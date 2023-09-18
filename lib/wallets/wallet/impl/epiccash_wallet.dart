import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/bip39_wallet.dart';

class EpiccashWallet extends Bip39Wallet {
  EpiccashWallet(super.cryptoCurrency);

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
  Future<void> refresh() {
    // TODO: implement refresh
    throw UnimplementedError();
  }

  @override
  Future<void> updateBalance() {
    // TODO: implement updateBalance
    throw UnimplementedError();
  }

  @override
  Future<void> updateNode() {
    // TODO: implement updateNode
    throw UnimplementedError();
  }

  @override
  Future<void> updateTransactions() {
    // TODO: implement updateTransactions
    throw UnimplementedError();
  }

  @override
  Future<void> updateUTXOs() {
    // TODO: implement updateUTXOs
    throw UnimplementedError();
  }
}
