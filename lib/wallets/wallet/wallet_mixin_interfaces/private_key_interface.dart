import 'package:stackwallet/exceptions/sw_exception.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

mixin PrivateKeyInterface<T extends CryptoCurrency> on Wallet<T> {
  Future<String> getPrivateKey() async {
    final privateKey = await secureStorageInterface.read(
      key: Wallet.privateKeyKey(walletId: info.walletId),
    );

    if (privateKey == null) {
      throw SWException("privateKey has not been set");
    }

    return privateKey;
  }

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
