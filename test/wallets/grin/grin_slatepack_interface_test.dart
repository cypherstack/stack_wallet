import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grin/grin.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/models/slatepack_models.dart';
import 'package:stackwallet/services/event_bus/events/global/tor_connection_status_changed_event.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/slatepack_method.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/impl/grin_wallet.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/supporting/grin/grin_errors.dart';
import 'package:stackwallet/wallets/wallet/supporting/grin/grin_scan_pause_observer.dart';
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
    h = await GrinHarness.create();
    await h.wallet.init();
  });
  tearDown(() async {
    await h.dispose();
    await isar.close();
    await isarRoot.delete(recursive: true);
  });

  Amount grin(int nano) =>
      Amount(rawValue: BigInt.from(nano), fractionDigits: 9);

  GrinSlateInfo info(
    GrinSlateState state, {
    int amount = 0,
    int fee = 0,
    bool encrypted = false,
  }) => GrinSlateInfo(
    slateId: 'slate-in',
    state: state,
    amount: BigInt.from(amount),
    fee: BigInt.from(fee),
    kernelExcess: null,
    sender: 'grin1sender',
    recipients: encrypted ? const ['grin1ownaddress'] : const [],
    ttlCutoffHeight: 2000,
    numParticipants: 2,
    isEncrypted: encrypted,
    slateJson: '{}',
  );

  Future<void> storeHistory(List<GrinTxLogEntry> entries) async {
    h.backend.api.transactions = GrinTxList(
      refreshedFromNode: true,
      transactions: entries,
    );
    await h.wallet.updateTransactions();
  }

  test('GrinWallet is a SlatepackInterface with the Grin capabilities', () {
    final SlatepackInterface wallet = h.wallet;
    expect(wallet.supportedMethods, [
      SlatepackMethod.slatepack,
      SlatepackMethod.http,
    ]);
    expect(wallet.supportsOnChainNote, isFalse);
    expect(wallet.supportsInvoices, isTrue);
    expect(wallet.supportsPaymentProofs, isTrue);
    expect(wallet.supportsRepost, isTrue);
    expect(wallet.receiveQrIsRawAddress, isTrue);
    expect(wallet.receiveAddressNote, isNotNull);
  });

  test('the direct send hint names the address prefix of the network', () {
    expect(h.wallet.directSendAddressHint, startsWith('grin1 '));
    final testnet = GrinWallet(
      CryptoCurrencyNetwork.test,
      backend: h.backend,
      torService: h.tor,
      eventBus: h.bus,
    );
    expect(testnet.directSendAddressHint, startsWith('tgrin1 '));
  });

  group('inspectSlatepack', () {
    test('an S1 carries amount, sender, encryption and TTL', () async {
      h.backend.api.decoded = info(
        GrinSlateState.s1,
        amount: 5000,
        fee: 300,
        encrypted: true,
      );
      final inspection = await h.wallet.inspectSlatepack('s1');
      expect(inspection.state, SlateState.s1);
      expect(inspection.slateId, 'slate-in');
      expect(inspection.amount, grin(5000));
      expect(inspection.fee, grin(300));
      expect(inspection.senderAddress, 'grin1sender');
      expect(inspection.isEncrypted, isTrue);
      expect(inspection.ttlCutoffHeight, 2000);
    });

    test('S2 and I2 leave the amount to the local transaction', () async {
      for (final state in [GrinSlateState.s2, GrinSlateState.i2]) {
        h.backend.api.decoded = info(state, fee: 300);
        final inspection = await h.wallet.inspectSlatepack('x');
        expect(inspection.amount, isNull);
        expect(inspection.state, SlateState.fromCode(state.wireName));
      }
    });

    test('an I1 has no fee yet', () async {
      h.backend.api.decoded = info(GrinSlateState.i1, amount: 7000);
      final inspection = await h.wallet.inspectSlatepack('i1');
      expect(inspection.state, SlateState.i1);
      expect(inspection.amount, grin(7000));
      expect(inspection.fee, isNull);
    });

    test('an unreadable slatepack throws a sanitized error', () async {
      h.backend.api.decoded = null;
      await expectLater(
        h.wallet.inspectSlatepack('junk'),
        throwsA(
          isA<GrinWalletException>().having(
            (e) => e.message,
            'message',
            isNot(contains(remoteText)),
          ),
        ),
      );
    });
  });

  test('localTxForSlate reads the stored send', () async {
    expect(await h.wallet.localTxForSlate('slate-1'), isNull);
    await storeHistory([
      entryOf(id: 1, debited: 3000, credited: 1000, fee: 100),
    ]);
    final local = await h.wallet.localTxForSlate('slate-1');
    expect(local, isNotNull);
    expect(local!.fee, grin(100));
    expect(local.amount, grin(1900));
    expect(local.isSend, isTrue);
  });

  group('createSlatepack', () {
    test('encrypts to a recipient and honours send all', () async {
      final result = await h.wallet.createSlatepack(
        amount: grin(5000),
        recipientAddress: 'grin1friend',
        sendAll: true,
      );
      expect(result.success, isTrue);
      expect(result.state, SlateState.s1);
      expect(result.slateId, 'slate-S1');
      expect(result.slatepack, startsWith('BEGINSLATEPACK.'));
      final args = h.backend.api.initSends.single;
      expect(args.recipientAddress, 'grin1friend');
      expect(args.amount, BigInt.from(5000));
      expect(args.selectionStrategyIsAll, isTrue);
      expect(args.amountIncludesFee, isTrue);
      expect(args.ttlBlocks, GrinWallet.slatepackTtlBlocks);
    });

    test('without a recipient the S1 is plain', () async {
      final result = await h.wallet.createSlatepack(amount: grin(5000));
      expect(result.success, isTrue);
      expect(h.backend.api.initSends.single.recipientAddress, isNull);
      expect(h.backend.api.initSends.single.selectionStrategyIsAll, isFalse);
    });

    test('a recipient that is not a grin1 address locks nothing', () async {
      final result = await h.wallet.createSlatepack(
        amount: grin(5000),
        recipientAddress: 'https://x.example',
      );
      expect(result.success, isFalse);
      expect(h.backend.api.calls, isNot(contains('initSend')));
    });
  });

  test('receiveSlatepack returns the S2', () async {
    final result = await h.wallet.receiveSlatepack('s1');
    expect(result.success, isTrue);
    expect(result.state, SlateState.s2);
    expect(result.slatepack, isNotNull);
  });

  group('finalizeSlatepack', () {
    test('posted with the kernel excess', () async {
      final result = await h.wallet.finalizeSlatepack('s2');
      expect(result.success, isTrue);
      expect(result.posted, isTrue);
      expect(result.kernelExcess, '08ab');
      expect(result.slateId, 'slate-S3');
    });

    test('a node error naming the slate is finalized, not posted', () async {
      h.backend.api.finalizeError = grinError(
        9,
        details: {'slate_id': 'slate-9'},
      );
      final result = await h.wallet.finalizeSlatepack('s2');
      expect(result.success, isTrue);
      expect(result.posted, isFalse);
      expect(result.slateId, 'slate-9');
      expect(result.error, contains('repost'));
      expect(result.error, isNot(contains(remoteText)));
    });

    test('a node error before finalizing is a failure', () async {
      h.backend.api.finalizeError = grinError(9);
      final result = await h.wallet.finalizeSlatepack('s2');
      expect(result.success, isFalse);
    });

    test('not found means not a pending send from this wallet', () async {
      h.backend.api.finalizeError = grinError(13);
      final result = await h.wallet.finalizeSlatepack('s2');
      expect(result.success, isFalse);
      expect(result.error, 'This is not a pending send from this wallet.');
    });

    test('an invoice node error is offered for repost too', () async {
      h.backend.api.finalizeError = grinError(
        9,
        details: {'slate_id': 'slate-i'},
      );
      final result = await h.wallet.finalizeInvoice('i2');
      expect(result.success, isTrue);
      expect(result.posted, isFalse);
    });
  });

  group('stored transactions', () {
    test('repost needs a stored finalized transaction', () async {
      await storeHistory([entryOf(id: 3, state: GrinSlateState.s1)]);
      await expectLater(
        h.wallet.repost('slate-1'),
        throwsA(isA<GrinWalletException>()),
      );
      expect(h.backend.api.calls, isNot(contains('repost')));

      await storeHistory([
        entryOf(id: 3, state: GrinSlateState.s3, hasStoredTx: true),
      ]);
      await h.wallet.repost('slate-1');
      expect(h.backend.api.reposts.single, (txId: 3, slateId: 'slate-1'));
    });

    test('slatepackTxInfo offers repost for finalized, unconfirmed', () async {
      await storeHistory([
        entryOf(
          id: 4,
          state: GrinSlateState.s3,
          hasStoredTx: true,
          kernelExcess: '08cd',
          counterparty: 'grin1friend',
          ttl: 2500,
        ),
      ]);
      final tx = (await isar.transactionV2s.where().findAll()).single;
      final details = h.wallet.slatepackTxInfo(tx)!;
      expect(details.slateId, 'slate-1');
      expect(details.kernelExcess, '08cd');
      expect(details.counterpartyAddress, 'grin1friend');
      expect(details.ttlCutoffHeight, 2500);
      expect(details.finalizedAwaitingConfirmation, isTrue);
      expect(details.canRepost, isTrue);
      expect(details.canShowSlatepack, isFalse);
    });

    test('an S1 waiting for an answer can be shown again', () async {
      await storeHistory([
        entryOf(id: 5, state: GrinSlateState.s1, armored: 'BEGINSLATEPACK.'),
      ]);
      final tx = (await isar.transactionV2s.where().findAll()).single;
      final details = h.wallet.slatepackTxInfo(tx)!;
      expect(details.canShowSlatepack, isTrue);
      expect(details.canRepost, isFalse);
      expect(await h.wallet.pendingSlatepackFor('slate-1'), 'BEGINSLATEPACK.');
    });

    test('a cancelled send offers nothing', () async {
      await storeHistory([
        entryOf(id: 6, type: GrinTxType.txSentCancelled, hasStoredTx: true),
      ]);
      final tx = (await isar.transactionV2s.where().findAll()).single;
      final details = h.wallet.slatepackTxInfo(tx)!;
      expect(details.canRepost, isFalse);
      expect(details.canShowSlatepack, isFalse);
    });

    test('export needs a payment proof', () async {
      await storeHistory([entryOf(id: 7, state: GrinSlateState.s3)]);
      await expectLater(
        h.wallet.exportPaymentProof('slate-1'),
        throwsA(isA<GrinWalletException>()),
      );
      expect(h.backend.api.calls, isNot(contains('exportPaymentProof')));

      await storeHistory([
        entryOf(
          id: 7,
          state: GrinSlateState.s3,
          proof: const GrinPaymentProofSummary(
            receiverAddress: 'grin1recipient',
            senderAddress: 'grin1ownaddress',
            receiverSignaturePresent: true,
            senderSignaturePresent: true,
          ),
        ),
      ]);
      final json = await h.wallet.exportPaymentProof('slate-1');
      expect(json, contains('grin1recipient'));
    });
  });

  group('verifyPaymentProof', () {
    const proof =
        '{"amount": 1000, "excess": "08ab", '
        '"recipient_address": "grin1recipient", '
        '"sender_address": "grin1ownaddress", '
        '"recipient_sig": "r", "sender_sig": "s"}';

    test('reports the proof and which side this wallet is', () async {
      final check = await h.wallet.verifyPaymentProof(proof);
      expect(check.amount, grin(1000));
      expect(check.kernelExcess, '08ab');
      expect(check.senderAddress, 'grin1ownaddress');
      expect(check.recipientAddress, 'grin1recipient');
      expect(check.isSender, isTrue);
      expect(check.isRecipient, isFalse);
    });

    test('malformed text never reaches the library', () async {
      await expectLater(
        h.wallet.verifyPaymentProof('not json'),
        throwsA(isA<GrinWalletException>()),
      );
      expect(h.backend.api.calls, isNot(contains('verifyPaymentProof')));
    });

    test('a failed check has fixed text', () async {
      h.backend.api.verifyError = grinError(12);
      await expectLater(
        h.wallet.verifyPaymentProof(proof),
        throwsA(
          isA<GrinWalletException>().having(
            (e) => e.message,
            'message',
            contains('did not verify'),
          ),
        ),
      );
    });
  });

  group('httpSendPolicy', () {
    test('Tor off: clearnet needs the IP warning, onion is blocked', () {
      final https = h.wallet.httpSendPolicy('https://x.example');
      expect(https.isBlocked, isFalse);
      expect(https.needsClearnetAck, isTrue);
      expect(https.needsPlaintextAck, isFalse);

      final http = h.wallet.httpSendPolicy('http://x.example');
      expect(http.needsClearnetAck, isTrue);
      expect(http.needsPlaintextAck, isTrue);

      expect(h.wallet.httpSendPolicy('grin1friend').isBlocked, isTrue);
      expect(
        h.wallet.httpSendPolicy('http://${'a' * 56}.onion').isBlocked,
        isTrue,
      );
    });

    test('Tor on: no IP warning, plain http still warned', () {
      h.prefs.tor = true;
      h.tor.current = TorConnectionStatus.connected;
      final https = h.wallet.httpSendPolicy('https://x.example');
      expect(https.isBlocked, isFalse);
      expect(https.needsClearnetAck, isFalse);
      expect(
        h.wallet.httpSendPolicy('http://x.example').needsPlaintextAck,
        isTrue,
      );
      expect(h.wallet.httpSendPolicy('grin1friend').isBlocked, isFalse);
    });

    test('Tor wanted but down blocks everything', () {
      h.prefs.tor = true;
      h.prefs.killSwitch = false;
      h.tor.current = TorConnectionStatus.disconnected;
      for (final target in [
        'https://x.example',
        'http://x.example',
        'grin1friend',
      ]) {
        expect(h.wallet.httpSendPolicy(target).isBlocked, isTrue);
      }
    });
  });

  test('an HTTP answer that fails checks says nothing was locked', () async {
    h.backend.api.sendError = grinError(11);
    await expectLater(
      h.wallet.confirmSend(
        txData: TxData(
          recipients: [
            TxRecipient(
              address: 'https://x.example',
              amount: grin(1000),
              isChange: false,
              addressType: AddressType.mimbleWimble,
            ),
          ],
          otherData: slatepackMethodOtherData(SlatepackMethod.http),
          grinClearnetAcknowledged: true,
        ),
      ),
      throwsA(
        isA<GrinWalletException>().having(
          (e) => e.message,
          'message',
          contains("recipient's answer failed checks"),
        ),
      ),
    );
  });

  test('app pause and resume notify the scan owner', () {
    var cancels = 0;
    var resumes = 0;
    final observer = GrinScanPauseObserver.detached(
      cancelScan: () => cancels++,
      resumeScan: () => resumes++,
    );
    observer.onStateChange(AppLifecycleState.resumed);
    observer.onStateChange(AppLifecycleState.inactive);
    expect(cancels, 0);
    observer.onStateChange(AppLifecycleState.paused);
    expect(cancels, 1);
    observer.onStateChange(AppLifecycleState.detached);
    expect(cancels, 2);
    expect(observer.isPaused, isTrue);
    expect(resumes, 0);
    observer.onStateChange(AppLifecycleState.resumed);
    expect(observer.isPaused, isFalse);
    expect(resumes, 1);
    observer.dispose();
  });
}
