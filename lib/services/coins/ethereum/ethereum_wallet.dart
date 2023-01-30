import 'dart:async';
import 'dart:math';
import 'package:bip39/bip39.dart' as bip39;

import 'package:decimal/decimal.dart';
import 'package:devicelocale/devicelocale.dart';
import 'package:ethereum_addresses/ethereum_addresses.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/models/paymint/transactions_model.dart';
import 'package:stackwallet/models/paymint/utxo_model.dart';
import 'package:stackwallet/services/price.dart';
import 'package:stackwallet/services/transaction_notification_tracker.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/fee_rate_type_enum.dart';
import 'package:stackwallet/utilities/eth_commons.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/web3dart.dart' as Transaction;
import 'package:stackwallet/models/models.dart' as models;

import 'package:http/http.dart';

import 'package:stackwallet/hive/db.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/services/coins/coin_service.dart';

import 'package:stackwallet/services/event_bus/events/global/node_connection_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/events/global/refresh_percent_changed_event.dart';
import 'package:stackwallet/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/global_event_bus.dart';

import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/services/notifications_api.dart';
import 'package:stackwallet/services/event_bus/events/global/updated_in_background_event.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/utilities/default_nodes.dart';

const int MINIMUM_CONFIRMATIONS = 3;

class EthereumWallet extends CoinServiceAPI {
  NodeModel? _ethNode;
  final _gasLimit = 21000;

  @override
  String get walletId => _walletId;
  late String _walletId;

  late String _walletName;
  late Coin _coin;
  Timer? timer;
  Timer? _networkAliveTimer;

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
  late final TransactionNotificationTracker txTracker;
  late PriceAPI _priceAPI;
  final _prefs = Prefs.instance;
  bool longMutex = false;

  Future<NodeModel> getCurrentNode() async {
    return NodeService(secureStorageInterface: _secureStore)
            .getPrimaryNodeFor(coin: coin) ??
        DefaultNodes.getNodeFor(coin);
  }

  Future<Web3Client> getEthClient() async {
    final node = await getCurrentNode();
    return Web3Client(node.host, Client());
  }

  late EthPrivateKey _credentials;

  EthereumWallet({
    required String walletId,
    required String walletName,
    required Coin coin,
    PriceAPI? priceAPI,
    required SecureStorageInterface secureStore,
    required TransactionNotificationTracker tracker,
  }) {
    txTracker = tracker;
    _walletId = walletId;
    _walletName = walletName;
    _coin = coin;
    _priceAPI = priceAPI ?? PriceAPI(Client());
    _secureStore = secureStore;
  }

  bool _shouldAutoSync = false;

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

  @override
  String get walletName => _walletName;

  @override
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
    Web3Client client = await getEthClient();
    EtherAmount ethBalance = await client.getBalance(_credentials.address);
    return Decimal.parse(ethBalance.getValueInUnit(EtherUnit.ether).toString());
  }

  @override
  Future<Decimal> get balanceMinusMaxFee async =>
      (await availableBalance) -
      (Decimal.fromInt((await maxFee)) /
              Decimal.fromInt(Constants.satsPerCoin(coin)))
          .toDecimal();

  @override
  Future<String> confirmSend({required Map<String, dynamic> txData}) async {
    Web3Client client = await getEthClient();
    final int chainId = await client.getNetworkId();
    final amount = txData['recipientAmt'];
    final decimalAmount =
        Format.satoshisToAmount(amount as int, coin: Coin.ethereum);
    const decimal = 18; //Eth has up to 18 decimal places
    final bigIntAmount = amountToBigInt(decimalAmount.toDouble(), decimal);

    final tx = Transaction.Transaction(
        to: EthereumAddress.fromHex(txData['address'] as String),
        gasPrice:
            EtherAmount.fromUnitAndValue(EtherUnit.wei, txData['feeInWei']),
        maxGas: _gasLimit,
        value: EtherAmount.inWei(bigIntAmount));
    final transaction =
        await client.sendTransaction(_credentials, tx, chainId: chainId);

    return transaction;
  }

  @override
  Future<String> get currentReceivingAddress async {
    final _currentReceivingAddress = _credentials.address;
    final checkSumAddress =
        checksumEthereumAddress(_currentReceivingAddress.toString());
    return checkSumAddress;
  }

  @override
  Future<int> estimateFeeFor(int satoshiAmount, int feeRate) async {
    final fee = estimateFee(feeRate, _gasLimit, 18);
    return Format.decimalAmountToSatoshis(Decimal.parse(fee.toString()), coin);
  }

  @override
  Future<void> exit() async {
    _hasCalledExit = true;
    timer?.cancel();
    timer = null;
    stopNetworkAlivePinging();
  }

  @override
  Future<FeeObject> get fees => _feeObject ??= _getFees();
  Future<FeeObject>? _feeObject;

  Future<FeeObject> _getFees() async {
    return await getFees();
  }

  //Full rescan is not needed for ETH since we have a balance
  @override
  Future<void> fullRescan(
      int maxUnusedAddressGap, int maxNumberOfIndexesToCheck) {
    // TODO: implement fullRescan
    throw UnimplementedError();
  }

  @override
  Future<bool> generateNewAddress() {
    // TODO: implement generateNewAddress - might not be needed for ETH
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
    String privateKey = getPrivateKey(mnemonicString!);
    _credentials = EthPrivateKey.fromHex(privateKey);

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
    await _secureStore.write(key: '${_walletId}_mnemonic', value: mnemonic);
    String privateKey = getPrivateKey(mnemonic);
    _credentials = EthPrivateKey.fromHex(privateKey);
    //Store credentials in secure store
    await _secureStore.write(
        key: '${_walletId}_credentials', value: _credentials.toString());

    await DB.instance
        .put<dynamic>(boxName: walletId, key: "id", value: _walletId);
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'receivingAddresses',
        value: [_credentials.address.toString()]);
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

  @override
  bool get isRefreshing => refreshMutex;

  bool refreshMutex = false;

  @override
  Future<int> get maxFee async {
    final fee = (await fees).fast;
    final feeEstimate = await estimateFeeFor(0, fee);
    return feeEstimate;
  }

  @override
  Future<List<String>> get mnemonic => _getMnemonicList();

  Future<int> get chainHeight async {
    Web3Client client = await getEthClient();
    try {
      final result = await client.getBlockNumber();

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
  // TODO: implement pendingBalance - Not needed since we don't use UTXOs to get a balance
  Future<Decimal> get pendingBalance => throw UnimplementedError();

  @override
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
      //Subtract fee amount from send amount
      satoshiAmount -= feeEstimate;
    }

    Map<String, dynamic> txData = {
      "fee": feeEstimate,
      "feeInWei": fee,
      "address": address,
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
    longMutex = true;
    final start = DateTime.now();

    try {
      if ((await _secureStore.read(key: '${_walletId}_mnemonic')) != null) {
        longMutex = false;
        throw Exception("Attempted to overwrite mnemonic on restore!");
      }

      await _secureStore.write(
          key: '${_walletId}_mnemonic', value: mnemonic.trim());

      String privateKey = getPrivateKey(mnemonic);
      _credentials = EthPrivateKey.fromHex(privateKey);

      await DB.instance
          .put<dynamic>(boxName: walletId, key: "id", value: _walletId);
      await DB.instance
          .put<dynamic>(boxName: walletId, key: "isFavorite", value: false);
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown from recoverFromMnemonic(): $e\n$s",
          level: LogLevel.Error);
      longMutex = false;
      rethrow;
    }

    longMutex = false;
    final end = DateTime.now();
    Logging.instance.log(
        "$walletName recovery time: ${end.difference(start).inMilliseconds} millis",
        level: LogLevel.Info);
  }

  Future<bool> refreshIfThereIsNewData() async {
    Web3Client client = await getEthClient();
    if (longMutex) return false;
    if (_hasCalledExit) return false;
    final currentChainHeight = await chainHeight;

    try {
      bool needsRefresh = false;
      Set<String> txnsToCheck = {};

      for (final String txid in txTracker.pendings) {
        if (!txTracker.wasNotifiedConfirmed(txid)) {
          txnsToCheck.add(txid);
        }
      }

      for (String txid in txnsToCheck) {
        final txn = await client.getTransactionByHash(txid);
        final int txBlockNumber = txn.blockNumber.blockNum;

        final int txConfirmations = currentChainHeight - txBlockNumber;
        bool isUnconfirmed = txConfirmations < MINIMUM_CONFIRMATIONS;
        if (!isUnconfirmed) {
          needsRefresh = true;
          break;
        }
      }
      if (!needsRefresh) {
        var allOwnAddresses = await _fetchAllOwnAddresses();
        AddressTransaction addressTransactions = await fetchAddressTransactions(
            allOwnAddresses.elementAt(0), "txlist");
        final txData = await transactionData;
        if (addressTransactions.message == "OK") {
          final allTxs = addressTransactions.result;
          allTxs.forEach((element) {
            if (txData.findTransaction(element["hash"] as String) == null) {
              Logging.instance.log(
                  " txid not found in address history already ${element["hash"]}",
                  level: LogLevel.Info);
              needsRefresh = true;
            }
          });
        }
      }
      return needsRefresh;
    } catch (e, s) {
      Logging.instance.log(
          "Exception caught in refreshIfThereIsNewData: $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Future<void> getAllTxsToWatch(
    TransactionData txData,
  ) async {
    if (_hasCalledExit) return;
    List<models.Transaction> unconfirmedTxnsToNotifyPending = [];
    List<models.Transaction> unconfirmedTxnsToNotifyConfirmed = [];

    for (final chunk in txData.txChunks) {
      for (final tx in chunk.transactions) {
        if (tx.confirmedStatus) {
          // get all transactions that were notified as pending but not as confirmed
          if (txTracker.wasNotifiedPending(tx.txid) &&
              !txTracker.wasNotifiedConfirmed(tx.txid)) {
            unconfirmedTxnsToNotifyConfirmed.add(tx);
          }
        } else {
          // get all transactions that were not notified as pending yet
          if (!txTracker.wasNotifiedPending(tx.txid)) {
            unconfirmedTxnsToNotifyPending.add(tx);
          }
        }
      }
    }

    // notify on unconfirmed transactions
    for (final tx in unconfirmedTxnsToNotifyPending) {
      if (tx.txType == "Received") {
        unawaited(NotificationApi.showNotification(
          title: "Incoming transaction",
          body: walletName,
          walletId: walletId,
          iconAssetName: Assets.svg.iconFor(coin: coin),
          date: DateTime.fromMillisecondsSinceEpoch(tx.timestamp * 1000),
          shouldWatchForUpdates: tx.confirmations < MINIMUM_CONFIRMATIONS,
          coinName: coin.name,
          txid: tx.txid,
          confirmations: tx.confirmations,
          requiredConfirmations: MINIMUM_CONFIRMATIONS,
        ));
        await txTracker.addNotifiedPending(tx.txid);
      } else if (tx.txType == "Sent") {
        unawaited(NotificationApi.showNotification(
          title: "Sending transaction",
          body: walletName,
          walletId: walletId,
          iconAssetName: Assets.svg.iconFor(coin: coin),
          date: DateTime.fromMillisecondsSinceEpoch(tx.timestamp * 1000),
          shouldWatchForUpdates: tx.confirmations < MINIMUM_CONFIRMATIONS,
          coinName: coin.name,
          txid: tx.txid,
          confirmations: tx.confirmations,
          requiredConfirmations: MINIMUM_CONFIRMATIONS,
        ));
        await txTracker.addNotifiedPending(tx.txid);
      }
    }

    // notify on confirmed
    for (final tx in unconfirmedTxnsToNotifyConfirmed) {
      if (tx.txType == "Received") {
        unawaited(NotificationApi.showNotification(
          title: "Incoming transaction confirmed",
          body: walletName,
          walletId: walletId,
          iconAssetName: Assets.svg.iconFor(coin: coin),
          date: DateTime.fromMillisecondsSinceEpoch(tx.timestamp * 1000),
          shouldWatchForUpdates: false,
          coinName: coin.name,
        ));
        await txTracker.addNotifiedConfirmed(tx.txid);
      } else if (tx.txType == "Sent") {
        unawaited(NotificationApi.showNotification(
          title: "Outgoing transaction confirmed",
          body: walletName,
          walletId: walletId,
          iconAssetName: Assets.svg.iconFor(coin: coin),
          date: DateTime.fromMillisecondsSinceEpoch(tx.timestamp * 1000),
          shouldWatchForUpdates: false,
          coinName: coin.name,
        ));
        await txTracker.addNotifiedConfirmed(tx.txid);
      }
    }
  }

  @override
  Future<void> refresh() async {
    if (refreshMutex) {
      Logging.instance.log("$walletId $walletName refreshMutex denied",
          level: LogLevel.Info);
      return;
    } else {
      refreshMutex = true;
    }

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

        GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.2, walletId));

        final newTxData = _fetchTransactionData();
        GlobalEventBus.instance
            .fire(RefreshPercentChangedEvent(0.50, walletId));

        final feeObj = _getFees();
        GlobalEventBus.instance
            .fire(RefreshPercentChangedEvent(0.60, walletId));

        _transactionData = Future(() => newTxData);

        GlobalEventBus.instance
            .fire(RefreshPercentChangedEvent(0.70, walletId));
        _feeObject = Future(() => feeObj);
        GlobalEventBus.instance
            .fire(RefreshPercentChangedEvent(0.80, walletId));

        final allTxsToWatch = getAllTxsToWatch(await newTxData);
        await Future.wait([
          newTxData,
          feeObj,
          allTxsToWatch,
        ]);
        GlobalEventBus.instance
            .fire(RefreshPercentChangedEvent(0.90, walletId));
      }
      refreshMutex = false;
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(1.0, walletId));
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.synced,
          walletId,
          coin,
        ),
      );

      if (shouldAutoSync) {
        timer ??= Timer.periodic(const Duration(seconds: 30), (timer) async {
          Logging.instance.log(
              "Periodic refresh check for $walletId $walletName in object instance: $hashCode",
              level: LogLevel.Info);
          if (await refreshIfThereIsNewData()) {
            await refresh();
            GlobalEventBus.instance.fire(UpdatedInBackgroundEvent(
                "New data found in $walletId $walletName in background!",
                walletId));
          }
        });
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
  Future<bool> testNetworkConnection() async {
    Web3Client client = await getEthClient();
    try {
      final result = await client.isListeningForNetwork();
      return result;
    } catch (_) {
      return false;
    }
  }

  void _periodicPingCheck() async {
    bool hasNetwork = await testNetworkConnection();
    _isConnected = hasNetwork;
    if (_isConnected != hasNetwork) {
      NodeConnectionStatus status = hasNetwork
          ? NodeConnectionStatus.connected
          : NodeConnectionStatus.disconnected;
      GlobalEventBus.instance
          .fire(NodeConnectionStatusChangedEvent(status, walletId, coin));
    }
  }

  @override
  Future<Decimal> get totalBalance async {
    Web3Client client = await getEthClient();
    EtherAmount ethBalance = await client.getBalance(_credentials.address);
    return Decimal.parse(ethBalance.getValueInUnit(EtherUnit.ether).toString());
  }

  @override
  Future<TransactionData> get transactionData =>
      _transactionData ??= _fetchTransactionData();
  Future<TransactionData>? _transactionData;

  TransactionData? cachedTxData;

  @override
  // TODO: implement unspentOutputs - NOT NEEDED, ETH DOES NOT USE UTXOs
  Future<List<UtxoObject>> get unspentOutputs => throw UnimplementedError();

  @override
  Future<void> updateNode(bool shouldRefresh) async {
    _ethNode = NodeService(secureStorageInterface: _secureStore)
            .getPrimaryNodeFor(coin: coin) ??
        DefaultNodes.getNodeFor(coin);

    if (shouldRefresh) {
      unawaited(refresh());
    }
  }

  @override
  Future<void> updateSentCachedTxData(Map<String, dynamic> txData) async {
    //Only used for Electrumx coins
  }

  @override
  bool validateAddress(String address) {
    return isValidEthereumAddress(address);
  }

  Future<TransactionData> _fetchTransactionData() async {
    String thisAddress = await currentReceivingAddress;
    final cachedTransactions =
        DB.instance.get<dynamic>(boxName: walletId, key: 'latest_tx_model')
            as TransactionData?;
    int latestTxnBlockHeight =
        DB.instance.get<dynamic>(boxName: walletId, key: "storedTxnDataHeight")
                as int? ??
            0;

    final priceData =
        await _priceAPI.getPricesAnd24hChange(baseCurrency: _prefs.currency);
    Decimal currentPrice = priceData[coin]?.item1 ?? Decimal.zero;
    final List<Map<String, dynamic>> midSortedArray = [];

    AddressTransaction txs =
        await fetchAddressTransactions(thisAddress, "txlist");

    if (txs.message == "OK") {
      final allTxs = txs.result;
      allTxs.forEach((element) {
        Map<String, dynamic> midSortedTx = {};
        // create final tx map
        midSortedTx["txid"] = element["hash"];
        int confirmations = int.parse(element['confirmations'].toString());

        int transactionAmount = int.parse(element['value'].toString());
        const decimal = 18; //Eth has up to 18 decimal places
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
          midSortedTx["txType"] = (int.parse(element["isError"] as String) == 0)
              ? "Sent"
              : "Send Failed";
        } else {
          midSortedTx["txType"] = "Received";
        }

        midSortedTx["amount"] = satAmount;
        final String worthNow = ((currentPrice * Decimal.fromInt(satAmount)) /
                Decimal.fromInt(Constants.satsPerCoin(coin)))
            .toDecimal(scaleOnInfinitePrecision: 2)
            .toStringAsFixed(2);

        //Calculate fees (GasLimit * gasPrice)
        int txFee = int.parse(element['gasPrice'].toString()) *
            int.parse(element['gasUsed'].toString());
        final txFeeDecimal = txFee / (pow(10, decimal));

        midSortedTx["worthNow"] = worthNow;
        midSortedTx["worthAtBlockTimestamp"] = worthNow;
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
      });
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

    final transactionsMap = cachedTransactions?.getAllTransactions() ?? {};
    transactionsMap
        .addAll(TransactionData.fromJson(result).getAllTransactions());

    final txModel = TransactionData.fromMap(transactionsMap);

    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'storedTxnDataHeight',
        value: latestTxnBlockHeight);
    await DB.instance.put<dynamic>(
        boxName: walletId, key: 'latest_tx_model', value: txModel);

    cachedTxData = txModel;
    return txModel;
  }

  @override
  set walletName(String newName) => _walletName = newName;

  void stopNetworkAlivePinging() {
    _networkAliveTimer?.cancel();
    _networkAliveTimer = null;
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
}
