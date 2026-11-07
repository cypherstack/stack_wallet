import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grin/grin.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/services/event_bus/events/global/blocks_remaining_event.dart';
import 'package:stackwallet/services/event_bus/events/global/refresh_percent_changed_event.dart';
import 'package:stackwallet/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/supporting/grin/grin_errors.dart';
import 'package:stackwallet/wallets/wallet/supporting/grin_wallet_info_extension.dart';

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
    h.backend.scanBlocks = true;
  });
  tearDown(() async {
    await h.dispose();
    await isar.close();
    await isarRoot.delete(recursive: true);
  });

  Future<FakeGrinWalletApi> restore() async {
    await h.wallet.init(isRestore: true);
    await h.wallet.recover(isRescan: false);
    await pumpEventQueue();
    return h.backend.api;
  }

  Amount grin(int nano) => Amount(rawValue: BigInt.from(nano), fractionDigits: 9);

  test('restore creates from the mnemonic, then scans from the restore '
      'height', () async {
    final api = await restore();
    final create = h.backend.creates.single;
    expect(create.mnemonic, testMnemonic);
    expect(create.isNewWallet, isFalse);
    expect(api.calls, contains('scan:1000:false'));
    expect(h.wallet.info.grinData!.pendingScanFrom, 1000);
    expect((await h.wallet.getCurrentReceivingAddress())!.type,
        AddressType.mimbleWimble);

    api.finishScan();
    await eventually(() => h.wallet.info.grinData!.pendingScanFrom == null);
  });

  test('nothing that refreshes from the node runs while a scan is pending',
      () async {
    final api = await restore();
    expect(api.scanRunning, isTrue);
    final before = List.of(api.calls);

    await h.wallet.refresh();
    await h.wallet.updateTransactions();
    await h.wallet.updateBalance();
    await expectLater(
      h.wallet.estimateFeeFor(grin(5), BigInt.one),
      throwsA(isA<GrinWalletException>()),
    );
    final txData = TxData(
      recipients: [
        TxRecipient(
          address: 'grin1recipient',
          amount: grin(5),
          isChange: false,
          addressType: AddressType.mimbleWimble,
        ),
      ],
    );
    await expectLater(
      h.wallet.prepareSend(txData: txData),
      throwsA(isA<GrinWalletException>()),
    );
    await expectLater(
      h.wallet.confirmSend(txData: txData),
      throwsA(isA<GrinWalletException>()),
    );
    expect(
      await h.wallet.cancelPendingTransactionAndPost('slate-1'),
      isNotEmpty,
    );

    final after = api.calls.sublist(before.length);
    expect(api.transactionRefreshes, everyElement(isFalse));
    expect(api.balanceRefreshes, everyElement(isFalse));
    for (final call in [
      'estimateFee',
      'initSend',
      'sendHttp',
      'cancelTransaction',
    ]) {
      expect(after, isNot(contains(call)));
    }
    expect(after.where((c) => c.startsWith('scan')), isEmpty);
  });

  test('a cancelled scan resumes from scanned_height + 1', () async {
    final api = await restore();
    api.cancelScannedHeight = 20000;
    api.cancelScan();
    await eventually(() => h.wallet.info.grinData!.pendingScanFrom == 20001);

    await h.wallet.refresh();
    await eventually(() => api.calls.contains('scan:20001:false'));
    expect(api.calls.where((c) => c.startsWith('scan')).toList(),
        ['scan:1000:false', 'scan:20001:false']);
  });

  test('a node error keeps the resume height and reports unableToSync',
      () async {
    h.backend.scanBlocks = false;
    final statuses = <WalletSyncStatus>[];
    h.bus.on<WalletSyncStatusChangedEvent>().listen(
      (e) => statuses.add(e.newStatus),
    );
    await h.wallet.init(isRestore: true);
    await h.wallet.recover(isRescan: false);
    await eventually(
      () => h.wallet.info.grinData!.pendingScanFrom == null,
      reason: 'the default fake scan succeeds',
    );

    // Now a rescan whose node call fails.
    h.backend.api.scanError = grinError(9);
    await h.wallet.recover(isRescan: true);
    await eventually(() => statuses.contains(WalletSyncStatus.unableToSync));
    expect(h.wallet.info.grinData!.pendingScanFrom, 1000);
  });

  test('progress is reported as percent and blocks remaining', () async {
    final percents = <double>[];
    final remaining = <int>[];
    h.bus.on<RefreshPercentChangedEvent>().listen((e) => percents.add(e.percent));
    h.bus.on<BlocksRemainingEvent>().listen(
      (e) => remaining.add(e.blocksRemaining),
    );
    final api = await restore();
    api.progress = const GrinScanProgress(
      isScanning: true,
      cancelRequested: false,
      startHeight: 1000,
      scannedHeight: 3000,
      tipHeight: 5000,
      progressPct: 50,
    );
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(percents, contains(0.5));
    expect(remaining, contains(2000));
    expect(h.wallet.restoreProgress, 0.5);
    api.finishScan();
  });

  test('rescan keeps history and does not delete unconfirmed outputs',
      () async {
    final api = await restore();
    api.finishScan();
    await eventually(() => h.wallet.info.grinData!.pendingScanFrom == null);
    await h.wallet.recover(isRescan: true);
    await pumpEventQueue();
    expect(api.calls.where((c) => c.startsWith('scan')).last,
        'scan:1000:false');
    expect(h.backend.calls.where((c) => c == 'delete'), isEmpty);
  });
}
