import 'package:stackwallet/wallets/crypto_currency/intermediate/cryptonote_currency.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/mnemonic_interface.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

abstract class CryptonoteWallet<T extends CryptonoteCurrency> extends Wallet<T>
    with MnemonicInterface<T> {
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

  @override
  Future<void> updateUTXOs() async {
    // do nothing for now
  }
}
