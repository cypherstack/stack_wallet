import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/global_event_bus.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

class _Wallet extends Wallet<Bitcoin> {
  _Wallet() : super(Bitcoin(CryptoCurrencyNetwork.main)) {
    doNotFireRefreshEvents = true;
    prefs = Prefs.instance;
  }

  final historyStarted = Completer<void>();
  final historyRelease = Completer<void>();
  final utxosStarted = Completer<void>();
  final utxosRelease = Completer<bool>();
  int historyReads = 0;
  int balanceReads = 0;
  int pingReads = 0;
  Completer<bool>? ping;

  @override
  String get walletId => 'refresh-test';

  @override
  WalletInfo get info => WalletInfo(
    walletId: walletId,
    name: 'Fixture wallet',
    mainAddressType: AddressType.p2wpkh,
    coinName: 'bitcoin',
  );

  @override
  Future<bool> pingCheck() {
    pingReads++;
    return ping?.future ?? Future.value(true);
  }

  @override
  Future<void> updateChainHeight() async {}

  @override
  Future<void> updateTransactions() {
    historyReads++;
    if (!historyStarted.isCompleted) historyStarted.complete();
    return historyRelease.future;
  }

  @override
  Future<bool> updateUTXOs() {
    if (!utxosStarted.isCompleted) utxosStarted.complete();
    return utxosRelease.future;
  }

  @override
  Future<void> updateBalance() async {
    balanceReads++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('exit returns before refresh and stops background polling', (
    tester,
  ) async {
    final wallet = _Wallet();
    wallet.shouldAutoSync = true;
    final active = wallet.refresh();
    await tester.pump(const Duration(milliseconds: 300));
    expect(wallet.historyReads, 1);
    var exited = false;
    final exit = wallet.exit().then((_) => exited = true);
    await tester.pump();
    expect(exited, isTrue);
    expect(wallet.shouldAutoSync, isFalse);
    expect(wallet.historyRelease.isCompleted, isFalse);
    expect(wallet.utxosRelease.isCompleted, isFalse);
    final pingsAtExit = wallet.pingReads;
    await tester.pump(const Duration(seconds: 150));
    expect(wallet.pingReads, pingsAtExit);
    expect(wallet.historyReads, 1);
    wallet.historyRelease.complete();
    wallet.utxosRelease.complete(false);
    await tester.pump();
    await active;
    await exit;
    final autoSyncAfterExit = wallet.shouldAutoSync;
    await tester.pump(const Duration(seconds: 150));
    await tester.pump(const Duration(milliseconds: 300));
    final readsAfterExit = wallet.historyReads;
    final balanceReadsAfterExit = wallet.balanceReads;

    wallet.shouldAutoSync = true;
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    wallet.shouldAutoSync = false;

    expect(autoSyncAfterExit, isFalse);
    expect(readsAfterExit, 1);
    expect(balanceReadsAfterExit, 1);
    expect(wallet.historyReads, 2);
    expect(wallet.balanceReads, 2);
  });

  for (final historyFails in [true, false]) {
    testWidgets('exit returns while ${historyFails ? 'history' : 'UTXO'} fails '
        'and the other request remains pending', (tester) async {
      final wallet = _Wallet();
      wallet.shouldAutoSync = true;
      final refresh = wallet.refresh();
      await tester.pump(const Duration(milliseconds: 300));
      if (historyFails) {
        wallet.historyRelease.completeError(StateError('History unavailable'));
      } else {
        wallet.utxosRelease.completeError(StateError('UTXOs unavailable'));
      }
      await tester.pump();
      var exited = false;
      final exit = wallet.exit().then((_) => exited = true);
      await tester.pump();
      expect(exited, isTrue);
      expect(wallet.shouldAutoSync, isFalse);
      expect(wallet.refreshMutex.isLocked, isTrue);
      final pingsAtExit = wallet.pingReads;
      await tester.pump(const Duration(seconds: 150));
      expect(wallet.pingReads, pingsAtExit);
      expect(wallet.historyReads, 1);
      if (historyFails) {
        wallet.utxosRelease.complete(false);
      } else {
        wallet.historyRelease.complete();
      }
      await tester.pump();
      await refresh;
      await exit;
      await tester.pump(const Duration(seconds: 150));
      expect(wallet.shouldAutoSync, isFalse);
      expect(wallet.historyReads, 1);
      expect(wallet.balanceReads, 0);
      expect(wallet.pingReads, pingsAtExit);
    });
  }

  testWidgets('late ping cannot restart an exited wallet', (tester) async {
    final wallet = _Wallet()..ping = Completer<bool>();
    wallet.shouldAutoSync = true;
    final active = wallet.refresh();
    await tester.pump(const Duration(milliseconds: 300));
    wallet.historyRelease.complete();
    wallet.utxosRelease.complete(false);
    await tester.pump();
    await active;
    await wallet.exit();
    wallet.ping!.complete(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final readsAfterExit = wallet.historyReads;
    wallet.shouldAutoSync = false;
    expect(readsAfterExit, 1);
    expect(wallet.balanceReads, 1);
  });

  test(
    'concurrent refreshes wait for one update and emit synced once',
    () async {
      final wallet = _Wallet();
      wallet.doNotFireRefreshEvents = false;
      final statuses = <WalletSyncStatus>[];
      final subscription = GlobalEventBus.instance
          .on<WalletSyncStatusChangedEvent>()
          .listen((event) => statuses.add(event.newStatus));
      addTearDown(subscription.cancel);
      final first = wallet.refresh();
      await wallet.historyStarted.future;
      final second = wallet.refresh();
      var secondFinished = false;
      final observed = second.then((_) => secondFinished = true);
      await Future<void>.delayed(Duration.zero);
      expect(second, same(first));
      expect(secondFinished, isFalse);
      expect(statuses, [WalletSyncStatus.syncing]);
      expect(wallet.historyReads, 1);
      wallet.historyRelease.complete();
      wallet.utxosRelease.complete(false);
      await first;
      await observed;
      await Future<void>.delayed(Duration.zero);
      expect(statuses, [WalletSyncStatus.syncing, WalletSyncStatus.synced]);
      expect(wallet.balanceReads, 1);

      await wallet.refresh();
      expect(wallet.historyReads, 2);
    },
  );

  test(
    'a separate operation holding the mutex does not report synced',
    () async {
      final wallet = _Wallet();
      wallet.doNotFireRefreshEvents = false;
      final statuses = <WalletSyncStatus>[];
      final subscription = GlobalEventBus.instance
          .on<WalletSyncStatusChangedEvent>()
          .listen((event) => statuses.add(event.newStatus));
      addTearDown(subscription.cancel);
      await wallet.refreshMutex.acquire();
      addTearDown(wallet.refreshMutex.release);
      await wallet.refresh();
      await Future<void>.delayed(Duration.zero);
      expect(statuses, isEmpty);
      expect(wallet.historyReads, 0);
    },
  );
}
