import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grin_native/grin_native.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/models/slatepack_models.dart';
import 'package:stackwallet/services/event_bus/events/global/tor_connection_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/events/global/tor_status_changed_event.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/slatepack_method.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/supporting/grin/grin_errors.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/slatepack_interface.dart';

import '../support/grin_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dataRoot;
  late Directory isarRoot;
  late Isar isar;
  late GrinHarness h;

  setUpAll(() async => dataRoot = await setUpGrinTests());
  tearDownAll(() => dataRoot.delete(recursive: true));
  setUp(() async {
    isarRoot = await Directory.systemTemp.createTemp('stack_grin_isar_');
    isar = await openTestIsar(isarRoot);
    h = await GrinHarness.create(restoreHeight: 1000);
  });
  tearDown(() async {
    await h.dispose();
    await isar.close();
    await isarRoot.delete(recursive: true);
  });

  Amount grin(int nano) =>
      Amount(rawValue: BigInt.from(nano), fractionDigits: 9);

  TxData send(String address, {SlatepackMethod? method}) => TxData(
    recipients: [
      TxRecipient(
        address: address,
        amount: grin(1000000000),
        isChange: false,
        addressType: AddressType.mimbleWimble,
      ),
    ],
    otherData: method == null ? null : slatepackMethodOtherData(method),
    grinClearnetAcknowledged: true,
  );

  Future<GrinWalletException> failure(Future<Object?> call) async {
    try {
      await call;
    } on GrinWalletException catch (e) {
      return e;
    }
    fail('the call did not fail');
  }

  /// Whether the history was read again after [call] was made.
  bool refreshedAfter(String call) {
    final calls = h.backend.api.calls;
    return calls.skip(calls.lastIndexOf(call)).contains('getTransactions');
  }

  Future<TransactionV2> storedTx() async => (await isar.transactionV2s
      .where()
      .txidWalletIdEqualTo('slate-1', h.wallet.walletId)
      .findFirst())!;

  Future<void> storeHistory(List<GrinTxLogEntry> entries) async {
    h.backend.api.transactions = GrinTxList(
      refreshedFromNode: true,
      transactions: entries,
    );
    await h.wallet.updateTransactions();
  }

  Future<FakeGrinWalletApi> startScan() async {
    h.backend.scanBlocks = true;
    await h.wallet.init(isRestore: true);
    await h.wallet.recover(isRescan: false);
    await eventually(() => h.backend.api.scanRunning);
    return h.backend.api;
  }

  group('an HTTP send that fails', () {
    const target = 'https://wallet.example';

    test('before anything is locked says so and changes nothing', () async {
      await h.wallet.init();
      h.backend.api.sendError = grinError(11);
      final e = await failure(h.wallet.confirmSend(txData: send(target)));
      expect(e.message, endsWith('Nothing was sent or locked.'));
      expect(e.leftPendingTransaction, isFalse);
      await pumpEventQueue();
      expect(refreshedAfter('sendHttp'), isFalse);
    });

    test('and was released again says no funds are locked', () async {
      await h.wallet.init();
      h.backend.api.sendError = grinError(
        12,
        details: {'slate_id': 'slate-r', 'released': true},
      );
      final e = await failure(h.wallet.confirmSend(txData: send(target)));
      expect(e.message, endsWith('Nothing was sent and no funds are locked.'));
      expect(e.released, isTrue);
      expect(e.leftPendingTransaction, isFalse);
      expect(e.finalizedNotBroadcast, isFalse);
      expect(e.message, isNot(contains(remoteText)));
      await eventually(() => refreshedAfter('sendHttp'));
    });

    test('and could not be released points at the history', () async {
      await h.wallet.init();
      h.backend.api.sendError = grinError(11, details: {'slate_id': 'slate-l'});
      final e = await failure(h.wallet.confirmSend(txData: send(target)));
      expect(e.message, contains('Nothing was sent.'));
      expect(e.message, endsWith(grinLeftPendingNote));
      expect(e.message, isNot(contains('or locked')));
      expect(e.slateId, 'slate-l');
      expect(e.leftPendingTransaction, isTrue);
      await eventually(() => refreshedAfter('sendHttp'));
    });

    test('at the broadcast is finalized and can be reposted', () async {
      await h.wallet.init();
      h.backend.api.sendError = grinError(
        9,
        details: {'slate_id': 'slate-f', 'finalized': true},
      );
      final e = await failure(h.wallet.confirmSend(txData: send(target)));
      expect(e.message, grinFinalizedNotBroadcastMessage);
      expect(e.finalizedNotBroadcast, isTrue);
      expect(e.slateId, 'slate-f');
      expect(e.leftPendingTransaction, isFalse);
      await eventually(() => refreshedAfter('sendHttp'));
    });
  });

  group('a fee that changed after the review', () {
    GrinFeeEstimate feeOf(int fee) => GrinFeeEstimate(
      fee: BigInt.from(fee),
      amount: BigInt.zero,
      netAmount: BigInt.zero,
      total: BigInt.zero,
      inputsCount: 2,
      changeOutputs: 1,
    );

    test('stops a Slatepack send before anything is locked', () async {
      await h.wallet.init();
      final api = h.backend.api;
      final prepared = await h.wallet.prepareSend(txData: send('grin1friend'));
      api.fee = feeOf(31000000);
      final e = await failure(h.wallet.confirmSend(txData: prepared));
      expect(e.message, contains('fee changed'));
      expect(api.initSends, isEmpty);
      expect(api.cancelled, isEmpty);
    });

    test('stops an HTTP send before the recipient is contacted', () async {
      await h.wallet.init();
      final api = h.backend.api;
      final prepared = await h.wallet.prepareSend(
        txData: send('https://wallet.example'),
      );
      api.fee = feeOf(31000000);
      final e = await failure(h.wallet.confirmSend(txData: prepared));
      expect(e.message, contains('fee changed'));
      expect(api.httpSends, isEmpty);
    });

    test('cancels a Slatepack send that was built with another fee', () async {
      await h.wallet.init();
      final api = h.backend.api;
      final prepared = await h.wallet.prepareSend(txData: send('grin1friend'));
      api.sendFee = BigInt.from(31000000);
      final e = await failure(h.wallet.confirmSend(txData: prepared));
      expect(e.message, contains('fee changed'));
      expect(api.cancelled.single, (txId: null, slateId: 'slate-S1'));
    });

    test('an unchanged fee sends', () async {
      await h.wallet.init();
      final prepared = await h.wallet.prepareSend(
        txData: send('grin1friend').copyWith(subtractFeeFromAmount: true),
      );
      final sent = await h.wallet.confirmSend(txData: prepared);
      expect(sent.txid, 'slate-S1');
      expect(h.backend.api.cancelled, isEmpty);
    });
  });

  group('while a scan is pending', () {
    test('receive, invoice, finalize and repost are refused at once', () async {
      final api = await startScan();
      await storeHistory([
        entryOf(id: 3, state: GrinSlateState.s3, hasStoredTx: true),
      ]);
      const wait = 'Wait for the Grin wallet to finish scanning';

      final received = await h.wallet.receiveSlatepack('s1');
      expect(received.success, isFalse);
      expect(received.error, contains(wait));

      final invoice = await h.wallet.issueInvoice(amount: grin(5));
      expect(invoice.success, isFalse);
      expect(invoice.error, contains(wait));

      for (final result in [
        await h.wallet.finalizeSlatepack('s2'),
        await h.wallet.finalizeInvoice('i2'),
      ]) {
        expect(result.success, isFalse);
        expect(result.error, contains(wait));
      }

      final repost = await failure(h.wallet.repost('slate-1'));
      expect(repost.message, contains(wait));

      for (final call in [
        'receiveSlatepack',
        'issueInvoice',
        'finalizeSlatepack',
        'finalizeInvoice',
        'repost',
      ]) {
        expect(api.calls, isNot(contains(call)));
      }
    });

    test('a Slatepack only the wallet can read says to wait', () async {
      final api = await startScan();
      h.backend.decodeError = grinError(11);
      final e = await failure(
        h.wallet.inspectSlatepack('BEGINSLATEPACK. x ENDSLATEPACK.'),
      );
      expect(e.message, contains('while the Grin wallet is scanning'));
      expect(api.calls, isNot(contains('decodeSlatepack')));
    });
  });

  test(
    'receive and invoice are refused while the network is blocked',
    () async {
      await h.wallet.init();
      h.prefs.tor = true;
      h.tor.current = TorConnectionStatus.disconnected;

      final received = await h.wallet.receiveSlatepack('s1');
      expect(received.success, isFalse);
      expect(received.error, contains('Tor is not connected'));
      final invoice = await h.wallet.issueInvoice(amount: grin(5));
      expect(invoice.success, isFalse);
      expect(invoice.error, contains('Tor is not connected'));

      final api = h.backend.api;
      expect(api.calls, isNot(contains('receiveSlatepack')));
      expect(api.calls, isNot(contains('issueInvoice')));
    },
  );

  test(
    'a refresh that changes a transaction tells whoever watches it',
    () async {
      await h.wallet.init();
      await storeHistory([entryOf(id: 1)]);
      final seen = <SlatepackTxInfo?>[];
      final watch = isar.transactionV2s
          .where()
          .txidWalletIdEqualTo('slate-1', h.wallet.walletId)
          .watch()
          .listen((rows) => seen.addAll(rows.map(h.wallet.slatepackTxInfo)));
      addTearDown(watch.cancel);
      expect(h.wallet.slatepackTxInfo(await storedTx())!.canRepost, isFalse);

      await storeHistory([
        entryOf(id: 1, state: GrinSlateState.s3, hasStoredTx: true),
      ]);
      await eventually(() => seen.isNotEmpty);
      expect(seen.last!.canRepost, isTrue);
      expect(seen.last!.canShowSlatepack, isFalse);
    },
  );

  group('cancelling a self-send', () {
    Future<void> selfSend() => storeHistory([
      entryOf(id: 1, debited: 1000, credited: 400, fee: 10),
      entryOf(
        id: 2,
        type: GrinTxType.txReceived,
        state: GrinSlateState.s2,
        credited: 590,
        fee: null,
      ),
    ]);

    test('goes on to the second entry when the first is gone', () async {
      await h.wallet.init();
      await selfSend();
      final api = h.backend.api;
      for (final code in [12, 13]) {
        api.cancelled.clear();
        api.cancelErrors[1] = grinError(code);
        expect(await h.wallet.cancelPendingTransactionAndPost('slate-1'), '');
        expect(api.cancelled, [(txId: 2, slateId: null)], reason: '$code');
      }
    });

    test('fails when neither entry could be cancelled', () async {
      await h.wallet.init();
      await selfSend();
      final api = h.backend.api;
      api.cancelErrors[1] = grinError(13);
      api.cancelErrors[2] = grinError(12);
      final result = await h.wallet.cancelPendingTransactionAndPost('slate-1');
      expect(result, isNotEmpty);
      expect(result, isNot(contains(remoteText)));
      expect(api.cancelled, isEmpty);
    });
  });

  group('Tor starting to connect over a direct connection', () {
    Future<void> settle() => pumpEventQueue(times: 50);

    void torConnecting() {
      h.prefs.tor = true;
      h.tor.current = TorConnectionStatus.connecting;
      h.bus.fire(
        TorConnectionStatusChangedEvent(TorConnectionStatus.connecting, ''),
      );
    }

    test('turns the network off until Tor is up', () async {
      await h.wallet.init();
      h.wallet.shouldAutoSync = true;
      final api = h.backend.api;

      torConnecting();
      await settle();
      final hold = api.networkUpdates.single;
      expect(hold.networkEnabled, isFalse);
      expect(hold.socksProxy, isNull);
      expect(refreshedAfter('updateNetwork'), isFalse);

      h.tor.current = TorConnectionStatus.connected;
      h.bus.fire(
        TorConnectionStatusChangedEvent(TorConnectionStatus.connected, ''),
      );
      await settle();
      expect(api.networkUpdates, hasLength(2));
      expect(api.networkUpdates.last.socksProxy, '127.0.0.1:9050');
      expect(api.networkUpdates.last.networkEnabled, isTrue);
      await eventually(() => refreshedAfter('updateNetwork'));
    });

    test('stops a running scan, which goes on through Tor', () async {
      final api = await startScan();
      h.wallet.shouldAutoSync = true;
      api.cancelScannedHeight = 1500;

      torConnecting();
      await settle();
      expect(api.calls, containsAllInOrder(['cancelScan', 'updateNetwork']));
      expect(api.networkUpdates.single.networkEnabled, isFalse);
      expect(api.scanRunning, isFalse);

      h.tor.current = TorConnectionStatus.connected;
      h.bus.fire(
        TorConnectionStatusChangedEvent(TorConnectionStatus.connected, ''),
      );
      await eventually(() => api.calls.contains('scan:1501:false'));
      final proxied = api.calls.lastIndexOf('updateNetwork');
      expect(api.calls.indexOf('scan:1501:false'), greaterThan(proxied));
      expect(api.networkUpdates.last.socksProxy, '127.0.0.1:9050');
    });

    test('a hold over a proxy or a block changes nothing', () async {
      h.prefs.tor = true;
      h.tor.current = TorConnectionStatus.connected;
      await h.wallet.init();
      final api = h.backend.api;
      torConnecting();
      h.bus.fire(TorPreferenceChangedEvent(status: TorStatus.enabled));
      await settle();
      expect(api.networkUpdates, isEmpty);
    });
  });
}
