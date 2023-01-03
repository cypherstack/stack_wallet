import 'dart:async';
import 'dart:math';
import 'package:bip39/bip39.dart' as bip39;
import 'package:cw_core/sec_random_native.dart';
import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';
import 'package:stack_wallet_backup/generate_password.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/models/paymint/transactions_model.dart';
import 'package:stackwallet/models/paymint/utxo_model.dart';
import 'package:stackwallet/services/price.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:string_to_hex/string_to_hex.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/web3dart.dart' as web3;
import 'package:web3dart/web3dart.dart' as Transaction;

import 'package:http/http.dart';

import 'package:stackwallet/hive/db.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/services/coins/coin_service.dart';

import 'package:stackwallet/services/event_bus/events/global/node_connection_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/events/global/refresh_percent_changed_event.dart';
import 'package:stackwallet/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/global_event_bus.dart';

const int MINIMUM_CONFIRMATIONS = 1;
const int DUST_LIMIT = 294;

const String GENESIS_HASH_MAINNET =
    "0x11bbe8db4e347b4e8c937c1c8370e4b5ed33adb3db69cbdb7a38e1e50b1b82fa";

class EthereumWallet extends CoinServiceAPI {
  @override
  set isFavorite(bool markFavorite) {
    DB.instance.put<dynamic>(
        boxName: walletId, key: "isFavorite", value: markFavorite);
  }

  @override
  bool get isFavorite {
    try {
      return DB.instance.get<dynamic>(boxName: walletId, key: "isFavorite")
          as bool;
    } catch (e, s) {
      Logging.instance.log(
          "isFavorite fetch failed (returning false by default): $e\n$s",
          level: LogLevel.Error);
      return false;
    }
  }

  @override
  Coin get coin => _coin;

  late SecureStorageInterface _secureStore;

  late PriceAPI _priceAPI;
  final _prefs = Prefs.instance;
  final _client = Web3Client(
      "https://goerli.infura.io/v3/22677300bf774e49a458b73313ee56ba", Client());

  late EthPrivateKey _credentials;
  int _chainId = 5; //5 for testnet and 1 for mainnet

  EthereumWallet(
      {required String walletId,
      required String walletName,
      required Coin coin,
      PriceAPI? priceAPI,
      required SecureStorageInterface secureStore}) {
    _walletId = walletId;
    _walletName = walletName;
    _coin = coin;

    _priceAPI = priceAPI ?? PriceAPI(Client());
    _secureStore = secureStore;
  }

  @override
  bool shouldAutoSync = false;

  @override
  String get walletName => _walletName;
  late String _walletName;

  late Coin _coin;

  @override
  // TODO: implement allOwnAddresses
  Future<List<String>> get allOwnAddresses =>
      _allOwnAddresses ??= _fetchAllOwnAddresses();
  Future<List<String>>? _allOwnAddresses;

  Future<List<String>> _fetchAllOwnAddresses() async {
    List<String> addresses = [];
    final ownAddress = _credentials.address;
    addresses.add(ownAddress.toString());
    return addresses;
  }

  @override
  Future<Decimal> get availableBalance async {
    EtherAmount ethBalance = await _client.getBalance(_credentials.address);
    print("THIS ETH BALANCE IS $ethBalance");
    return Decimal.parse(ethBalance.getValueInUnit(EtherUnit.ether).toString());
  }

  @override
  // TODO: implement balanceMinusMaxFee
  Future<Decimal> get balanceMinusMaxFee => throw UnimplementedError();

  @override
  Future<String> confirmSend({required Map<String, dynamic> txData}) async {
    final gasPrice = await _client.getGasPrice();
    final amount = txData['recipientAmt'];
    final decimalAmount =
        Format.satoshisToAmount(amount as int, coin: Coin.ethereum);
    final bigIntAmount = amountToBigInt(decimalAmount.toDouble());
    final tx = Transaction.Transaction(
        to: EthereumAddress.fromHex(txData['addresss'] as String),
        gasPrice: gasPrice,
        maxGas: 21000,
        value: EtherAmount.inWei(bigIntAmount));
    final transaction =
        await _client.sendTransaction(_credentials, tx, chainId: _chainId);

    Logging.instance.log("Generated TX IS  $transaction", level: LogLevel.Info);
    return transaction;
  }

  BigInt amountToBigInt(num amount) {
    const decimal = 18; //Eth has up to 18 decimal places
    final amountToSendinDecimal = amount * (pow(10, decimal));
    return BigInt.from(amountToSendinDecimal);
  }

  @override
  Future<String> get currentReceivingAddress async {
    final _currentReceivingAddress = _credentials.address;
    return _currentReceivingAddress.toString();
  }

  @override
  Future<int> estimateFeeFor(int satoshiAmount, int feeRate) async {
    print("CALLING ESTIMATE FEE");
    // TODO: implement estimateFeeFor
    // throw UnimplementedError();
    return 1;
  }

  @override
  Future<void> exit() {
    // TODO: implement exit
    throw UnimplementedError();
  }

  @override
  Future<FeeObject> get fees => _feeObject ??= _getFees();
  Future<FeeObject>? _feeObject;

  Future<FeeObject> _getFees() async {
    return FeeObject(
        numberOfBlocksFast: 10,
        numberOfBlocksAverage: 10,
        numberOfBlocksSlow: 10,
        fast: 1,
        medium: 1,
        slow: 1);
  }

  @override
  Future<void> fullRescan(
      int maxUnusedAddressGap, int maxNumberOfIndexesToCheck) {
    // TODO: implement fullRescan
    throw UnimplementedError();
  }

  @override
  Future<bool> generateNewAddress() {
    // TODO: implement generateNewAddress
    throw UnimplementedError();
  }

  bool _hasCalledExit = false;

  @override
  bool get hasCalledExit => _hasCalledExit;

  @override
  Future<void> initializeExisting() async {
    //First get mnemonic so we can initialize credentials
    final mnemonicString =
        await _secureStore.read(key: '${_walletId}_mnemonic');

    _credentials =
        EthPrivateKey.fromHex(StringToHex.toHexString(mnemonicString));

    Logging.instance.log("Opening existing ${coin.prettyName} wallet.",
        level: LogLevel.Info);

    if ((DB.instance.get<dynamic>(boxName: walletId, key: "id")) == null) {
      throw Exception(
          "Attempted to initialize an existing wallet using an unknown wallet ID!");
    }
    await _prefs.init();
    final data =
        DB.instance.get<dynamic>(boxName: walletId, key: "latest_tx_model")
            as TransactionData?;
    if (data != null) {
      _transactionData = Future(() => data);
    }
  }

  @override
  Future<void> initializeNew() async {
    await _prefs.init();
    final String mnemonic = bip39.generateMnemonic(strength: 256);
    _credentials = EthPrivateKey.fromHex(StringToHex.toHexString(mnemonic));

    await _secureStore.write(key: '${_walletId}_mnemonic', value: mnemonic);

    //Store credentials in secure store
    await _secureStore.write(
        key: '${_walletId}_credentials', value: _credentials.toString());

    await DB.instance
        .put<dynamic>(boxName: walletId, key: "id", value: _walletId);
    await DB.instance.put<dynamic>(
        boxName: walletId, key: 'receivingAddresses', value: ["0"]);
    await DB.instance
        .put<dynamic>(boxName: walletId, key: "receivingIndex", value: 0);
    await DB.instance
        .put<dynamic>(boxName: walletId, key: "changeIndex", value: 0);
    await DB.instance.put<dynamic>(
      boxName: walletId,
      key: 'blocked_tx_hashes',
      value: ["0xdefault"],
    ); // A list of transaction hashes to represent frozen utxos in wallet
    // initialize address book entries
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'addressBookEntries',
        value: <String, String>{});
    await DB.instance
        .put<dynamic>(boxName: walletId, key: "isFavorite", value: false);
  }

  bool _isConnected = false;

  @override
  bool get isConnected => _isConnected;

  bool refreshMutex = false;
  @override
  bool get isRefreshing => refreshMutex;

  @override
  // TODO: implement maxFee
  Future<int> get maxFee => throw UnimplementedError();

  @override
  Future<List<String>> get mnemonic => _getMnemonicList();

  Future<int> get chainHeight async {
    try {
      final result = await _client.getBlockNumber();

      return result;
    } catch (e, s) {
      Logging.instance.log("Exception caught in chainHeight: $e\n$s",
          level: LogLevel.Error);
      return -1;
    }
  }

  int get storedChainHeight {
    final storedHeight = DB.instance
        .get<dynamic>(boxName: walletId, key: "storedChainHeight") as int?;
    return storedHeight ?? 0;
  }

  Future<void> updateStoredChainHeight({required int newHeight}) async {
    await DB.instance.put<dynamic>(
        boxName: walletId, key: "storedChainHeight", value: newHeight);
  }

  Future<List<String>> _getMnemonicList() async {
    final mnemonicString =
        await _secureStore.read(key: '${_walletId}_mnemonic');
    if (mnemonicString == null) {
      return [];
    }
    final List<String> data = mnemonicString.split(' ');
    return data;
  }

  @override
  // TODO: implement pendingBalance
  Future<Decimal> get pendingBalance => throw UnimplementedError();

  // Future<Decimal> transactionFee(int satoshiAmount) {}

  @override
  Future<Map<String, dynamic>> prepareSend(
      {required String address,
      required int satoshiAmount,
      Map<String, dynamic>? args}) async {
    final gasPrice = await _client.getGasPrice();

    Map<String, dynamic> txData = {
      "fee": Format.decimalAmountToSatoshis(
          Decimal.parse(gasPrice.getValueInUnit(EtherUnit.ether).toString()),
          coin),
      "addresss": address,
      "recipientAmt": satoshiAmount,
    };

    return txData;
  }

  @override
  Future<void> recoverFromMnemonic(
      {required String mnemonic,
      required int maxUnusedAddressGap,
      required int maxNumberOfIndexesToCheck,
      required int height}) async {
    await _prefs.init();
    print("Mnemonic is $mnemonic");
    _credentials = EthPrivateKey.fromHex(StringToHex.toHexString(mnemonic));

    await _secureStore.write(key: '${_walletId}_mnemonic', value: mnemonic);

    await DB.instance
        .put<dynamic>(boxName: walletId, key: "id", value: _walletId);
    await DB.instance.put<dynamic>(
        boxName: walletId, key: 'receivingAddresses', value: ["0"]);
    await DB.instance
        .put<dynamic>(boxName: walletId, key: "receivingIndex", value: 0);
    await DB.instance
        .put<dynamic>(boxName: walletId, key: "changeIndex", value: 0);
    await DB.instance.put<dynamic>(
      boxName: walletId,
      key: 'blocked_tx_hashes',
      value: ["0xdefault"],
    ); // A list of transaction hashes to represent frozen utxos in wallet
    // initialize address book entries
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'addressBookEntries',
        value: <String, String>{});
    await DB.instance
        .put<dynamic>(boxName: walletId, key: "isFavorite", value: false);
  }

  @override
  Future<void> refresh() async {
    print("CALLING REFRESH");
    // if (refreshMutex) {
    //   Logging.instance.log("$walletId $walletName refreshMutex denied",
    //       level: LogLevel.Info);
    //   return;
    // } else {
    //   refreshMutex = true;
    // }

    print("SYNC STATUS IS ");
    final blockNumber = await _client.getBlockNumber();
    print("BLOCK NUMBER IS ::: ${blockNumber}");

    try {
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.syncing,
          walletId,
          coin,
        ),
      );

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.0, walletId));
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.1, walletId));

      final currentHeight = await chainHeight;
      print("CURRENT CHAIN HEIGHT IS $currentHeight");
      const storedHeight = 1; //await storedChainHeight;

      Logging.instance
          .log("chain height: $currentHeight", level: LogLevel.Info);
      Logging.instance
          .log("cached height: $storedHeight", level: LogLevel.Info);

      if (currentHeight != storedHeight) {
        if (currentHeight != -1) {
          // -1 failed to fetch current height
          unawaited(updateStoredChainHeight(newHeight: currentHeight));
        }

        final newTxData = await _fetchTransactionData();
        print("RETREIVED TX DATA IS $newTxData");
        GlobalEventBus.instance
            .fire(RefreshPercentChangedEvent(0.50, walletId));
      }
    } catch (error, strace) {
      refreshMutex = false;
      GlobalEventBus.instance.fire(
        NodeConnectionStatusChangedEvent(
          NodeConnectionStatus.disconnected,
          walletId,
          coin,
        ),
      );
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.unableToSync,
          walletId,
          coin,
        ),
      );
      Logging.instance.log(
          "Caught exception in refreshWalletData(): $error\n$strace",
          level: LogLevel.Warning);
    }
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
  // TODO: Check difference between total and available balance for eth
  Future<Decimal> get totalBalance async {
    EtherAmount ethBalance = await _client.getBalance(_credentials.address);
    print(
        "BALANCE NOW IS ${ethBalance.getValueInUnit(EtherUnit.ether).toString()}");
    return Decimal.parse(ethBalance.getValueInUnit(EtherUnit.ether).toString());
  }

  @override
  Future<TransactionData> get transactionData =>
      _transactionData ??= _fetchTransactionData();
  Future<TransactionData>? _transactionData;

  TransactionData? cachedTxData;

  @override
  // TODO: implement unspentOutputs
  Future<List<UtxoObject>> get unspentOutputs => throw UnimplementedError();

  @override
  Future<void> updateNode(bool shouldRefresh) {
    // TODO: implement updateNode
    throw UnimplementedError();
  }

  @override
  Future<void> updateSentCachedTxData(Map<String, dynamic> txData) {
    // TODO: implement updateSentCachedTxData
    throw UnimplementedError();
  }

  @override
  bool validateAddress(String address) {
    // TODO: implement validateAddress
    return true;
  }

  Future<TransactionData> _fetchTransactionData() async {
    String thisAddress = await currentReceivingAddress;
    int currentBlock = await chainHeight;
    var balance = await availableBalance;
    print("MY ADDRESS HERE IS $thisAddress");
    var n =
        await _client.getTransactionCount(EthereumAddress.fromHex(thisAddress));

    for (int i = currentBlock;
        i >= 0 && (n > 0 || balance.toDouble() > 0.0);
        --i) {
      try {
        // print(StringToHex.toHexString(i.toString()))
        print("BLOCK IS $i --------->>>>>>>");
        var block = await _client.getBlockInformation(
            blockNumber: i.toString(), isContainFullObj: true);
        // var block = await _client.getBlockInformation()
        print(block);
        // if (block && block.t) {
        //
        // }

      } catch (e, s) {
        print("Error getting transactions ${e.toString()} $s");
      }
    }

    print("THIS CURRECT ADDRESS IS $thisAddress");
    print("THIS CURRECT BLOCK IS $currentBlock");
    print("THIS BALANCE IS $balance");
    print("THIS COUNT TRANSACTIONS IS $n");

    return TransactionData();
    // throw UnimplementedError();
  }

  @override
  String get walletId => _walletId;
  late String _walletId;

  @override
  @override
  set walletName(String newName) => _walletName = newName;
}
