import 'dart:async';
import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:http/http.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/utxo.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/event_bus/events/global/node_connection_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/global_event_bus.dart';
import 'package:stackwallet/services/mixins/wallet_cache.dart';
import 'package:stackwallet/services/mixins/wallet_db.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/transaction_notification_tracker.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/fee_rate_type_enum.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:tezart/tezart.dart';
import 'package:tuple/tuple.dart';

const int MINIMUM_CONFIRMATIONS = 1;

class TezosWallet extends CoinServiceAPI with WalletCache, WalletDB {
  TezosWallet({
    required String walletId,
    required String walletName,
    required Coin coin,
    required SecureStorageInterface secureStore,
    required TransactionNotificationTracker tracker,
    MainDB? mockableOverride,
  }) {
    txTracker = tracker;
    _walletId = walletId;
    _walletName = walletName;
    _coin = coin;
    _secureStore = secureStore;
    initCache(walletId, coin);
    initWalletDB(mockableOverride: mockableOverride);
  }

  NodeModel? _xtzNode;

  NodeModel getCurrentNode() {
    return _xtzNode ??
        NodeService(secureStorageInterface: _secureStore)
            .getPrimaryNodeFor(coin: Coin.tezos) ??
        DefaultNodes.getNodeFor(Coin.tezos);
  }

  Future<Keystore> getKeystore() async {
    return Keystore.fromMnemonic((await mnemonicString).toString());
  }

  @override
  String get walletId => _walletId;
  late String _walletId;

  @override
  String get walletName => _walletName;
  late String _walletName;

  @override
  set walletName(String name) => _walletName = name;

  @override
  set isFavorite(bool markFavorite) {
    _isFavorite = markFavorite;
    updateCachedIsFavorite(markFavorite);
  }

  @override
  bool get isFavorite => _isFavorite ??= getCachedIsFavorite();
  bool? _isFavorite;

  @override
  Coin get coin => _coin;
  late Coin _coin;

  late SecureStorageInterface _secureStore;
  late final TransactionNotificationTracker txTracker;
  final _prefs = Prefs.instance;

  Timer? timer;
  bool _shouldAutoSync = false;
  Timer? _networkAliveTimer;

  @override
  bool get shouldAutoSync => _shouldAutoSync;

  @override
  set shouldAutoSync(bool shouldAutoSync) {
    if (_shouldAutoSync != shouldAutoSync) {
      _shouldAutoSync = shouldAutoSync;
      if (!shouldAutoSync) {
        timer?.cancel();
        timer = null;
        stopNetworkAlivePinging();
      } else {
        startNetworkAlivePinging();
        refresh();
      }
    }
  }

  void startNetworkAlivePinging() {
    // call once on start right away
    _periodicPingCheck();

    // then periodically check
    _networkAliveTimer = Timer.periodic(
      Constants.networkAliveTimerDuration,
      (_) async {
        _periodicPingCheck();
      },
    );
  }

  void stopNetworkAlivePinging() {
    _networkAliveTimer?.cancel();
    _networkAliveTimer = null;
  }

  void _periodicPingCheck() async {
    bool hasNetwork = await testNetworkConnection();

    if (_isConnected != hasNetwork) {
      NodeConnectionStatus status = hasNetwork
          ? NodeConnectionStatus.connected
          : NodeConnectionStatus.disconnected;

      GlobalEventBus.instance.fire(
        NodeConnectionStatusChangedEvent(
          status,
          walletId,
          coin,
        ),
      );

      _isConnected = hasNetwork;
      if (hasNetwork) {
        unawaited(refresh());
      }
    }
  }

  @override
  Balance get balance => _balance ??= getCachedBalance();
  Balance? _balance;

  @override
  Future<Map<String, dynamic>> prepareSend(
      {required String address,
      required Amount amount,
      Map<String, dynamic>? args}) async {
    try {
      if (amount.decimals != coin.decimals) {
        throw Exception("Amount decimals do not match coin decimals!");
      }
      var fee = int.parse((await estimateFeeFor(
              amount, (args!["feeRate"] as FeeRateType).index))
          .raw
          .toString());
      Map<String, dynamic> txData = {
        "fee": fee,
        "address": address,
        "recipientAmt": amount,
      };
      return Future.value(txData);
    } catch (e) {
      return Future.error(e);
    }
  }

  @override
  Future<String> confirmSend({required Map<String, dynamic> txData}) async {
    try {
      final amount = txData["recipientAmt"] as Amount;
      final amountInMicroTez = amount.decimal * Decimal.fromInt(1000000);
      final microtezToInt = int.parse(amountInMicroTez.toString());

      final int feeInMicroTez = int.parse(txData["fee"].toString());
      final String destinationAddress = txData["address"] as String;
      final secretKey =
          Keystore.fromMnemonic((await mnemonicString)!).secretKey;
      Logging.instance.log(secretKey, level: LogLevel.Info);
      final sourceKeyStore = Keystore.fromSecretKey(secretKey);
      final client = TezartClient(getCurrentNode().host);
      //TODO - Update gas Limit
      final operation = await client.transferOperation(
          source: sourceKeyStore,
          destination: destinationAddress,
          amount: microtezToInt,
          customFee: feeInMicroTez,
          customGasLimit: 400);
      await operation.executeAndMonitor(); // This line gives an error
      return Future.value("");
    } catch (e) {
      Logging.instance.log(e.toString(), level: LogLevel.Error);
      return Future.error(e);
    }
  }

  @override
  Future<String> get currentReceivingAddress async {
    var mneString = await mnemonicString;
    if (mneString == null) {
      throw Exception("No mnemonic found!");
    }
    return Future.value((Keystore.fromMnemonic(mneString)).address);
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, int feeRate) async {
    // TODO: Check if this is correct
    var api = "https://api.tzstats.com/series/op?start_date=today&collapse=10d";
    var response = jsonDecode((await get(Uri.parse(api))).body)[0];
    double totalFees = response[4] as double;
    int totalTxs = response[8] as int;
    int feePerTx = (totalFees / totalTxs * 1000000).floor();
    int estimatedFee = 0;
    Logging.instance.log("feePerTx:$feePerTx", level: LogLevel.Info);
    Logging.instance.log("feeRate:$feeRate", level: LogLevel.Info);
    switch (feeRate) {
      case 0:
        estimatedFee = feePerTx * 2;
      case 1:
        estimatedFee = feePerTx;
      case 2:
      case 3:
        estimatedFee = (feePerTx / 2).floor();
      default:
        estimatedFee = feeRate;
    }
    Logging.instance.log("estimatedFee:$estimatedFee", level: LogLevel.Info);
    return Amount(
        rawValue: BigInt.from(estimatedFee), fractionDigits: coin.decimals);
  }

  @override
  Future<void> exit() {
    _hasCalledExit = true;
    return Future.value();
  }

  @override
  Future<FeeObject> get fees async {
    // TODO: Check if this is correct
    var api = "https://api.tzstats.com/series/op?start_date=today&collapse=10d";
    var response = jsonDecode((await get(Uri.parse(api))).body);
    double totalFees = response[0][4] as double;
    int totalTxs = response[0][8] as int;
    int feePerTx = (totalFees / totalTxs * 1000000).floor();
    Logging.instance.log("feePerTx:$feePerTx", level: LogLevel.Info);
    // TODO: fix numberOfBlocks
    return FeeObject(
      numberOfBlocksFast: 3,
      numberOfBlocksAverage: 10,
      numberOfBlocksSlow: 30,
      fast: (feePerTx * 2),
      medium: feePerTx,
      slow: (feePerTx / 2).floor(),
    );
  }

  @override
  Future<void> fullRescan(
      int maxUnusedAddressGap, int maxNumberOfIndexesToCheck) {
    refresh();
    return Future.value();
  }

  @override
  Future<bool> generateNewAddress() {
    // TODO: implement generateNewAddress
    throw UnimplementedError();
  }

  @override
  bool get hasCalledExit => _hasCalledExit;
  bool _hasCalledExit = false;

  @override
  Future<void> initializeExisting() async {
    await _prefs.init();
  }

  @override
  Future<void> initializeNew() async {
    if ((await mnemonicString) != null || (await mnemonicPassphrase) != null) {
      throw Exception(
          "Attempted to overwrite mnemonic on generate new wallet!");
    }

    await _prefs.init();

    var newKeystore = Keystore.random();
    await _secureStore.write(
      key: '${_walletId}_mnemonic',
      value: newKeystore.mnemonic,
    );
    await _secureStore.write(
      key: '${_walletId}_mnemonicPassphrase',
      value: "",
    );

    final address = Address(
      walletId: walletId,
      value: newKeystore.address,
      publicKey: [], // TODO: Add public key
      derivationIndex: 0,
      derivationPath: null,
      type: AddressType.unknown,
      subType: AddressSubType.unknown,
    );

    await db.putAddress(address);

    await Future.wait([
      updateCachedId(walletId),
      updateCachedIsFavorite(false),
    ]);
  }

  @override
  bool get isConnected => _isConnected;
  bool _isConnected = false;

  @override
  bool get isRefreshing => refreshMutex;
  bool refreshMutex = false;

  @override
  // TODO: implement maxFee
  Future<int> get maxFee => throw UnimplementedError();

  @override
  Future<List<String>> get mnemonic async {
    final mnemonic = await mnemonicString;
    final mnemonicPassphrase = await this.mnemonicPassphrase;
    if (mnemonic == null) {
      throw Exception("No mnemonic found!");
    }
    if (mnemonicPassphrase == null) {
      throw Exception("No mnemonic passphrase found!");
    }
    return mnemonic.split(" ");
  }

  @override
  Future<String?> get mnemonicPassphrase =>
      _secureStore.read(key: '${_walletId}_mnemonicPassphrase');

  @override
  Future<String?> get mnemonicString =>
      _secureStore.read(key: '${_walletId}_mnemonic');

  @override
  Future<void> recoverFromMnemonic(
      {required String mnemonic,
      String? mnemonicPassphrase,
      required int maxUnusedAddressGap,
      required int maxNumberOfIndexesToCheck,
      required int height}) async {
    if ((await mnemonicString) != null ||
        (await this.mnemonicPassphrase) != null) {
      throw Exception("Attempted to overwrite mnemonic on restore!");
    }
    await _secureStore.write(
        key: '${_walletId}_mnemonic', value: mnemonic.trim());
    await _secureStore.write(
      key: '${_walletId}_mnemonicPassphrase',
      value: mnemonicPassphrase ?? "",
    );

    final address = Address(
      walletId: walletId,
      value: Keystore.fromMnemonic(mnemonic).address,
      publicKey: [], // TODO: Add public key
      derivationIndex: 0,
      derivationPath: null,
      type: AddressType.unknown,
      subType: AddressSubType.unknown,
    );

    await db.putAddress(address);

    await Future.wait([
      updateCachedId(walletId),
      updateCachedIsFavorite(false),
    ]);
  }

  Future<void> updateBalance() async {
    try {
      var api =
          "${getCurrentNode().host}/chains/main/blocks/head/context/contracts/${await currentReceivingAddress}/balance";
      var theBalance = (await get(Uri.parse(api)).then((value) => value.body))
          .substring(
              1,
              (await get(Uri.parse(api)).then((value) => value.body)).length -
                  2);
      Logging.instance.log(
          "Balance for ${await currentReceivingAddress}: $theBalance",
          level: LogLevel.Info);
      var balanceInAmount = Amount(
          rawValue: BigInt.parse(theBalance.toString()),
          fractionDigits: coin.decimals);
      _balance = Balance(
        total: balanceInAmount,
        spendable: balanceInAmount,
        blockedTotal:
            Amount(rawValue: BigInt.parse("0"), fractionDigits: coin.decimals),
        pendingSpendable:
            Amount(rawValue: BigInt.parse("0"), fractionDigits: coin.decimals),
      );
      await updateCachedBalance(_balance!);
    } catch (e, s) {
      Logging.instance
          .log("ERROR GETTING BALANCE ${e.toString()}", level: LogLevel.Error);
    }
  }

  Future<void> updateTransactions() async {
    // TODO: Use node RPC instead of tzstats API
    var api =
        "https://api.tzstats.com/tables/op?address=${await currentReceivingAddress}";
    var jsonResponse =
        jsonDecode(await get(Uri.parse(api)).then((value) => value.body));

    List<Tuple2<Transaction, Address>> txs = [];

    for (var tx in jsonResponse as List) {
      if (tx[1] == "transaction") {
        var txApi =
            "https://api.tzstats.com/explorer/op/${tx[0]}"; //Get transactions by Unique Id, this way we will only get txs
        var txJsonResponse =
            jsonDecode(await get(Uri.parse(txApi)).then((value) => value.body));
        // Check if list is larger than 1 (if it is, it's a batch transaction)
        if (!((txJsonResponse as List).length > 1)) {
          for (var (opJson as Map) in txJsonResponse) {
            if (opJson.containsKey("volume")) {
              // This is to check if transaction is a token transfer
              TransactionType txType;
              if (opJson["sender"] == (await currentReceivingAddress)) {
                txType = TransactionType.outgoing;
              } else {
                txType = TransactionType.incoming;
              }
              var theTx = Transaction(
                walletId: walletId,
                txid: opJson["hash"].toString(),
                timestamp: DateTime.parse(opJson["time"].toString())
                        .toUtc()
                        .millisecondsSinceEpoch ~/
                    1000,
                type: txType,
                subType: TransactionSubType.none,
                amount: (float.parse(opJson["volume"].toString()) * 1000000)
                    .toInt(),
                amountString: Amount(
                        rawValue: BigInt.parse(
                            (float.parse(opJson["volume"].toString()) * 1000000)
                                .toInt()
                                .toString()),
                        fractionDigits: coin.decimals)
                    .toJsonString(),
                fee: (float.parse(opJson["fee"].toString()) * 1000000).toInt(),
                height: int.parse(opJson["height"].toString()),
                isCancelled: false,
                isLelantus: false,
                slateId: "",
                otherData: "",
                inputs: [],
                outputs: [],
                nonce: 0,
                numberOfMessages: null,
              );
              var theAddress = Address(
                walletId: walletId,
                value: opJson["receiver"].toString(),
                publicKey: [], // TODO: Add public key
                derivationIndex: 0,
                derivationPath: null,
                type: AddressType.unknown,
                subType: AddressSubType.unknown,
              );
              txs.add(Tuple2(theTx, theAddress));
            }
          }
        }
      }
    }
    Logging.instance.log("Transactions: $txs", level: LogLevel.Info);
    await db.addNewTransactionData(txs, walletId);
  }

  Future<void> updateChainHeight() async {
    try {
      var api = "${getCurrentNode().host}/chains/main/blocks/head/header/shell";
      var jsonParsedResponse =
          jsonDecode(await get(Uri.parse(api)).then((value) => value.body));
      final int intHeight = int.parse(jsonParsedResponse["level"].toString());
      Logging.instance.log("Chain height: $intHeight", level: LogLevel.Info);
      await updateCachedChainHeight(intHeight);
    } catch (e, s) {
      Logging.instance
          .log("GET CHAIN HEIGHT ERROR ${e.toString()}", level: LogLevel.Error);
    }
  }

  @override
  Future<void> refresh() {
    updateChainHeight();
    updateBalance();
    updateTransactions();
    return Future.value();
  }

  @override
  int get storedChainHeight => getCachedChainHeight();

  @override
  Future<bool> testNetworkConnection() async {
    try {
      await get(Uri.parse(
          "${getCurrentNode().host}:${getCurrentNode().port}/chains/main/blocks/head/header/shell"));
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<Transaction>> get transactions =>
      db.getTransactions(walletId).findAll();

  @override
  Future<void> updateNode(bool shouldRefresh) async {
    _xtzNode = NodeService(secureStorageInterface: _secureStore)
            .getPrimaryNodeFor(coin: coin) ??
        DefaultNodes.getNodeFor(coin);

    if (shouldRefresh) {
      await refresh();
    }
  }

  @override
  Future<void> updateSentCachedTxData(Map<String, dynamic> txData) {
    // TODO: implement updateSentCachedTxData
    throw UnimplementedError();
  }

  @override
  // TODO: implement utxos
  Future<List<UTXO>> get utxos => throw UnimplementedError();

  @override
  bool validateAddress(String address) {
    return RegExp(r"^tz[1-9A-HJ-NP-Za-km-z]{34}$").hasMatch(address);
  }
}
