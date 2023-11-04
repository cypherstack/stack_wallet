import 'package:stackwallet/exceptions/sw_exception.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

abstract class CryptonoteWallet extends Wallet {
  CryptonoteWallet(super.cryptoCurrency);

  Future<String> getMnemonic() async {
    final mnemonic = await secureStorageInterface.read(
      key: Wallet.mnemonicKey(walletId: info.walletId),
    );

    if (mnemonic == null) {
      throw SWException("mnemonic has not been set");
    }

    return mnemonic;
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

  @override
  Future<void> recover({required bool isRescan}) {
    // TODO: implement recover
    throw UnimplementedError();
  }
}
