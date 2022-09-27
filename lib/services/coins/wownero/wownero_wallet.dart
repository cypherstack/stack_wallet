import 'dart:async';
import 'dart:io';

import 'package:cw_core/monero_transaction_priority.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_wownero/api/exceptions/creation_transaction_exception.dart';
import 'package:cw_wownero/api/wallet.dart';
import 'package:cw_wownero/wownero_amount_format.dart';
import 'package:cw_wownero/wownero_wallet.dart';
import 'package:cw_wownero/pending_wownero_transaction.dart';
import 'package:dart_numerics/dart_numerics.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_libmonero/core/key_service.dart';
import 'package:flutter_libmonero/core/wallet_creation_service.dart';
import 'package:flutter_libmonero/wownero/wownero.dart';
import 'package:flutter_libmonero/view_model/send/output.dart'
    as wownero_output;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:mutex/mutex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stackwallet/hive/db.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/models/paymint/transactions_model.dart';
import 'package:stackwallet/models/paymint/utxo_model.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/event_bus/events/global/blocks_remaining_event.dart';
import 'package:stackwallet/services/event_bus/events/global/node_connection_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/events/global/refresh_percent_changed_event.dart';
import 'package:stackwallet/services/event_bus/events/global/updated_in_background_event.dart';
import 'package:stackwallet/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/global_event_bus.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/price.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/fee_rate_type_enum.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';

const int MINIMUM_CONFIRMATIONS = 10;

//https://github.com/wownero-project/wownero/blob/8361d60aef6e17908658128284899e3a11d808d4/src/cryptonote_config.h#L162
const String GENESIS_HASH_MAINNET =
    "013c01ff0001ffffffffffff03029b2e4c0281c0b02e7c53291a94d1d0cbff8883f8024f5142ee494ffbbd08807121017767aafcde9be00dcfd098715ebcf7f410daebc582fda69d24a28e9d0bc890d1";
const String GENESIS_HASH_TESTNET =
    "013c01ff0001ffffffffffff03029b2e4c0281c0b02e7c53291a94d1d0cbff8883f8024f5142ee494ffbbd08807121017767aafcde9be00dcfd098715ebcf7f410daebc582fda69d24a28e9d0bc890d1";

class WowneroWallet extends CoinServiceAPI {
  static const integrationTestFlag =
      bool.fromEnvironment("IS_INTEGRATION_TEST");
  final _prefs = Prefs.instance;

  Timer? timer;
  Timer? wowneroAutosaveTimer;
  late Coin _coin;

  late FlutterSecureStorageInterface _secureStore;

  late PriceAPI _priceAPI;

  Future<NodeModel> getCurrentNode() async {
    return NodeService().getPrimaryNodeFor(coin: coin) ??
        DefaultNodes.getNodeFor(coin);
  }

  WowneroWallet(
      {required String walletId,
      required String walletName,
      required Coin coin,
      PriceAPI? priceAPI,
      FlutterSecureStorageInterface? secureStore}) {
    _walletId = walletId;
    _walletName = walletName;
    _coin = coin;

    _priceAPI = priceAPI ?? PriceAPI(Client());
    _secureStore =
        secureStore ?? const SecureStorageWrapper(FlutterSecureStorage());
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
        wowneroAutosaveTimer?.cancel();
        timer = null;
        wowneroAutosaveTimer = null;
        stopNetworkAlivePinging();
      } else {
        startNetworkAlivePinging();
        // Walletbase needs to be open for this to work
        refresh();
      }
    }
  }

  @override
  Future<void> updateNode(bool shouldRefresh) async {
    final node = await getCurrentNode();

    final host = Uri.parse(node.host).host;
    await walletBase?.connectToNode(
        node: Node(uri: "$host:${node.port}", type: WalletType.wownero));

    // TODO: is this sync call needed? Do we need to notify ui here?
    await walletBase?.startSync();

    if (shouldRefresh) {
      await refresh();
    }
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
  Future<List<String>> get mnemonic => _getMnemonicList();

  Future<int> get currentNodeHeight async {
    try {
      if (walletBase!.syncStatus! is SyncedSyncStatus &&
          walletBase!.syncStatus!.progress() == 1.0) {
        return await walletBase!.getNodeHeight();
      }
    } catch (e, s) {}
    int _height = -1;
    try {
      _height = (walletBase!.syncStatus as SyncingSyncStatus).height;
    } catch (e, s) {
      Logging.instance.log("$e $s", level: LogLevel.Warning);
    }

    int blocksRemaining = -1;

    try {
      blocksRemaining =
          (walletBase!.syncStatus as SyncingSyncStatus).blocksLeft;
    } catch (e, s) {
      Logging.instance.log("$e $s", level: LogLevel.Warning);
    }
    int currentHeight = _height + blocksRemaining;
    if (_height == -1 || blocksRemaining == -1) {
      currentHeight = int64MaxValue;
    }
    final cachedHeight = DB.instance
            .get<dynamic>(boxName: walletId, key: "storedNodeHeight") as int? ??
        0;

    if (currentHeight > cachedHeight && currentHeight != int64MaxValue) {
      await DB.instance.put<dynamic>(
          boxName: walletId, key: "storedNodeHeight", value: currentHeight);
      return currentHeight;
    } else {
      return cachedHeight;
    }
  }

  Future<int> get currentSyncingHeight async {
    //TODO return the tip of the wownero blockchain
    try {
      if (walletBase!.syncStatus! is SyncedSyncStatus &&
          walletBase!.syncStatus!.progress() == 1.0) {
        Logging.instance
            .log("currentSyncingHeight lol", level: LogLevel.Warning);
        return getSyncingHeight();
      }
    } catch (e, s) {}
    int syncingHeight = -1;
    try {
      syncingHeight = (walletBase!.syncStatus as SyncingSyncStatus).height;
    } catch (e, s) {
      Logging.instance.log("$e $s", level: LogLevel.Warning);
    }
    final cachedHeight =
        DB.instance.get<dynamic>(boxName: walletId, key: "storedSyncingHeight")
                as int? ??
            0;

    if (syncingHeight > cachedHeight) {
      await DB.instance.put<dynamic>(
          boxName: walletId, key: "storedSyncingHeight", value: syncingHeight);
      return syncingHeight;
    } else {
      return cachedHeight;
    }
  }

  Future<void> updateStoredChainHeight({required int newHeight}) async {
    await DB.instance.put<dynamic>(
        boxName: walletId, key: "storedChainHeight", value: newHeight);
  }

  int get storedChainHeight {
    return DB.instance.get<dynamic>(boxName: walletId, key: "storedChainHeight")
            as int? ??
        0;
  }

  /// Increases the index for either the internal or external chain, depending on [chain].
  /// [chain] - Use 0 for receiving (external), 1 for change (internal). Should not be any other value!
  Future<void> _incrementAddressIndexForChain(int chain) async {
    // Here we assume chain == 1 if it isn't 0
    String indexKey = chain == 0 ? "receivingIndex" : "changeIndex";

    final newIndex =
        (DB.instance.get<dynamic>(boxName: walletId, key: indexKey)) + 1;
    await DB.instance
        .put<dynamic>(boxName: walletId, key: indexKey, value: newIndex);
  }

  Future<void> _checkCurrentReceivingAddressesForTransactions() async {
    try {
      await _checkReceivingAddressForTransactions();
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown from _checkCurrentReceivingAddressesForTransactions(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Future<void> _checkReceivingAddressForTransactions() async {
    try {
      int highestIndex = -1;
      for (var element
          in walletBase!.transactionHistory!.transactions!.entries) {
        if (element.value.direction == TransactionDirection.incoming) {
          int curAddressIndex =
              element.value.additionalInfo!['addressIndex'] as int;
          if (curAddressIndex > highestIndex) {
            highestIndex = curAddressIndex;
          }
        }
      }

      // Check the new receiving index
      String indexKey = "receivingIndex";
      final curIndex =
          DB.instance.get<dynamic>(boxName: walletId, key: indexKey) as int;
      if (highestIndex >= curIndex) {
        // First increment the receiving index
        await _incrementAddressIndexForChain(0);
        final newReceivingIndex =
            DB.instance.get<dynamic>(boxName: walletId, key: indexKey) as int;

        // Use new index to derive a new receiving address
        final newReceivingAddress =
            await _generateAddressForChain(0, newReceivingIndex);

        // Add that new receiving address to the array of receiving addresses
        await _addToAddressesArrayForChain(newReceivingAddress, 0);

        // Set the new receiving address that the service

        _currentReceivingAddress = Future(() => newReceivingAddress);
      }
    } on SocketException catch (se, s) {
      Logging.instance.log(
          "SocketException caught in _checkReceivingAddressForTransactions(): $se\n$s",
          level: LogLevel.Error);
      return;
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown from _checkReceivingAddressForTransactions(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  @override
  bool get isRefreshing => refreshMutex;

  bool refreshMutex = false;

  Timer? syncPercentTimer;

  Mutex syncHeightMutex = Mutex();
  Future<void> stopSyncPercentTimer() async {
    syncPercentTimer?.cancel();
    syncPercentTimer = null;
  }

  Future<void> startSyncPercentTimer() async {
    if (syncPercentTimer != null) {
      return;
    }
    syncPercentTimer?.cancel();
    GlobalEventBus.instance
        .fire(RefreshPercentChangedEvent(highestPercentCached, walletId));
    syncPercentTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (syncHeightMutex.isLocked) {
        return;
      }
      await syncHeightMutex.protect(() async {
        // int restoreheight = walletBase!.walletInfo.restoreHeight ?? 0;
        int _height = await currentSyncingHeight;
        int _currentHeight = await currentNodeHeight;
        double progress = 0;
        try {
          progress = walletBase!.syncStatus!.progress();
        } catch (e, s) {
          Logging.instance.log("$e $s", level: LogLevel.Warning);
        }

        final int blocksRemaining = _currentHeight - _height;

        GlobalEventBus.instance
            .fire(BlocksRemainingEvent(blocksRemaining, walletId));

        if (progress == 1 && _currentHeight > 0 && _height > 0) {
          await stopSyncPercentTimer();
          GlobalEventBus.instance.fire(
            WalletSyncStatusChangedEvent(
              WalletSyncStatus.synced,
              walletId,
              coin,
            ),
          );
          return;
        }

        // for some reason this can be 0 which screws up the percent calculation
        // int64MaxValue is NOT the best value to use here
        if (_currentHeight < 1) {
          _currentHeight = int64MaxValue;
        }

        if (_height < 1) {
          _height = 1;
        }

        double restorePercent = progress;
        double highestPercent = highestPercentCached;

        Logging.instance.log(
            "currentSyncingHeight: $_height, nodeHeight: $_currentHeight, restorePercent: $restorePercent, highestPercentCached: $highestPercentCached",
            level: LogLevel.Info);

        if (restorePercent > 0 && restorePercent <= 1) {
          // if (restorePercent > highestPercent) {
          highestPercent = restorePercent;
          highestPercentCached = restorePercent;
          // }
        }

        GlobalEventBus.instance
            .fire(RefreshPercentChangedEvent(highestPercent, walletId));
      });
    });
  }

  double get highestPercentCached =>
      DB.instance.get<dynamic>(boxName: walletId, key: "highestPercentCached")
          as double? ??
      0;
  set highestPercentCached(double value) => DB.instance.put<dynamic>(
        boxName: walletId,
        key: "highestPercentCached",
        value: value,
      );

  /// Refreshes display data for the wallet
  @override
  Future<void> refresh() async {
    if (refreshMutex) {
      Logging.instance.log("$walletId $walletName refreshMutex denied",
          level: LogLevel.Info);
      return;
    } else {
      refreshMutex = true;
    }

    if (walletBase == null) {
      throw Exception("Tried to call refresh() in wownero without walletBase!");
    }

    try {
      await startSyncPercentTimer();
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.syncing,
          walletId,
          coin,
        ),
      );

      final int _currentSyncingHeight = await currentSyncingHeight;
      final int storedHeight = storedChainHeight;
      int _currentNodeHeight = await currentNodeHeight;

      double progress = 0;
      try {
        progress = (walletBase!.syncStatus!).progress();
      } catch (e, s) {
        Logging.instance.log("$e $s", level: LogLevel.Warning);
      }
      await _fetchTransactionData();

      bool stillSyncing = false;
      Logging.instance.log(
          "storedHeight: $storedHeight, _currentSyncingHeight: $_currentSyncingHeight, _currentNodeHeight: $_currentNodeHeight, progress: $progress, issynced: ${await walletBase!.isConnected()}",
          level: LogLevel.Info);

      if (progress < 1.0) {
        stillSyncing = true;
      }

      if (_currentSyncingHeight > storedHeight) {
        // 0 is returned from wownero as I assume an error?????
        if (_currentSyncingHeight > 0) {
          // 0 failed to fetch current height???
          await updateStoredChainHeight(newHeight: _currentSyncingHeight);
        }
      }

      await _checkCurrentReceivingAddressesForTransactions();
      String indexKey = "receivingIndex";
      final curIndex =
          DB.instance.get<dynamic>(boxName: walletId, key: indexKey) as int;
      // Use new index to derive a new receiving address
      try {
        final newReceivingAddress = await _generateAddressForChain(0, curIndex);
        _currentReceivingAddress = Future(() => newReceivingAddress);
      } catch (e, s) {
        Logging.instance.log(
            "Failed to call _generateAddressForChain(0, $curIndex): $e\n$s",
            level: LogLevel.Error);
      }
      final newTxData = await _fetchTransactionData();
      _transactionData = Future(() => newTxData);

      if (isActive || shouldAutoSync) {
        timer ??= Timer.periodic(const Duration(seconds: 60), (timer) async {
          debugPrint("run timer");
          //TODO: check for new data and refresh if needed. if wownero even needs this
          // chain height check currently broken
          // if ((await chainHeight) != (await storedChainHeight)) {
          // if (await refreshIfThereIsNewData()) {
          await refresh();
          GlobalEventBus.instance.fire(UpdatedInBackgroundEvent(
              "New data found in $walletId $walletName in background!",
              walletId));
          // }
          // }
        });
        wowneroAutosaveTimer ??=
            Timer.periodic(const Duration(seconds: 93), (timer) async {
          debugPrint("run wownero timer");
          if (isActive) {
            await walletBase?.save();
            GlobalEventBus.instance.fire(UpdatedInBackgroundEvent(
                "New data found in $walletId $walletName in background!",
                walletId));
          }
        });
      }

      if (stillSyncing) {
        debugPrint("still syncing");
        GlobalEventBus.instance.fire(
          WalletSyncStatusChangedEvent(
            WalletSyncStatus.syncing,
            walletId,
            coin,
          ),
        );
        refreshMutex = false;
        return;
      }
      await stopSyncPercentTimer();
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.synced,
          walletId,
          coin,
        ),
      );
      refreshMutex = false;
    } catch (error, strace) {
      refreshMutex = false;
      await stopSyncPercentTimer();
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
          level: LogLevel.Error);
    }
  }

  @override
  // TODO: implement allOwnAddresses
  Future<List<String>> get allOwnAddresses {
    return Future(() => []);
  }

  @override
  Future<Decimal> get balanceMinusMaxFee async =>
      (await availableBalance) -
      (Decimal.fromInt((await maxFee)) / Decimal.fromInt(Constants.satsPerCoin))
          .toDecimal();

  @override
  Future<String> get currentReceivingAddress =>
      _currentReceivingAddress ??= _getCurrentAddressForChain(0);

  @override
  Future<void> exit() async {
    await stopSyncPercentTimer();
    _hasCalledExit = true;
    isActive = false;
    await walletBase?.save(prioritySave: true);
    walletBase?.close();
    wowneroAutosaveTimer?.cancel();
    wowneroAutosaveTimer = null;
    timer?.cancel();
    timer = null;
    stopNetworkAlivePinging();
  }

  bool _hasCalledExit = false;

  @override
  bool get hasCalledExit => _hasCalledExit;

  Future<String>? _currentReceivingAddress;

  Future<FeeObject> _getFees() async {
    return FeeObject(
        numberOfBlocksFast: 10,
        numberOfBlocksAverage: 10,
        numberOfBlocksSlow: 10,
        fast: 4,
        medium: 2,
        slow: 0);
  }

  @override
  Future<FeeObject> get fees => _feeObject ??= _getFees();
  Future<FeeObject>? _feeObject;

  @override
  // TODO: implement fullRescan
  Future<void> fullRescan(
    int maxUnusedAddressGap,
    int maxNumberOfIndexesToCheck,
  ) async {
    var restoreHeight = walletBase?.walletInfo.restoreHeight;
    await walletBase?.rescan(height: restoreHeight);
    GlobalEventBus.instance.fire(
      WalletSyncStatusChangedEvent(
        WalletSyncStatus.syncing,
        walletId,
        coin,
      ),
    );
    return;
  }

  Future<String> _generateAddressForChain(int chain, int index) async {
    //
    String address = walletBase!.getTransactionAddress(chain, index);

    return address;
  }

  /// Adds [address] to the relevant chain's address array, which is determined by [chain].
  /// [address] - Expects a standard native segwit address
  /// [chain] - Use 0 for receiving (external), 1 for change (internal). Should not be any other value!
  Future<void> _addToAddressesArrayForChain(String address, int chain) async {
    String chainArray = '';
    if (chain == 0) {
      chainArray = 'receivingAddresses';
    } else {
      chainArray = 'changeAddresses';
    }

    final addressArray =
        DB.instance.get<dynamic>(boxName: walletId, key: chainArray);
    if (addressArray == null) {
      Logging.instance.log(
          'Attempting to add the following to $chainArray array for chain $chain:${[
            address
          ]}',
          level: LogLevel.Info);
      await DB.instance
          .put<dynamic>(boxName: walletId, key: chainArray, value: [address]);
    } else {
      // Make a deep copy of the existing list
      final List<String> newArray = [];
      addressArray
          .forEach((dynamic _address) => newArray.add(_address as String));
      newArray.add(address); // Add the address passed into the method
      await DB.instance
          .put<dynamic>(boxName: walletId, key: chainArray, value: newArray);
    }
  }

  /// Returns the latest receiving/change (external/internal) address for the wallet depending on [chain]
  /// and
  /// [chain] - Use 0 for receiving (external), 1 for change (internal). Should not be any other value!
  Future<String> _getCurrentAddressForChain(int chain) async {
    // Here, we assume that chain == 1 if it isn't 0
    String arrayKey = chain == 0 ? "receivingAddresses" : "changeAddresses";
    final internalChainArray = (DB.instance
        .get<dynamic>(boxName: walletId, key: arrayKey)) as List<dynamic>;
    return internalChainArray.last as String;
  }

  //TODO: take in the default language when creating wallet.
  Future<void> _generateNewWallet() async {
    Logging.instance
        .log("IS_INTEGRATION_TEST: $integrationTestFlag", level: LogLevel.Info);
    // TODO: ping wownero server and make sure the genesis hash matches
    // if (!integrationTestFlag) {
    //   final features = await electrumXClient.getServerFeatures();
    //   Logging.instance.log("features: $features");
    //   if (_networkType == BasicNetworkType.main) {
    //     if (features['genesis_hash'] != GENESIS_HASH_MAINNET) {
    //       throw Exception("genesis hash does not match main net!");
    //     }
    //   } else if (_networkType == BasicNetworkType.test) {
    //     if (features['genesis_hash'] != GENESIS_HASH_TESTNET) {
    //       throw Exception("genesis hash does not match test net!");
    //     }
    //   }
    // }

    // this should never fail
    if ((await _secureStore.read(key: '${_walletId}_mnemonic')) != null) {
      throw Exception(
          "Attempted to overwrite mnemonic on generate new wallet!");
    }

    storage = const FlutterSecureStorage();
    // TODO: Wallet Service may need to be switched to Wownero
    walletService =
        wownero.createWowneroWalletService(DB.instance.moneroWalletInfoBox);
    prefs = await SharedPreferences.getInstance();
    keysStorage = KeyService(storage!);
    WalletInfo walletInfo;
    WalletCredentials credentials;
    try {
      String name = _walletId;
      final dirPath =
          await pathForWalletDir(name: name, type: WalletType.wownero);
      final path = await pathForWallet(name: name, type: WalletType.wownero);
      credentials = wownero.createWowneroNewWalletCredentials(
        name: name,
        language: "English",
      );

      walletInfo = WalletInfo.external(
          id: WalletBase.idFor(name, WalletType.wownero),
          name: name,
          type: WalletType.wownero,
          isRecovery: false,
          restoreHeight: credentials.height ?? 0,
          date: DateTime.now(),
          path: path,
          dirPath: dirPath,
          // TODO: find out what to put for address
          address: '');
      credentials.walletInfo = walletInfo;

      _walletCreationService = WalletCreationService(
        secureStorage: storage,
        sharedPreferences: prefs,
        walletService: walletService,
        keyService: keysStorage,
      );
      _walletCreationService?.changeWalletType();
      // To restore from a seed
      final wallet = await _walletCreationService?.create(credentials);

      // subtract a couple days to ensure we have a buffer for SWB
      final bufferedCreateHeight =
          getSeedHeightSync(wallet?.seed.trim() as String);

      await DB.instance.put<dynamic>(
          boxName: walletId, key: "restoreHeight", value: bufferedCreateHeight);
      walletInfo.restoreHeight = bufferedCreateHeight;

      await _secureStore.write(
          key: '${_walletId}_mnemonic', value: wallet?.seed.trim());
      walletInfo.address = wallet?.walletAddresses.address;
      await DB.instance
          .add<WalletInfo>(boxName: WalletInfo.boxName, value: walletInfo);
      walletBase?.close();
      walletBase = wallet as WowneroWalletBase;
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrint(s.toString());
    }
    final node = await getCurrentNode();
    final host = Uri.parse(node.host).host;
    await walletBase?.connectToNode(
        node: Node(uri: "$host:${node.port}", type: WalletType.wownero));
    await walletBase?.startSync();
    await DB.instance
        .put<dynamic>(boxName: walletId, key: "id", value: _walletId);

    // Set relevant indexes
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

    // Generate and add addresses to relevant arrays
    final initialReceivingAddress = await _generateAddressForChain(0, 0);
    // final initialChangeAddress = await _generateAddressForChain(1, 0);

    await _addToAddressesArrayForChain(initialReceivingAddress, 0);
    // await _addToAddressesArrayForChain(initialChangeAddress, 1);

    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'receivingAddresses',
        value: [initialReceivingAddress]);
    await DB.instance
        .put<dynamic>(boxName: walletId, key: "receivingIndex", value: 0);

    _currentReceivingAddress = Future(() => initialReceivingAddress);

    Logging.instance.log("_generateNewWalletFinished", level: LogLevel.Info);
  }

  @override
  // TODO: implement initializeWallet
  Future<bool> initializeNew() async {
    await _prefs.init();
    // TODO: ping actual wownero network
    // try {
    //   final hasNetwork = await _electrumXClient.ping();
    //   if (!hasNetwork) {
    //     return false;
    //   }
    // } catch (e, s) {
    //   Logging.instance.log("Caught in initializeWallet(): $e\n$s");
    //   return false;
    // }
    storage = const FlutterSecureStorage();
    walletService =
        wownero.createWowneroWalletService(DB.instance.moneroWalletInfoBox);
    prefs = await SharedPreferences.getInstance();
    keysStorage = KeyService(storage!);

    await _generateNewWallet();
    // var password;
    // try {
    //   password =
    //       await keysStorage?.getWalletPassword(walletName: this._walletId);
    // } catch (e, s) {
    //   Logging.instance.log("$e $s");
    //   Logging.instance.log("Generating new ${coin.ticker} wallet.");
    //   // Triggers for new users automatically. Generates new wallet
    //   await _generateNewWallet(wallet);
    //   await wallet.put("id", this._walletId);
    //   return true;
    // }
    // walletBase = (await walletService?.openWallet(this._walletId, password))
    //     as WowneroWalletBase;
    // Logging.instance.log("Opening existing ${coin.ticker} wallet.");
    // // Wallet already exists, triggers for a returning user
    // final currentAddress = awaicurrentHeightt _getCurrentAddressForChain(0);
    // this._currentReceivingAddress = Future(() => currentAddress);
    //
    // await walletBase?.connectToNode(
    //     node: Node(
    //         uri: "xmr-node.cakewallet.com:18081", type: WalletType.wownero));
    // walletBase?.startSync();

    return true;
  }

  @override
  Future<void> initializeExisting() async {
    Logging.instance.log(
        "Opening existing ${coin.prettyName} wallet $walletName...",
        level: LogLevel.Info);

    if ((DB.instance.get<dynamic>(boxName: walletId, key: "id")) == null) {
      debugPrint("Exception was thrown");
      throw Exception(
          "Attempted to initialize an existing wallet using an unknown wallet ID!");
    }

    storage = const FlutterSecureStorage();
    walletService =
        wownero.createWowneroWalletService(DB.instance.moneroWalletInfoBox);
    prefs = await SharedPreferences.getInstance();
    keysStorage = KeyService(storage!);

    await _prefs.init();
    final data =
        DB.instance.get<dynamic>(boxName: walletId, key: "latest_tx_model")
            as TransactionData?;
    if (data != null) {
      _transactionData = Future(() => data);
    }

    String? password;
    try {
      password = await keysStorage?.getWalletPassword(walletName: _walletId);
    } catch (e, s) {
      debugPrint("Exception was thrown $e $s");
      throw Exception("Password not found $e, $s");
    }
    walletBase = (await walletService?.openWallet(_walletId, password!))
        as WowneroWalletBase;
    debugPrint("walletBase $walletBase");
    Logging.instance.log(
        "Opened existing ${coin.prettyName} wallet $walletName",
        level: LogLevel.Info);
    // Wallet already exists, triggers for a returning user

    String indexKey = "receivingIndex";
    final curIndex =
        await DB.instance.get<dynamic>(boxName: walletId, key: indexKey) as int;
    // Use new index to derive a new receiving address
    final newReceivingAddress = await _generateAddressForChain(0, curIndex);
    Logging.instance.log("xmr address in init existing: $newReceivingAddress",
        level: LogLevel.Info);
    _currentReceivingAddress = Future(() => newReceivingAddress);
  }

  @override
  Future<int> get maxFee async {
    var bal = await availableBalance;
    var fee = walletBase!.calculateEstimatedFee(
            wownero.getDefaultTransactionPriority(), bal.toBigInt().toInt()) ~/
        10000;

    return fee;
  }

  @override
  // TODO: implement pendingBalance
  Future<Decimal> get pendingBalance => throw UnimplementedError();

  bool longMutex = false;

  // TODO: are these needed?
  FlutterSecureStorage? storage;
  WalletService? walletService;
  SharedPreferences? prefs;
  KeyService? keysStorage;
  WowneroWalletBase? walletBase;
  WalletCreationService? _walletCreationService;

  String toStringForinfo(WalletInfo info) {
    return "id: ${info.id}  name: ${info.name} type: ${info.type} recovery: ${info.isRecovery}"
        " restoreheight: ${info.restoreHeight} timestamp: ${info.timestamp} dirPath: ${info.dirPath} "
        "path: ${info.path} address: ${info.address} addresses: ${info.addresses}";
  }

  Future<String> pathForWalletDir({
    required String name,
    required WalletType type,
  }) async {
    Directory root = (await getApplicationDocumentsDirectory());
    if (Platform.isIOS) {
      root = (await getLibraryDirectory());
    }
    final prefix = walletTypeToString(type).toLowerCase();
    final walletsDir = Directory('${root.path}/wallets');
    final walletDire = Directory('${walletsDir.path}/$prefix/$name');

    if (!walletDire.existsSync()) {
      walletDire.createSync(recursive: true);
    }

    return walletDire.path;
  }

  Future<String> pathForWallet({
    required String name,
    required WalletType type,
  }) async =>
      await pathForWalletDir(name: name, type: type)
          .then((path) => '$path/$name');

  // TODO: take in a dynamic height
  @override
  Future<void> recoverFromMnemonic({
    required String mnemonic,
    required int maxUnusedAddressGap,
    required int maxNumberOfIndexesToCheck,
    required int height,
  }) async {
    await _prefs.init();
    longMutex = true;
    final start = DateTime.now();
    try {
      // Logging.instance.log("IS_INTEGRATION_TEST: $integrationTestFlag");
      // if (!integrationTestFlag) {
      //   final features = await electrumXClient.getServerFeatures();
      //   Logging.instance.log("features: $features");
      //   if (_networkType == BasicNetworkType.main) {
      //     if (features['genesis_hash'] != GENESIS_HASH_MAINNET) {
      //       throw Exception("genesis hash does not match main net!");
      //     }
      //   } else if (_networkType == BasicNetworkType.test) {
      //     if (features['genesis_hash'] != GENESIS_HASH_TESTNET) {
      //       throw Exception("genesis hash does not match test net!");
      //     }
      //   }
      // }
      // check to make sure we aren't overwriting a mnemonic
      // this should never fail
      if ((await _secureStore.read(key: '${_walletId}_mnemonic')) != null) {
        longMutex = false;
        throw Exception("Attempted to overwrite mnemonic on restore!");
      }
      await _secureStore.write(
          key: '${_walletId}_mnemonic', value: mnemonic.trim());

      height = getSeedHeightSync(mnemonic.trim());

      await DB.instance
          .put<dynamic>(boxName: walletId, key: "restoreHeight", value: height);

      storage = const FlutterSecureStorage();
      walletService =
          wownero.createWowneroWalletService(DB.instance.moneroWalletInfoBox);
      prefs = await SharedPreferences.getInstance();
      keysStorage = KeyService(storage!);
      WalletInfo walletInfo;
      WalletCredentials credentials;
      String name = _walletId;
      final dirPath =
          await pathForWalletDir(name: name, type: WalletType.wownero);
      final path = await pathForWallet(name: name, type: WalletType.wownero);
      credentials = wownero.createWowneroRestoreWalletFromSeedCredentials(
        name: name,
        height: height,
        mnemonic: mnemonic.trim(),
      );
      try {
        walletInfo = WalletInfo.external(
            id: WalletBase.idFor(name, WalletType.wownero),
            name: name,
            type: WalletType.wownero,
            isRecovery: false,
            restoreHeight: credentials.height ?? 0,
            date: DateTime.now(),
            path: path,
            dirPath: dirPath,
            // TODO: find out what to put for address
            address: '');
        credentials.walletInfo = walletInfo;

        _walletCreationService = WalletCreationService(
          secureStorage: storage,
          sharedPreferences: prefs,
          walletService: walletService,
          keyService: keysStorage,
        );
        _walletCreationService!.changeWalletType();
        // To restore from a seed
        final wallet =
            await _walletCreationService!.restoreFromSeed(credentials);
        walletInfo.address = wallet.walletAddresses.address;
        await DB.instance
            .add<WalletInfo>(boxName: WalletInfo.boxName, value: walletInfo);
        walletBase?.close();
        walletBase = wallet as WowneroWalletBase;
        await DB.instance.put<dynamic>(
            boxName: walletId,
            key: 'receivingAddresses',
            value: [walletInfo.address!]);
        await DB.instance
            .put<dynamic>(boxName: walletId, key: "receivingIndex", value: 0);
        await DB.instance
            .put<dynamic>(boxName: walletId, key: "id", value: _walletId);
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
      } catch (e, s) {
        debugPrint(e.toString());
        debugPrint(s.toString());
      }
      final node = await getCurrentNode();
      final host = Uri.parse(node.host).host;
      await walletBase?.connectToNode(
          node: Node(uri: "$host:${node.port}", type: WalletType.wownero));
      await walletBase?.rescan(height: credentials.height);
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
        "$walletName Recovery time: ${end.difference(start).inMilliseconds} millis",
        level: LogLevel.Info);
  }

  @override
  Future<String> send({
    required String toAddress,
    required int amount,
    Map<String, String> args = const {},
  }) async {
    try {
      final txData = await prepareSend(
          address: toAddress, satoshiAmount: amount, args: args);
      final txHash = await confirmSend(txData: txData);
      return txHash;
    } catch (e, s) {
      Logging.instance
          .log("Exception rethrown from send(): $e\n$s", level: LogLevel.Error);
      rethrow;
    }
  }

  @override
  Future<bool> testNetworkConnection() async {
    return await walletBase?.isConnected() ?? false;
  }

  Timer? _networkAliveTimer;

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

  void stopNetworkAlivePinging() {
    _networkAliveTimer?.cancel();
    _networkAliveTimer = null;
  }

  bool _isConnected = false;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<Decimal> get totalBalance async {
    var transactions = walletBase?.transactionHistory!.transactions;
    int transactionBalance = 0;
    for (var tx in transactions!.entries) {
      if (tx.value.direction == TransactionDirection.incoming) {
        transactionBalance += tx.value.amount!;
      } else {
        transactionBalance += -tx.value.amount! - tx.value.fee!;
      }
    }

    // TODO: grab total balance
    var bal = 0;
    for (var element in walletBase!.balance!.entries) {
      bal = bal + element.value.fullBalance;
    }
    debugPrint("balances: $transactionBalance $bal");
    if (isActive) {
      String am = wowneroAmountToString(amount: bal);

      return Decimal.parse(am);
    } else {
      String am = wowneroAmountToString(amount: transactionBalance);

      return Decimal.parse(am);
    }
  }

  @override
  // TODO: implement onIsActiveWalletChanged
  void Function(bool)? get onIsActiveWalletChanged => (isActive) async {
        await walletBase?.save();
        walletBase?.close();
        wowneroAutosaveTimer?.cancel();
        wowneroAutosaveTimer = null;
        timer?.cancel();
        timer = null;
        await stopSyncPercentTimer();
        if (isActive) {
          String? password;
          try {
            password =
                await keysStorage?.getWalletPassword(walletName: _walletId);
          } catch (e, s) {
            debugPrint("Exception was thrown $e $s");
            throw Exception("Password not found $e, $s");
          }
          walletBase = (await walletService?.openWallet(_walletId, password!))
              as WowneroWalletBase?;
          if (!(await walletBase!.isConnected())) {
            final node = await getCurrentNode();
            final host = Uri.parse(node.host).host;
            await walletBase?.connectToNode(
                node:
                    Node(uri: "$host:${node.port}", type: WalletType.wownero));
            await walletBase?.startSync();
          }
          await refresh();
        }
        this.isActive = isActive;
      };

  bool isActive = false;

  @override
  Future<TransactionData> get transactionData =>
      _transactionData ??= _fetchTransactionData();
  Future<TransactionData>? _transactionData;

  Future<TransactionData> _fetchTransactionData() async {
    final transactions = walletBase?.transactionHistory!.transactions;

    final cachedTransactions =
        DB.instance.get<dynamic>(boxName: walletId, key: 'latest_tx_model')
            as TransactionData?;
    int latestTxnBlockHeight =
        DB.instance.get<dynamic>(boxName: walletId, key: "storedTxnDataHeight")
                as int? ??
            0;

    final txidsList = DB.instance
            .get<dynamic>(boxName: walletId, key: "cachedTxids") as List? ??
        [];

    final Set<String> cachedTxids = Set<String>.from(txidsList);

    // TODO: filter to skip cached + confirmed txn processing in next step
    // final unconfirmedCachedTransactions =
    //     cachedTransactions?.getAllTransactions() ?? {};
    // unconfirmedCachedTransactions
    //     .removeWhere((key, value) => value.confirmedStatus);
    //
    // if (cachedTransactions != null) {
    //   for (final tx in allTxHashes.toList(growable: false)) {
    //     final txHeight = tx["height"] as int;
    //     if (txHeight > 0 &&
    //         txHeight < latestTxnBlockHeight - MINIMUM_CONFIRMATIONS) {
    //       if (unconfirmedCachedTransactions[tx["tx_hash"] as String] == null) {
    //         allTxHashes.remove(tx);
    //       }
    //     }
    //   }
    // }

    // sort thing stuff
    // change to get Wownero price
    final priceData =
        await _priceAPI.getPricesAnd24hChange(baseCurrency: _prefs.currency);
    Decimal currentPrice = priceData[coin]?.item1 ?? Decimal.zero;
    final List<Map<String, dynamic>> midSortedArray = [];

    if (transactions != null) {
      for (var tx in transactions.entries) {
        cachedTxids.add(tx.value.id);
        Logging.instance.log(
            "${tx.value.accountIndex} ${tx.value.addressIndex} ${tx.value.amount} ${tx.value.date} "
            "${tx.value.direction} ${tx.value.fee} ${tx.value.height} ${tx.value.id} ${tx.value.isPending} ${tx.value.key} "
            "${tx.value.recipientAddress}, ${tx.value.additionalInfo} con:${tx.value.confirmations}"
            " ${tx.value.keyIndex}",
            level: LogLevel.Info);
        String am = wowneroAmountToString(amount: tx.value.amount!);
        final worthNow = (currentPrice * Decimal.parse(am)).toStringAsFixed(2);
        Map<String, dynamic> midSortedTx = {};
        // // create final tx map
        midSortedTx["txid"] = tx.value.id;
        midSortedTx["confirmed_status"] = !tx.value.isPending &&
            tx.value.confirmations! >= MINIMUM_CONFIRMATIONS;
        midSortedTx["confirmations"] = tx.value.confirmations ?? 0;
        midSortedTx["timestamp"] =
            (tx.value.date.millisecondsSinceEpoch ~/ 1000);
        midSortedTx["txType"] =
            tx.value.direction == TransactionDirection.incoming
                ? "Received"
                : "Sent";
        midSortedTx["amount"] = tx.value.amount;
        midSortedTx["worthNow"] = worthNow;
        midSortedTx["worthAtBlockTimestamp"] = worthNow;
        midSortedTx["fees"] = tx.value.fee;
        // TODO: shouldn't wownero have an address I can grab
        if (tx.value.direction == TransactionDirection.incoming) {
          final addressInfo = tx.value.additionalInfo;

          midSortedTx["address"] = walletBase?.getTransactionAddress(
            addressInfo!['accountIndex'] as int,
            addressInfo['addressIndex'] as int,
          );
        } else {
          midSortedTx["address"] = "";
        }

        final int txHeight = tx.value.height ?? 0;
        midSortedTx["height"] = txHeight;
        if (txHeight >= latestTxnBlockHeight) {
          latestTxnBlockHeight = txHeight;
        }

        midSortedTx["aliens"] = <dynamic>[];
        midSortedTx["inputSize"] = 0;
        midSortedTx["outputSize"] = 0;
        midSortedTx["inputs"] = <dynamic>[];
        midSortedTx["outputs"] = <dynamic>[];
        midSortedArray.add(midSortedTx);
      }
    }

    // sort by date  ----
    midSortedArray
        .sort((a, b) => (b["timestamp"] as int) - (a["timestamp"] as int));
    Logging.instance.log(midSortedArray, level: LogLevel.Info);

    // buildDateTimeChunks
    final Map<String, dynamic> result = {"dateTimeChunks": <dynamic>[]};
    final dateArray = <dynamic>[];

    for (int i = 0; i < midSortedArray.length; i++) {
      final txObject = midSortedArray[i];
      final date = extractDateFromTimestamp(txObject["timestamp"] as int);
      final txTimeArray = [txObject["timestamp"], date];

      if (dateArray.contains(txTimeArray[1])) {
        result["dateTimeChunks"].forEach((dynamic chunk) {
          if (extractDateFromTimestamp(chunk["timestamp"] as int) ==
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
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'cachedTxids',
        value: cachedTxids.toList(growable: false));

    return txModel;
  }

  @override
  // TODO: implement unspentOutputs
  Future<List<UtxoObject>> get unspentOutputs => throw UnimplementedError();

  @override
  // TODO: implement validateAddress
  bool validateAddress(String address) {
    bool valid = RegExp("[a-zA-Z0-9]{95}").hasMatch(address) ||
        RegExp("[a-zA-Z0-9]{106}").hasMatch(address);
    return valid;
  }

  @override
  String get walletId => _walletId;
  late String _walletId;

  @override
  String get walletName => _walletName;
  late String _walletName;

  // setter for updating on rename
  @override
  set walletName(String newName) => _walletName = newName;

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
      Logging.instance
          .log("isFavorite fetch failed: $e\n$s", level: LogLevel.Error);
      rethrow;
    }
  }

  @override
  // TODO: implement availableBalance
  Future<Decimal> get availableBalance async {
    var bal = 0;
    for (var element in walletBase!.balance!.entries) {
      bal = bal + element.value.unlockedBalance;
    }
    String am = wowneroAmountToString(amount: bal);

    return Decimal.parse(am);
  }

  @override
  Coin get coin => _coin;

  @override
  Future<String> confirmSend({required Map<String, dynamic> txData}) async {
    try {
      Logging.instance.log("confirmSend txData: $txData", level: LogLevel.Info);
      final pendingWowneroTransaction =
          txData['pendingWowneroTransaction'] as PendingWowneroTransaction;
      try {
        await pendingWowneroTransaction.commit();
        Logging.instance.log(
            "transaction ${pendingWowneroTransaction.id} has been sent",
            level: LogLevel.Info);
        return pendingWowneroTransaction.id;
      } catch (e, s) {
        Logging.instance.log("$walletName wownero confirmSend: $e\n$s",
            level: LogLevel.Error);
        rethrow;
      }
    } catch (e, s) {
      Logging.instance.log("Exception rethrown from confirmSend(): $e\n$s",
          level: LogLevel.Info);
      rethrow;
    }
  }

  // TODO: fix the double free memory crash error.
  @override
  Future<Map<String, dynamic>> prepareSend(
      {required String address,
      required int satoshiAmount,
      Map<String, dynamic>? args}) async {
    int amount = satoshiAmount;
    String toAddress = address;
    try {
      final feeRate = args?["feeRate"];
      if (feeRate is FeeRateType) {
        MoneroTransactionPriority feePriority = MoneroTransactionPriority.slow;
        switch (feeRate) {
          case FeeRateType.fast:
            feePriority = MoneroTransactionPriority.fastest;
            break;
          case FeeRateType.average:
            feePriority = MoneroTransactionPriority.medium;
            break;
          case FeeRateType.slow:
            feePriority = MoneroTransactionPriority.slow;
            break;
        }

        Future<PendingTransaction>? awaitPendingTransaction;
        try {
          Logging.instance
              .log("$toAddress $amount $args", level: LogLevel.Info);
          String amountToSend = wowneroAmountToString(amount: amount * 10000);
          Logging.instance.log("$amount $amountToSend", level: LogLevel.Info);

          wownero_output.Output output = wownero_output.Output(walletBase!);
          output.address = toAddress;
          output.setCryptoAmount(amountToSend);

          List<wownero_output.Output> outputs = [output];
          Object tmp = wownero.createWowneroTransactionCreationCredentials(
              outputs: outputs, priority: feePriority);

          awaitPendingTransaction = walletBase!.createTransaction(tmp);
        } catch (e, s) {
          Logging.instance.log("Exception rethrown from prepareSend(): $e\n$s",
              level: LogLevel.Warning);
        }

        PendingWowneroTransaction pendingWowneroTransaction =
            await (awaitPendingTransaction!) as PendingWowneroTransaction;
        int realfee = (Decimal.parse(pendingWowneroTransaction.feeFormatted) *
                100000000.toDecimal())
            .toBigInt()
            .toInt();
        debugPrint("fee? $realfee");
        Map<String, dynamic> txData = {
          "pendingWowneroTransaction": pendingWowneroTransaction,
          "fee": realfee,
          "addresss": toAddress,
          "recipientAmt": satoshiAmount,
        };

        Logging.instance.log("prepare send: $txData", level: LogLevel.Info);
        return txData;
      } else {
        throw ArgumentError("Invalid fee rate argument provided!");
      }
    } catch (e, s) {
      Logging.instance.log("Exception rethrown from prepare send(): $e\n$s",
          level: LogLevel.Info);

      if (e.toString().contains("Incorrect unlocked balance")) {
        throw Exception("Insufficient balance!");
      } else if (e is CreationTransactionException) {
        throw Exception("Insufficient funds to pay for transaction fee!");
      } else {
        throw Exception("Transaction failed with error code $e");
      }
    }
  }

  @override
  Future<int> estimateFeeFor(int satoshiAmount, int feeRate) async {
    MoneroTransactionPriority? priority;
    switch (feeRate) {
      case 1:
        priority = MoneroTransactionPriority.regular;
        break;
      case 2:
        priority = MoneroTransactionPriority.medium;
        break;
      case 3:
        priority = MoneroTransactionPriority.fast;
        break;
      case 4:
        priority = MoneroTransactionPriority.fastest;
        break;
      case 0:
      default:
        priority = MoneroTransactionPriority.slow;
        break;
    }
    final fee =
        (walletBase?.calculateEstimatedFee(priority, satoshiAmount) ?? 0) ~/
            10000;
    return fee;
  }

  @override
  Future<bool> generateNewAddress() async {
    try {
      const String indexKey = "receivingIndex";
      // First increment the receiving index
      await _incrementAddressIndexForChain(0);
      final newReceivingIndex =
          DB.instance.get<dynamic>(boxName: walletId, key: indexKey) as int;

      // Use new index to derive a new receiving address
      final newReceivingAddress =
          await _generateAddressForChain(0, newReceivingIndex);

      // Add that new receiving address to the array of receiving addresses
      await _addToAddressesArrayForChain(newReceivingAddress, 0);

      // Set the new receiving address that the service

      _currentReceivingAddress = Future(() => newReceivingAddress);

      return true;
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown from generateNewAddress(): $e\n$s",
          level: LogLevel.Error);
      return false;
    }
  }
}
