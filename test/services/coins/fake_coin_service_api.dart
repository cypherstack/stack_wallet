import 'package:decimal/decimal.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/models/paymint/transactions_model.dart';
import 'package:stackwallet/models/paymint/utxo_model.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

class FakeCoinServiceAPI extends CoinServiceAPI {
  @override
  // TODO: implement allOwnAddresses
  Future<List<String>> get allOwnAddresses => throw UnimplementedError();

  @override
  // TODO: implement balanceMinusMaxFee
  Future<Decimal> get balanceMinusMaxFee => throw UnimplementedError();

  @override
  // TODO: implement currentReceivingAddress
  Future<String> get currentReceivingAddress => throw UnimplementedError();

  @override
  Future<void> exit() {
    // TODO: implement exit
    throw UnimplementedError();
  }

  @override
  // TODO: implement maxFee
  Future<int> get maxFee => throw UnimplementedError();

  @override
  // TODO: implement mnemonic
  Future<List<String>> get mnemonic => throw UnimplementedError();

  @override
  // TODO: implement pendingBalance
  Future<Decimal> get pendingBalance => throw UnimplementedError();

  @override
  Future<void> refresh() {
    // TODO: implement refresh
    throw UnimplementedError();
  }

  @override
  // TODO: implement totalBalance
  Future<Decimal> get totalBalance => throw UnimplementedError();

  @override
  // TODO: implement transactionData
  Future<TransactionData> get transactionData => throw UnimplementedError();

  @override
  bool validateAddress(String address) {
    // TODO: implement validateAddress
    throw UnimplementedError();
  }

  @override
  // TODO: implement walletId
  String get walletId => throw UnimplementedError();

  @override
  // TODO: implement walletName
  String get walletName => throw UnimplementedError();

  @override
  Future<void> fullRescan(
      int maxUnusedAddressGap, int maxNumberOfIndexesToCheck) {
    // TODO: implement fullRescan
    throw UnimplementedError();
  }

  @override
  // TODO: implement unspentOutputs
  Future<List<UtxoObject>> get unspentOutputs => throw UnimplementedError();

  @override
  bool get isFavorite => throw UnimplementedError();

  @override
  set isFavorite(bool isFavorite) => throw UnimplementedError();

  @override
  late bool shouldAutoSync;

  @override
  // TODO: implement availableBalance
  Future<Decimal> get availableBalance => throw UnimplementedError();

  @override
  // TODO: implement coin
  Coin get coin => throw UnimplementedError();

  @override
  Future<String> confirmSend({required Map<String, dynamic> txData}) {
    // TODO: implement confirmSend
    throw UnimplementedError();
  }

  @override
  Future<int> estimateFeeFor(int satoshiAmount, int feeRate) {
    // TODO: implement estimateFeeFor
    throw UnimplementedError();
  }

  @override
  // TODO: implement hasCalledExit
  bool get hasCalledExit => throw UnimplementedError();

  @override
  Future<void> initializeExisting() {
    // TODO: implement initializeExisting
    throw UnimplementedError();
  }

  @override
  Future<void> initializeNew() {
    // TODO: implement initializeNew
    throw UnimplementedError();
  }

  @override
  // TODO: implement isConnected
  bool get isConnected => throw UnimplementedError();

  @override
  // TODO: implement isRefreshing
  bool get isRefreshing => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> prepareSend(
      {required String address,
      required int satoshiAmount,
      Map<String, dynamic>? args}) {
    // TODO: implement prepareSend
    throw UnimplementedError();
  }

  @override
  Future<void> updateNode(bool shouldRefresh) {
    // TODO: implement updateNode
    throw UnimplementedError();
  }

  @override
  set walletName(String newName) {
    // TODO: implement walletName
  }

  @override
  // TODO: implement fees
  Future<FeeObject> get fees => throw UnimplementedError();

  @override
  Future<void> recoverFromMnemonic(
      {required String mnemonic,
      required int maxUnusedAddressGap,
      required int maxNumberOfIndexesToCheck,
      required int height}) {
    // TODO: implement recoverFromMnemonic
    throw UnimplementedError();
  }

  @override
  Future<String> send(
      {required String toAddress,
      required int amount,
      Map<String, String> args = const {}}) {
    // TODO: implement send
    throw UnimplementedError();
  }

  @override
  Future<bool> testNetworkConnection() {
    // TODO: implement testNetworkConnection
    throw UnimplementedError();
  }

  @override
  Future<bool> generateNewAddress() {
    // TODO: implement generateNewAddress
    throw UnimplementedError();
  }

  @override
  Future<void> updateSentCachedTxData(Map<String, dynamic> txData) {
    // TODO: implement updateSentCachedTxData
    throw UnimplementedError();
  }
}
