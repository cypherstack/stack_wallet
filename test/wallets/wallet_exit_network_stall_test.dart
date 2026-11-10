import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/utilities/enums/sync_type_enum.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

class _Prefs extends Fake implements Prefs {
  @override
  SyncingType get syncType => SyncingType.allWalletsOnStartup;
}

class _Wallet extends Wallet<Bitcoin> {
  _Wallet() : super(Bitcoin(CryptoCurrencyNetwork.main)) {
    prefs = _Prefs();
    doNotFireRefreshEvents = true;
  }

  final history = Completer<void>();
  final utxos = Completer<bool>();

  @override
  String get walletId => 'stalled-exit-test';

  @override
  WalletInfo get info => WalletInfo(
    walletId: walletId,
    name: 'Stalled node fixture',
    mainAddressType: AddressType.p2wpkh,
    coinName: 'bitcoin',
  );

  @override
  Future<void> updateChainHeight() async {}

  @override
  Future<void> updateTransactions() => history.future;

  @override
  Future<bool> updateUTXOs() => utxos.future;

  @override
  Future<void> updateBalance() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

void main() {
  testWidgets('exit remains responsive while node requests are stalled', (
    tester,
  ) async {
    final wallet = _Wallet();
    final refresh = wallet.refresh();
    await tester.pump(const Duration(milliseconds: 300));
    var exited = false;
    final exit = wallet.exit().then((_) => exited = true);
    await tester.pump();
    final exitedBeforeNodeResponded = exited;
    // Release fixture requests after checking exit so teardown leaves no
    // pending work behind.
    wallet.history.complete();
    wallet.utxos.complete(false);
    await tester.pump();
    await refresh;
    await exit;
    expect(exitedBeforeNodeResponded, isTrue);
  });
}
