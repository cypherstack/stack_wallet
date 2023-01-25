import 'package:decimal/decimal.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/models/paymint/transactions_model.dart';
import 'package:stackwallet/services/tokens/token_service.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/services/transaction_notification_tracker.dart';

class EthereumToken extends TokenServiceAPI {
  @override
  late bool shouldAutoSync;
  late String _walletId;
  late String _contractAddress;
  late SecureStorageInterface _secureStore;
  late final TransactionNotificationTracker txTracker;

  EthereumToken({
    required String contractAddress,
    required String walletId,
    required SecureStorageInterface secureStore,
    required TransactionNotificationTracker tracker,
  }) {
    txTracker = tracker;
    _walletId = walletId;
    _contractAddress = contractAddress;
    _secureStore = secureStore;
  }

  @override
  // TODO: implement allOwnAddresses
  Future<List<String>> get allOwnAddresses => throw UnimplementedError();

  @override
  // TODO: implement availableBalance
  Future<Decimal> get availableBalance => throw UnimplementedError();

  @override
  // TODO: implement balanceMinusMaxFee
  Future<Decimal> get balanceMinusMaxFee => throw UnimplementedError();

  @override
  // TODO: implement coin
  Coin get coin => throw UnimplementedError();

  @override
  Future<String> confirmSend({required Map<String, dynamic> txData}) {
    // TODO: implement confirmSend
    throw UnimplementedError();
  }

  @override
  // TODO: implement currentReceivingAddress
  Future<String> get currentReceivingAddress => throw UnimplementedError();

  @override
  Future<int> estimateFeeFor(int satoshiAmount, int feeRate) {
    // TODO: implement estimateFeeFor
    throw UnimplementedError();
  }

  @override
  // TODO: implement fees
  Future<FeeObject> get fees => throw UnimplementedError();

  @override
  Future<void> initializeExisting() {
    // TODO: implement initializeExisting
    throw UnimplementedError();
  }

  @override
  Future<void> initializeNew() async {
    throw UnimplementedError();
  }

  @override
  // TODO: implement isConnected
  bool get isConnected => throw UnimplementedError();

  @override
  // TODO: implement isRefreshing
  bool get isRefreshing => throw UnimplementedError();

  @override
  // TODO: implement maxFee
  Future<int> get maxFee => throw UnimplementedError();

  @override
  // TODO: implement pendingBalance
  Future<Decimal> get pendingBalance => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> prepareSend(
      {required String address,
      required int satoshiAmount,
      Map<String, dynamic>? args}) {
    // TODO: implement prepareSend
    throw UnimplementedError();
  }

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
  Future<void> updateSentCachedTxData(Map<String, dynamic> txData) {
    // TODO: implement updateSentCachedTxData
    throw UnimplementedError();
  }

  @override
  bool validateAddress(String address) {
    // TODO: implement validateAddress
    throw UnimplementedError();
  }
}
