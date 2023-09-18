import 'package:stackwallet/exceptions/sw_exception.dart';
import 'package:stackwallet/wallets/crypto_currency/bip39_currency.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

abstract class Bip39Wallet<T extends Bip39Currency> extends Wallet<T> {
  Bip39Wallet(super.cryptoCurrency);

  Future<String> getMnemonic() async {
    final mnemonic = await secureStorageInterface.read(
      key: Wallet.mnemonicKey(walletId: walletInfo.walletId),
    );

    if (mnemonic == null) {
      throw SWException("mnemonic has not been set");
    }

    return mnemonic;
  }

  Future<String> getMnemonicPassphrase() async {
    final mnemonicPassphrase = await secureStorageInterface.read(
      key: Wallet.mnemonicPassphraseKey(walletId: walletInfo.walletId),
    );

    if (mnemonicPassphrase == null) {
      throw SWException("mnemonicPassphrase has not been set");
    }

    return mnemonicPassphrase;
  }

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
