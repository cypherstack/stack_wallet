import 'package:stackwallet/wallets/crypto_currency/intermediate/cryptonote_currency.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/mixins/mnemonic_based_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

abstract class CryptonoteWallet<T extends CryptonoteCurrency> extends Wallet<T>
    with MnemonicBasedWallet<T> {
  CryptonoteWallet(T currency) : super(currency);

  // ========== Overrides ======================================================

  @override
  Future<TxData> confirmSend({required TxData txData}) {
    // TODO: implement confirmSend
    throw UnimplementedError();
  }

  @override
  Future<TxData> prepareSend({required TxData txData}) {
    // TODO: implement prepareSend
    throw UnimplementedError();
  }

  @override
  Future<void> recover({required bool isRescan}) {
    // TODO: implement recover
    throw UnimplementedError();
  }
}
