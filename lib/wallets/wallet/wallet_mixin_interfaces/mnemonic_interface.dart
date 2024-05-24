import '../../../exceptions/sw_exception.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../wallet.dart';

mixin MnemonicInterface<T extends CryptoCurrency> on Wallet<T> {
  Future<String> getMnemonic() async {
    final mnemonic = await secureStorageInterface.read(
      key: Wallet.mnemonicKey(walletId: info.walletId),
    );

    if (mnemonic == null) {
      throw SWException("mnemonic has not been set");
    }

    return mnemonic;
  }

  Future<List<String>> getMnemonicAsWords() async {
    final mnemonic = await getMnemonic();
    return mnemonic.split(" ");
  }

  Future<String> getMnemonicPassphrase() async {
    final mnemonicPassphrase = await secureStorageInterface.read(
      key: Wallet.mnemonicPassphraseKey(walletId: info.walletId),
    );

    if (mnemonicPassphrase == null) {
      // some really old wallets may not have this set so for legacy reasons do
      // not throw here for now
      return "";
      //throw SWException("mnemonicPassphrase has not been set");
    }

    return mnemonicPassphrase;
  }
}
