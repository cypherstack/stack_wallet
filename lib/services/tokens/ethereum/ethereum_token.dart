import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:http/http.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/models/paymint/transactions_model.dart';
import 'package:stackwallet/services/tokens/token_service.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/eth_commons.dart';

import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/services/transaction_notification_tracker.dart';
import 'package:web3dart/web3dart.dart';

class AbiRequestResponse {
  final String message;
  final String result;
  final String status;

  const AbiRequestResponse({
    required this.message,
    required this.result,
    required this.status,
  });

  factory AbiRequestResponse.fromJson(Map<String, dynamic> json) {
    return AbiRequestResponse(
      message: json['message'] as String,
      result: json['result'] as String,
      status: json['status'] as String,
    );
  }
}

class EthereumToken extends TokenServiceAPI {
  @override
  late bool shouldAutoSync;
  late String _contractAddress;
  late EthPrivateKey _credentials;
  late Future<List<String>> _walletMnemonic;
  late SecureStorageInterface _secureStore;
  late String _tokenAbi;
  late final TransactionNotificationTracker txTracker;

  String rpcUrl =
      'https://mainnet.infura.io/v3/22677300bf774e49a458b73313ee56ba';

  EthereumToken({
    required String contractAddress,
    required Future<List<String>> walletMnemonic,
    // required SecureStorageInterface secureStore,
  }) {
    _contractAddress = contractAddress;
    _walletMnemonic = walletMnemonic;
    // _secureStore = secureStore;
  }

  Future<AbiRequestResponse> fetchTokenAbi() async {
    final response = await get(Uri.parse(
        "https://api.etherscan.io/api?module=contract&action=getabi&address=$_contractAddress&apikey=EG6J7RJIQVSTP2BS59D3TY2G55YHS5F2HP"));
    if (response.statusCode == 200) {
      return AbiRequestResponse.fromJson(
          json.decode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to load transactions');
    }
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
  Future<void> initializeExisting() async {
    AbiRequestResponse abi = await fetchTokenAbi();
    //Fetch token ABI so we can call token functions
    if (abi.message == "OK") {
      _tokenAbi = abi.result;
    }

    final mnemonic = await _walletMnemonic;
    String mnemonicString = mnemonic.join(' ');

    //Get private key for given mnemonic
    String privateKey = getPrivateKey(mnemonicString);
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
