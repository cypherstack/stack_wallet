import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/utxo.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

class FakeCoinServiceAPI extends CoinServiceAPI {
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
  Future<void> refresh() {
    // TODO: implement refresh
    throw UnimplementedError();
  }

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
  bool get isFavorite => throw UnimplementedError();

  @override
  set isFavorite(bool isFavorite) => throw UnimplementedError();

  @override
  late bool shouldAutoSync;

  @override
  // TODO: implement coin
  Coin get coin => throw UnimplementedError();

  @override
  Future<String> confirmSend({required Map<String, dynamic> txData}) {
    // TODO: implement confirmSend
    throw UnimplementedError();
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, int feeRate) {
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
      required Amount amount,
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
  Future<void> recoverFromMnemonic({
    required String mnemonic,
    String? mnemonicPassphrase,
    required int maxUnusedAddressGap,
    required int maxNumberOfIndexesToCheck,
    required int height,
  }) {
    // TODO: implement recoverFromMnemonic
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

  @override
  // TODO: implement balance
  Balance get balance => throw UnimplementedError();

  @override
  // TODO: implement storedChainHeight
  int get storedChainHeight => throw UnimplementedError();

  @override
  // TODO: implement transactions
  Future<List<Transaction>> get transactions => throw UnimplementedError();

  @override
  // TODO: implement utxos
  Future<List<UTXO>> get utxos => throw UnimplementedError();

  @override
  // TODO: implement mnemonicPassphrase
  Future<String?> get mnemonicPassphrase => throw UnimplementedError();

  @override
  // TODO: implement mnemonicString
  Future<String?> get mnemonicString => throw UnimplementedError();
}
