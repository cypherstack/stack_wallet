import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
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
  bool rowDeleted = false;
  int pingReads = 0;

  @override
  String get walletId => 'refresh-test';

  @override
  WalletInfo get info => rowDeleted
      ? throw StateError('Wallet row deleted')
      : WalletInfo(
          walletId: walletId,
          name: 'Fixture wallet',
          mainAddressType: AddressType.p2wpkh,
          coinName: 'bitcoin',
        );

  @override
  Future<bool> pingCheck() async {
    pingReads++;
    return true;
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

  testWidgets('automatic sync retries failures until disabled', (tester) async {
    final wallet = _Wallet();
    wallet.shouldAutoSync = true;
    await tester.pump(const Duration(milliseconds: 300));
    expect(wallet.historyReads, 1);
    wallet.historyRelease.completeError(StateError('History unavailable'));
    wallet.utxosRelease.complete(false);
    await tester.pump();
    await tester.pump(const Duration(seconds: 150));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    final readsBeforeExit = wallet.historyReads;
    final healthyPings = wallet.pingReads;
    wallet.shouldAutoSync = false;
    await wallet.exit();
    await tester.pump(const Duration(seconds: 150));
    await tester.pump(const Duration(milliseconds: 300));

    expect(readsBeforeExit, 2);
    expect(healthyPings, greaterThan(1));
    expect(wallet.historyReads, 2);
    expect(wallet.balanceReads, 0);
  });

  test('retired wallet row cannot escape refresh error handling', () async {
    final errors = <Object>[];
    await runZonedGuarded(() async {
      final wallet = _Wallet();
      final refresh = wallet.refresh();
      await wallet.historyStarted.future;
      await wallet.utxosStarted.future;
      // Deletion can remove this row while the refresh is still pending.
      wallet.rowDeleted = true;
      wallet.historyRelease.complete();
      wallet.utxosRelease.complete(false);
      await refresh.timeout(const Duration(seconds: 3));
      await Future<void>.delayed(Duration.zero);
    }, (error, _) => errors.add(error));
    expect(errors, isEmpty);
  });

  for (final historyFails in [true, false]) {
    test(
      '${historyFails ? 'history' : 'UTXO'} errors wait for the other request '
      'before releasing the refresh lock',
      () async {
        final wallet = _Wallet();
        final refresh = wallet.refresh();
        var finished = false;
        final observed = refresh.then((_) => finished = true);
        await wallet.historyStarted.future;
        await wallet.utxosStarted.future;
        if (historyFails) {
          wallet.historyRelease.completeError(
            StateError('History unavailable'),
          );
        } else {
          wallet.utxosRelease.completeError(StateError('UTXOs unavailable'));
        }
        await Future<void>.delayed(Duration.zero);
        expect(finished, isFalse);
        expect(wallet.refreshMutex.isLocked, isTrue);
        if (historyFails) {
          wallet.utxosRelease.complete(false);
        } else {
          wallet.historyRelease.complete();
        }
        await observed;
        expect(wallet.refreshMutex.isLocked, isFalse);
        expect(wallet.balanceReads, 0);
      },
    );
  }
}
