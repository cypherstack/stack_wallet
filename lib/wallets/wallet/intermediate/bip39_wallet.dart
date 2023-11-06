import 'package:stackwallet/wallets/crypto_currency/intermediate/bip39_currency.dart';
import 'package:stackwallet/wallets/wallet/mixins/mnemonic_based_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

abstract class Bip39Wallet<T extends Bip39Currency> extends Wallet<T>
    with MnemonicBasedWallet {
  Bip39Wallet(T currency) : super(currency);

  // ========== Private ========================================================

  // ========== Overrides ======================================================

  // @override
  // Future<TxData> confirmSend({required TxData txData}) {
  //   // TODO: implement confirmSend
  //   throw UnimplementedError();
  // }
  //
  // @override
  // Future<TxData> prepareSend({required TxData txData}) {
  //   // TODO: implement prepareSend
  //   throw UnimplementedError();
  // }
  //
  // @override
  // Future<void> recover({required bool isRescan}) {
  //   // TODO: implement recover
  //   throw UnimplementedError();
  // }
}
