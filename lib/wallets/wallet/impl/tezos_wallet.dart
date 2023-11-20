import 'package:isar/isar.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/tezos.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/intermediate/bip39_wallet.dart';

class TezosWallet extends Bip39Wallet {
  TezosWallet(CryptoCurrencyNetwork network) : super(Tezos(network));

  @override
  // TODO: implement changeAddressFilterOperation
  FilterOperation? get changeAddressFilterOperation =>
      throw UnimplementedError();

  @override
  // TODO: implement receivingAddressFilterOperation
  FilterOperation? get receivingAddressFilterOperation =>
      throw UnimplementedError();

  @override
  Future<TxData> confirmSend({required TxData txData}) {
    // TODO: implement confirmSend
    throw UnimplementedError();
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, int feeRate) {
    // TODO: implement estimateFeeFor
    throw UnimplementedError();
  }

  @override
  // TODO: implement fees
  Future<FeeObject> get fees => throw UnimplementedError();

  @override
  Future<bool> pingCheck() {
    // TODO: implement pingCheck
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
  Future<void> updateBalance() {
    // TODO: implement updateBalance
    throw UnimplementedError();
  }

  @override
  Future<void> updateChainHeight() {
    // TODO: implement updateChainHeight
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
