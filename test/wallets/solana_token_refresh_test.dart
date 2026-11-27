import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/solana/sol_contract.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/impl/solana_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/sub_wallets/solana_token_wallet.dart';

class _ParentWallet extends Fake implements SolanaWallet {
  @override
  Solana get cryptoCurrency => Solana(CryptoCurrencyNetwork.main);

  int refreshes = 0;

  @override
  Future<void> refresh() async {
    refreshes++;
  }
}

class _TokenWallet extends SolanaTokenWallet {
  _TokenWallet(SolanaWallet parentSolanaWallet)
    : super(
        parentSolanaWallet,
        SolContract(
          address: 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v',
          name: 'USD Coin',
          symbol: 'USDC',
          decimals: 6,
        ),
      );

  @override
  String get walletId => 'sol-wallet';

  final balanceGate = Completer<void>();
  final balanceStarted = Completer<void>();
  int balanceUpdates = 0;
  int transactionUpdates = 0;

  @override
  Future<void> updateBalance() async {
    balanceUpdates++;
    if (!balanceStarted.isCompleted) balanceStarted.complete();
    await balanceGate.future;
  }

  @override
  Future<void> updateTransactions() async {
    transactionUpdates++;
  }
}

void main() {
  test('concurrent Solana token refreshes share all token work', () async {
    final parent = _ParentWallet();
    final wallet = _TokenWallet(parent);

    final first = wallet.refresh();
    await wallet.balanceStarted.future;
    final second = wallet.refresh();

    expect(wallet.refreshMutex.isLocked, isTrue);
    expect(parent.refreshes, 1);
    expect(wallet.balanceUpdates, 1);

    wallet.balanceGate.complete();
    await Future.wait([first, second]);

    expect(wallet.transactionUpdates, 1);
    expect(wallet.refreshMutex.isLocked, isFalse);
  });
}
