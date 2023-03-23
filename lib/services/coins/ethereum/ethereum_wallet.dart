import 'dart:async';

import 'package:bip39/bip39.dart' as bip39;
import 'package:decimal/decimal.dart';
import 'package:ethereum_addresses/ethereum_addresses.dart';
import 'package:http/http.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/ethereum/ethereum_api.dart';
import 'package:stackwallet/services/event_bus/events/global/node_connection_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/events/global/refresh_percent_changed_event.dart';
import 'package:stackwallet/services/event_bus/events/global/updated_in_background_event.dart';
import 'package:stackwallet/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/global_event_bus.dart';
import 'package:stackwallet/services/mixins/wallet_cache.dart';
import 'package:stackwallet/services/mixins/wallet_db.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/notifications_api.dart';
import 'package:stackwallet/services/transaction_notification_tracker.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/fee_rate_type_enum.dart';
import 'package:stackwallet/utilities/eth_commons.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:tuple/tuple.dart';
import 'package:web3dart/web3dart.dart' as web3;

const int MINIMUM_CONFIRMATIONS = 3;

class EthereumWallet extends CoinServiceAPI with WalletCache, WalletDB {
  EthereumWallet({
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

  NodeModel? _ethNode;

  final _gasLimit = 21000;

  Timer? timer;
  Timer? _networkAliveTimer;

  Future<void> updateTokenContracts(List<String> contractAddresses) async {
    // final set = getWalletTokenContractAddresses().toSet();
    // set.addAll(contractAddresses);
    await updateWalletTokenContractAddresses(contractAddresses);

    GlobalEventBus.instance.fire(
      UpdatedInBackgroundEvent(
        "$contractAddresses updated/added for: $walletId $walletName",
        walletId,
      ),
    );
  }

  // Future<void> removeTokenContract(String contractAddress) async {
  //   final set = getWalletTokenContractAddresses().toSet();
  //   set.removeWhere((e) => e == contractAddress);
  //   await updateWalletTokenContractAddresses(set.toList());
  //
  //   GlobalEventBus.instance.fire(
  //     UpdatedInBackgroundEvent(
  //       "$contractAddress removed for: $walletId $walletName",
  //       walletId,
  //     ),
  //   );
  // }

  @override
  String get walletId => _walletId;
  late String _walletId;

  @override
  String get walletName => _walletName;
  late String _walletName;

  @override
  set walletName(String newName) => _walletName = newName;

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
  bool longMutex = false;

  NodeModel getCurrentNode() {
    return _ethNode ??
        NodeService(secureStorageInterface: _secureStore)
            .getPrimaryNodeFor(coin: coin) ??
        DefaultNodes.getNodeFor(coin);
  }

  web3.Web3Client getEthClient() {
    final node = getCurrentNode();
    return web3.Web3Client(node.host, Client());
  }

  late web3.EthPrivateKey _credentials;

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
  Future<List<UTXO>> get utxos => db.getUTXOs(walletId).findAll();

  @override
  Future<List<Transaction>> get transactions => db
      .getTransactions(walletId)
      .filter()
      .otherDataEqualTo(null)
      .sortByTimestampDesc()
      .findAll();

  @override
  Future<String> get currentReceivingAddress async {
    final address = await _currentReceivingAddress;
    return checksumEthereumAddress(
        address?.value ?? _credentials.address.toString());
  }

  Future<Address?> get _currentReceivingAddress => db
      .getAddresses(walletId)
      .filter()
      .typeEqualTo(AddressType.ethereum)
      .subTypeEqualTo(AddressSubType.receiving)
      .sortByDerivationIndexDesc()
      .findFirst();

  @override
  Balance get balance => _balance ??= getCachedBalance();
  Balance? _balance;

  Future<void> updateBalance() async {
    web3.Web3Client client = getEthClient();
    web3.EtherAmount ethBalance = await client.getBalance(_credentials.address);
    // TODO: check if toInt() is ok and if getBalance actually returns enough balance data
    _balance = Balance(
      coin: coin,
      total: ethBalance.getInWei.toInt(),
      spendable: ethBalance.getInWei.toInt(),
      blockedTotal: 0,
      pendingSpendable: 0,
    );
    await updateCachedBalance(_balance!);
  }

  @override
  Future<String> confirmSend({required Map<String, dynamic> txData}) async {
    web3.Web3Client client = getEthClient();
    final chainId = await client.getChainId();
    final amount = txData['recipientAmt'] as int;
    final decimalAmount = Format.satoshisToAmount(amount, coin: coin);
    final bigIntAmount = amountToBigInt(
      decimalAmount.toDouble(),
      Constants.decimalPlacesForCoin(coin),
    );

    final tx = web3.Transaction(
        to: web3.EthereumAddress.fromHex(txData['address'] as String),
        gasPrice: web3.EtherAmount.fromUnitAndValue(
            web3.EtherUnit.wei, txData['feeInWei']),
        maxGas: _gasLimit,
        value: web3.EtherAmount.inWei(bigIntAmount));
    final transaction = await client.sendTransaction(_credentials, tx,
        chainId: chainId.toInt());

    return transaction;
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

  Future<FeeObject> _getFees() => EthereumAPI.getFees();

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
    Logging.instance.log(
      "initializeExisting() ${coin.prettyName} wallet",
      level: LogLevel.Info,
    );

    //First get mnemonic so we can initialize credentials
    String privateKey =
        getPrivateKey((await mnemonicString)!, (await mnemonicPassphrase)!);
    _credentials = web3.EthPrivateKey.fromHex(privateKey);

    if (getCachedId() == null) {
      throw Exception(
          "Attempted to initialize an existing wallet using an unknown wallet ID!");
    }
    await _prefs.init();
  }

  @override
  Future<void> initializeNew() async {
    Logging.instance.log(
      "Generating new ${coin.prettyName} wallet.",
      level: LogLevel.Info,
    );

    if (getCachedId() != null) {
      throw Exception(
          "Attempted to initialize a new wallet using an existing wallet ID!");
    }

    await _prefs.init();

    try {
      await _generateNewWallet();
    } catch (e, s) {
      Logging.instance.log(
        "Exception rethrown from initializeNew(): $e\n$s",
        level: LogLevel.Fatal,
      );
      rethrow;
    }
    await Future.wait([
      updateCachedId(walletId),
      updateCachedIsFavorite(false),
    ]);
  }

  Future<void> _generateNewWallet() async {
    // Logging.instance
    //     .log("IS_INTEGRATION_TEST: $integrationTestFlag", level: LogLevel.Info);
    // if (!integrationTestFlag) {
    //   try {
    //     final features = await electrumXClient.getServerFeatures();
    //     Logging.instance.log("features: $features", level: LogLevel.Info);
    //     switch (coin) {
    //       case Coin.namecoin:
    //         if (features['genesis_hash'] != GENESIS_HASH_MAINNET) {
    //           throw Exception("genesis hash does not match main net!");
    //         }
    //         break;
    //       default:
    //         throw Exception(
    //             "Attempted to generate a EthereumWallet using a non eth coin type: ${coin.name}");
    //     }
    //   } catch (e, s) {
    //     Logging.instance.log("$e/n$s", level: LogLevel.Info);
    //   }
    // }

    // this should never fail - sanity check
    if ((await mnemonicString) != null || (await mnemonicPassphrase) != null) {
      throw Exception(
          "Attempted to overwrite mnemonic on generate new wallet!");
    }

    final String mnemonic = bip39.generateMnemonic(strength: 256);
    await _secureStore.write(key: '${_walletId}_mnemonic', value: mnemonic);
    await _secureStore.write(
      key: '${_walletId}_mnemonicPassphrase',
      value: "",
    );

    String privateKey = getPrivateKey(mnemonic, "");
    _credentials = web3.EthPrivateKey.fromHex(privateKey);

    final address = Address(
      walletId: walletId, value: _credentials.address.toString(),
      publicKey: [], // maybe store address bytes here? seems a waste of space though
      derivationIndex: 0,
      derivationPath: DerivationPath()..value = "$hdPathEthereum/0",
      type: AddressType.ethereum,
      subType: AddressSubType.receiving,
    );

    await db.putAddress(address);

    Logging.instance.log("_generateNewWalletFinished", level: LogLevel.Info);
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

  @override
  Future<String?> get mnemonicString =>
      _secureStore.read(key: '${_walletId}_mnemonic');

  @override
  Future<String?> get mnemonicPassphrase => _secureStore.read(
        key: '${_walletId}_mnemonicPassphrase',
      );

  Future<int> get chainHeight async {
    web3.Web3Client client = getEthClient();
    try {
      final height = await client.getBlockNumber();
      await updateCachedChainHeight(height);
      if (height > storedChainHeight) {
        GlobalEventBus.instance.fire(
          UpdatedInBackgroundEvent(
            "Updated current chain height in $walletId $walletName!",
            walletId,
          ),
        );
      }
      return height;
    } catch (e, s) {
      Logging.instance.log("Exception caught in chainHeight: $e\n$s",
          level: LogLevel.Error);
      return storedChainHeight;
    }
  }

  @override
  int get storedChainHeight => getCachedChainHeight();

  Future<List<String>> _getMnemonicList() async {
    final _mnemonicString = await mnemonicString;
    if (_mnemonicString == null) {
      return [];
    }
    final List<String> data = _mnemonicString.split(' ');
    return data;
  }

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
    final availableBalance = balance.spendable;
    if (satoshiAmount == availableBalance) {
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
  Future<void> recoverFromMnemonic({
    required String mnemonic,
    String? mnemonicPassphrase,
    required int maxUnusedAddressGap,
    required int maxNumberOfIndexesToCheck,
    required int height,
  }) async {
    longMutex = true;
    final start = DateTime.now();

    try {
      // check to make sure we aren't overwriting a mnemonic
      // this should never fail
      if ((await mnemonicString) != null ||
          (await this.mnemonicPassphrase) != null) {
        longMutex = false;
        throw Exception("Attempted to overwrite mnemonic on restore!");
      }

      await _secureStore.write(
          key: '${_walletId}_mnemonic', value: mnemonic.trim());
      await _secureStore.write(
        key: '${_walletId}_mnemonicPassphrase',
        value: mnemonicPassphrase ?? "",
      );

      String privateKey =
          getPrivateKey(mnemonic.trim(), mnemonicPassphrase ?? "");
      _credentials = web3.EthPrivateKey.fromHex(privateKey);

      final address = Address(
        walletId: walletId, value: _credentials.address.toString(),
        publicKey: [], // maybe store address bytes here? seems a waste of space though
        derivationIndex: 0,
        derivationPath: DerivationPath()..value = "$hdPathEthereum/0",
        type: AddressType.ethereum,
        subType: AddressSubType.receiving,
      );

      await db.putAddress(address);

      await Future.wait([
        updateCachedId(walletId),
        updateCachedIsFavorite(false),
      ]);
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

  Future<List<Address>> _fetchAllOwnAddresses() => db
      .getAddresses(walletId)
      .filter()
      .not()
      .typeEqualTo(AddressType.nonWallet)
      .and()
      .group((q) => q
          .subTypeEqualTo(AddressSubType.receiving)
          .or()
          .subTypeEqualTo(AddressSubType.change))
      .findAll();

  Future<bool> refreshIfThereIsNewData() async {
    web3.Web3Client client = getEthClient();
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
        final response = await EthereumAPI.getEthTransactions(
          allOwnAddresses.elementAt(0).value,
        );
        if (response.value != null) {
          final allTxs = response.value!;
          for (final element in allTxs) {
            final txid = element.hash;
            if ((await db
                    .getTransactions(walletId)
                    .filter()
                    .txidMatches(txid)
                    .findFirst()) ==
                null) {
              Logging.instance.log(
                  " txid not found in address history already $txid",
                  level: LogLevel.Info);
              needsRefresh = true;
              break;
            }
          }
        } else {
          Logging.instance.log(
            " refreshIfThereIsNewData get eth transactions failed: ${response.exception}",
            level: LogLevel.Error,
          );
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

  Future<void> getAllTxsToWatch() async {
    if (_hasCalledExit) return;
    List<Transaction> unconfirmedTxnsToNotifyPending = [];
    List<Transaction> unconfirmedTxnsToNotifyConfirmed = [];

    final currentChainHeight = await chainHeight;

    final txCount = await db.getTransactions(walletId).count();

    const paginateLimit = 50;

    for (int i = 0; i < txCount; i += paginateLimit) {
      final transactions = await db
          .getTransactions(walletId)
          .offset(i)
          .limit(paginateLimit)
          .findAll();
      for (final tx in transactions) {
        if (tx.isConfirmed(currentChainHeight, MINIMUM_CONFIRMATIONS)) {
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
      final confirmations = tx.getConfirmations(currentChainHeight);

      if (tx.type == TransactionType.incoming) {
        unawaited(NotificationApi.showNotification(
          title: "Incoming transaction",
          body: walletName,
          walletId: walletId,
          iconAssetName: Assets.svg.iconFor(coin: coin),
          date: DateTime.fromMillisecondsSinceEpoch(tx.timestamp * 1000),
          shouldWatchForUpdates: confirmations < MINIMUM_CONFIRMATIONS,
          coinName: coin.name,
          txid: tx.txid,
          confirmations: confirmations,
          requiredConfirmations: MINIMUM_CONFIRMATIONS,
        ));
        await txTracker.addNotifiedPending(tx.txid);
      } else if (tx.type == TransactionType.outgoing) {
        unawaited(NotificationApi.showNotification(
          title: "Sending transaction",
          body: walletName,
          walletId: walletId,
          iconAssetName: Assets.svg.iconFor(coin: coin),
          date: DateTime.fromMillisecondsSinceEpoch(tx.timestamp * 1000),
          shouldWatchForUpdates: confirmations < MINIMUM_CONFIRMATIONS,
          coinName: coin.name,
          txid: tx.txid,
          confirmations: confirmations,
          requiredConfirmations: MINIMUM_CONFIRMATIONS,
        ));
        await txTracker.addNotifiedPending(tx.txid);
      }
    }

    // notify on confirmed
    for (final tx in unconfirmedTxnsToNotifyConfirmed) {
      if (tx.type == TransactionType.incoming) {
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
      } else if (tx.type == TransactionType.outgoing) {
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
        GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.2, walletId));

        final newTxDataFuture = _refreshTransactions();
        GlobalEventBus.instance
            .fire(RefreshPercentChangedEvent(0.50, walletId));

        final feeObj = _getFees();
        GlobalEventBus.instance
            .fire(RefreshPercentChangedEvent(0.60, walletId));

        GlobalEventBus.instance
            .fire(RefreshPercentChangedEvent(0.70, walletId));
        _feeObject = Future(() => feeObj);
        GlobalEventBus.instance
            .fire(RefreshPercentChangedEvent(0.80, walletId));

        final allTxsToWatch = getAllTxsToWatch();
        await Future.wait([
          updateBalance(),
          newTxDataFuture,
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
        "Caught exception in $walletName $walletId refresh(): $error\n$strace",
        level: LogLevel.Warning,
      );
    }
  }

  @override
  Future<bool> testNetworkConnection() async {
    web3.Web3Client client = getEthClient();
    try {
      await client.getBlockNumber();
      return true;
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

  Future<void> _refreshTransactions() async {
    String thisAddress = await currentReceivingAddress;

    final txsResponse = await EthereumAPI.getEthTransactions(thisAddress);

    if (txsResponse.value != null) {
      final allTxs = txsResponse.value!;
      final List<Tuple2<Transaction, Address?>> txnsData = [];
      for (final element in allTxs) {
        int transactionAmount = element.value;

        bool isIncoming;
        bool txFailed = false;
        if (checksumEthereumAddress(element.from) == thisAddress) {
          if (element.isError != 0) {
            txFailed = true;
          }
          isIncoming = false;
        } else {
          isIncoming = true;
        }

        //Calculate fees (GasLimit * gasPrice)
        // int txFee = element.gasPrice * element.gasUsed;
        int txFee = element.gasCost;

        final String addressString = checksumEthereumAddress(element.to);
        final int height = element.blockNumber;

        final txn = Transaction(
          walletId: walletId,
          txid: element.hash,
          timestamp: element.timestamp,
          type:
              isIncoming ? TransactionType.incoming : TransactionType.outgoing,
          subType: TransactionSubType.none,
          amount: transactionAmount,
          fee: txFee,
          height: height,
          isCancelled: txFailed,
          isLelantus: false,
          slateId: null,
          otherData: null,
          inputs: [],
          outputs: [],
        );

        Address? transactionAddress = await db
            .getAddresses(walletId)
            .filter()
            .valueEqualTo(addressString)
            .findFirst();

        if (transactionAddress == null) {
          if (isIncoming) {
            transactionAddress = Address(
              walletId: walletId,
              value: addressString,
              publicKey: [],
              derivationIndex: 0,
              derivationPath: DerivationPath()..value = "$hdPathEthereum/0",
              type: AddressType.ethereum,
              subType: AddressSubType.receiving,
            );
          } else {
            final myRcvAddr = await currentReceivingAddress;
            final isSentToSelf = myRcvAddr == addressString;

            transactionAddress = Address(
              walletId: walletId,
              value: addressString,
              publicKey: [],
              derivationIndex: isSentToSelf ? 0 : -1,
              derivationPath: isSentToSelf
                  ? (DerivationPath()..value = "$hdPathEthereum/0")
                  : null,
              type: AddressType.ethereum,
              subType: isSentToSelf
                  ? AddressSubType.receiving
                  : AddressSubType.nonWallet,
            );
          }
        }

        txnsData.add(Tuple2(txn, transactionAddress));
      }
      await db.addNewTransactionData(txnsData, walletId);

      // quick hack to notify manager to call notifyListeners if
      // transactions changed
      if (txnsData.isNotEmpty) {
        GlobalEventBus.instance.fire(
          UpdatedInBackgroundEvent(
            "Transactions updated/added for: $walletId $walletName  ",
            walletId,
          ),
        );
      }
    } else {
      Logging.instance.log(
        "Failed to refresh transactions for ${coin.prettyName} $walletName $walletId",
        level: LogLevel.Warning,
      );
    }
  }

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
