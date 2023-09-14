import 'package:stackwallet/exceptions/sw_exception.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

class PrivateKeyBasedWallet extends Wallet {
  PrivateKeyBasedWallet(super.cryptoCurrency);

  Future<String> getPrivateKey() async {
    final privateKey = await secureStorageInterface.read(
      key: Wallet.privateKeyKey(walletId: walletInfo.walletId),
    );

    if (privateKey == null) {
      throw SWException("privateKey has not been set");
    }

    return privateKey;
  }

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
}
