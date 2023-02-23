import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:ethereum_addresses/ethereum_addresses.dart';
import 'package:http/http.dart';
import 'package:stackwallet/models/ethereum/eth_token.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/models/paymint/transactions_model.dart';
import 'package:stackwallet/services/ethereum/ethereum_api.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/transaction_notification_tracker.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/fee_rate_type_enum.dart';
import 'package:stackwallet/utilities/eth_commons.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/web3dart.dart' as transaction;

const int MINIMUM_CONFIRMATIONS = 3;

class EthereumTokenService {
  final EthToken token;

  late bool shouldAutoSync;
  late EthereumAddress _contractAddress;
  late EthPrivateKey _credentials;
  late DeployedContract _contract;
  late ContractFunction _balanceFunction;
  late ContractFunction _sendFunction;
  late Future<List<String>> _walletMnemonic;
  late SecureStorageInterface _secureStore;
  late String _tokenAbi;
  late Web3Client _client;
  late final TransactionNotificationTracker txTracker;
  TransactionData? cachedTxData;

  final _gasLimit = 200000;

  EthereumTokenService({
    required this.token,
    required Future<List<String>> walletMnemonic,
    required SecureStorageInterface secureStore,
  }) {
    _contractAddress = EthereumAddress.fromHex(token.contractAddress);
    _walletMnemonic = walletMnemonic;
    _secureStore = secureStore;
  }

  Future<List<String>> get allOwnAddresses =>
      _allOwnAddresses ??= _fetchAllOwnAddresses();
  Future<List<String>>? _allOwnAddresses;

  Future<List<String>> _fetchAllOwnAddresses() async {
    List<String> addresses = [];
    final ownAddress = _credentials.address;
    addresses.add(ownAddress.toString());
    return addresses;
  }

  Future<Decimal> get availableBalance async {
    return await totalBalance;
  }

  Coin get coin => Coin.ethereum;

  Future<String> confirmSend({required Map<String, dynamic> txData}) async {
    final amount = txData['recipientAmt'];
    final decimalAmount =
        Format.satoshisToAmount(amount as int, coin: Coin.ethereum);
    final bigIntAmount =
        amountToBigInt(decimalAmount.toDouble(), token.decimals);

    final sentTx = await _client.sendTransaction(
        _credentials,
        transaction.Transaction.callContract(
            contract: _contract,
            function: _sendFunction,
            parameters: [
              EthereumAddress.fromHex(txData['address'] as String),
              bigIntAmount
            ],
            maxGas: _gasLimit,
            gasPrice: EtherAmount.fromUnitAndValue(
                EtherUnit.wei, txData['feeInWei'])));

    return sentTx;
  }

  Future<String> get currentReceivingAddress async {
    final _currentReceivingAddress = await _credentials.extractAddress();
    final checkSumAddress =
        checksumEthereumAddress(_currentReceivingAddress.toString());
    return checkSumAddress;
  }

  Future<int> estimateFeeFor(int satoshiAmount, int feeRate) async {
    final fee = estimateFee(feeRate, _gasLimit, token.decimals);
    return Format.decimalAmountToSatoshis(Decimal.parse(fee.toString()), coin);
  }

  Future<FeeObject> get fees => _feeObject ??= _getFees();
  Future<FeeObject>? _feeObject;

  Future<FeeObject> _getFees() async {
    return await EthereumAPI.getFees();
  }

  Future<void> initializeExisting() async {
    _tokenAbi = (await _secureStore.read(
        key: '${_contractAddress.toString()}_tokenAbi'))!;

    final mnemonic = await _walletMnemonic;
    String mnemonicString = mnemonic.join(' ');

    //Get private key for given mnemonic
    // TODO: replace empty string with actual passphrase
    String privateKey = getPrivateKey(mnemonicString, "");
    _credentials = EthPrivateKey.fromHex(privateKey);

    _contract = DeployedContract(
        ContractAbi.fromJson(_tokenAbi, token.name), _contractAddress);
    _balanceFunction = _contract.function('balanceOf');
    _sendFunction = _contract.function('transfer');
    _client = await getEthClient();

    // print(_credentials.p)
  }

  Future<void> initializeNew() async {
    AbiRequestResponse abi =
        await EthereumAPI.fetchTokenAbi(_contractAddress.hex);
    //Fetch token ABI so we can call token functions
    if (abi.message == "OK") {
      _tokenAbi = abi.result;
      //Store abi in secure store
      await _secureStore.write(
          key: '${_contractAddress.hex}_tokenAbi', value: _tokenAbi);
    } else {
      throw Exception('Failed to load token abi');
    }

    final mnemonic = await _walletMnemonic;
    String mnemonicString = mnemonic.join(' ');

    //Get private key for given mnemonic
    // TODO: replace empty string with actual passphrase
    String privateKey = getPrivateKey(mnemonicString, "");
    _credentials = EthPrivateKey.fromHex(privateKey);

    _contract = DeployedContract(
        ContractAbi.fromJson(_tokenAbi, token.name), _contractAddress);
    _balanceFunction = _contract.function('balanceOf');
    _sendFunction = _contract.function('transfer');
    _client = await getEthClient();
  }

  // TODO: implement isRefreshing
  bool get isRefreshing => throw UnimplementedError();

  Future<int> get maxFee async {
    final fee = (await fees).fast;
    final feeEstimate = await estimateFeeFor(0, fee);
    return feeEstimate;
  }

  Future<Map<String, dynamic>> prepareSend(
      {required String address,
      required int satoshiAmount,
      Map<String, dynamic>? args}) async {
    final feeRateType = args?["feeRate"];
    int fee = 0;
    final feeObject = await fees;
    switch (feeRateType) {
      case FeeRateType.fast:
        fee = feeObject.fast;
        break;
      case FeeRateType.average:
        fee = feeObject.medium;
        break;
      case FeeRateType.slow:
        fee = feeObject.slow;
        break;
    }

    final feeEstimate = await estimateFeeFor(satoshiAmount, fee);

    bool isSendAll = false;
    final balance =
        Format.decimalAmountToSatoshis(await availableBalance, coin);
    if (satoshiAmount == balance) {
      isSendAll = true;
    }

    if (isSendAll) {
      //Send the full balance
      satoshiAmount = balance;
    }

    Map<String, dynamic> txData = {
      "fee": feeEstimate,
      "feeInWei": fee,
      "address": address,
      "recipientAmt": satoshiAmount,
    };

    return txData;
  }

  Future<void> refresh() {
    // TODO: implement refresh
    throw UnimplementedError();
  }

  Future<Decimal> get totalBalance async {
    final balanceRequest = await _client.call(
        contract: _contract,
        function: _balanceFunction,
        params: [_credentials.address]);

    String balance = balanceRequest.first.toString();
    final balanceInDecimal = Format.satoshisToEthTokenAmount(
      int.parse(balance),
      token.decimals,
    );
    return Decimal.parse(balanceInDecimal.toString());
  }

  Future<TransactionData> get transactionData =>
      _transactionData ??= _fetchTransactionData();
  Future<TransactionData>? _transactionData;

  Future<TransactionData> _fetchTransactionData() async {
    String thisAddress = await currentReceivingAddress;

    final List<Map<String, dynamic>> midSortedArray = [];

    AddressTransaction txs =
        await EthereumAPI.fetchAddressTransactions(thisAddress, "tokentx");

    if (txs.message == "OK") {
      final allTxs = txs.result;
      for (var element in allTxs) {
        Map<String, dynamic> midSortedTx = {};
        // create final tx map
        midSortedTx["txid"] = element["hash"];
        int confirmations = int.parse(element['confirmations'].toString());

        int transactionAmount = int.parse(element['value'].toString());
        int decimal = token.decimals; //Eth has up to 18 decimal places
        final transactionAmountInDecimal =
            transactionAmount / (pow(10, decimal));

        //Convert to satoshi, default display for other coins
        final satAmount = Format.decimalAmountToSatoshis(
            Decimal.parse(transactionAmountInDecimal.toString()), coin);

        midSortedTx["confirmed_status"] =
            (confirmations != 0) && (confirmations >= MINIMUM_CONFIRMATIONS);
        midSortedTx["confirmations"] = confirmations;
        midSortedTx["timestamp"] = element["timeStamp"];

        if (checksumEthereumAddress(element["from"].toString()) ==
            thisAddress) {
          midSortedTx["txType"] = "Sent";
        } else {
          midSortedTx["txType"] = "Received";
        }

        midSortedTx["amount"] = satAmount;

        //Calculate fees (GasLimit * gasPrice)
        int txFee = int.parse(element['gasPrice'].toString()) *
            int.parse(element['gasUsed'].toString());
        final txFeeDecimal = txFee / (pow(10, decimal));

        midSortedTx["aliens"] = <dynamic>[];
        midSortedTx["fees"] = Format.decimalAmountToSatoshis(
            Decimal.parse(txFeeDecimal.toString()), coin);
        midSortedTx["address"] = element["to"];
        midSortedTx["inputSize"] = 1;
        midSortedTx["outputSize"] = 1;
        midSortedTx["inputs"] = <dynamic>[];
        midSortedTx["outputs"] = <dynamic>[];
        midSortedTx["height"] = int.parse(element['blockNumber'].toString());

        midSortedArray.add(midSortedTx);
      }
    }

    midSortedArray.sort((a, b) =>
        (int.parse(b['timestamp'].toString())) -
        (int.parse(a['timestamp'].toString())));

    // buildDateTimeChunks
    final Map<String, dynamic> result = {"dateTimeChunks": <dynamic>[]};
    final dateArray = <dynamic>[];

    for (int i = 0; i < midSortedArray.length; i++) {
      final txObject = midSortedArray[i];
      final date =
          extractDateFromTimestamp(int.parse(txObject['timestamp'].toString()));
      final txTimeArray = [txObject["timestamp"], date];

      if (dateArray.contains(txTimeArray[1])) {
        result["dateTimeChunks"].forEach((dynamic chunk) {
          if (extractDateFromTimestamp(
                  int.parse(chunk['timestamp'].toString())) ==
              txTimeArray[1]) {
            if (chunk["transactions"] == null) {
              chunk["transactions"] = <Map<String, dynamic>>[];
            }
            chunk["transactions"].add(txObject);
          }
        });
      } else {
        dateArray.add(txTimeArray[1]);
        final chunk = {
          "timestamp": txTimeArray[0],
          "transactions": [txObject],
        };
        result["dateTimeChunks"].add(chunk);
      }
    }

    final txModel = TransactionData.fromMap(
        TransactionData.fromJson(result).getAllTransactions());

    cachedTxData = txModel;
    return txModel;
  }

  bool validateAddress(String address) {
    return isValidEthereumAddress(address);
  }

  Future<NodeModel> getCurrentNode() async {
    return NodeService(secureStorageInterface: _secureStore)
            .getPrimaryNodeFor(coin: coin) ??
        DefaultNodes.getNodeFor(coin);
  }

  Future<Web3Client> getEthClient() async {
    final node = await getCurrentNode();
    return Web3Client(node.host, Client());
  }
}
