import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/hive/db.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/transaction_notification_tracker.dart';
import 'package:stackwallet/services/wallets_service.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/sync_type_enum.dart';
import 'package:stackwallet/utilities/listenable_list.dart';
import 'package:stackwallet/utilities/listenable_map.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:tuple/tuple.dart';

final ListenableList<ChangeNotifierProvider<Manager>> _nonFavorites =
    ListenableList();
ListenableList<ChangeNotifierProvider<Manager>> get nonFavorites =>
    _nonFavorites;

final ListenableList<ChangeNotifierProvider<Manager>> _favorites =
    ListenableList();
ListenableList<ChangeNotifierProvider<Manager>> get favorites => _favorites;

class Wallets extends ChangeNotifier {
  Wallets._private();

  @override
  dispose() {
    debugPrint("Wallets dispose was called!!");
    super.dispose();
  }

  static final Wallets _sharedInstance = Wallets._private();
  static Wallets get sharedInstance => _sharedInstance;

  late WalletsService walletsService;
  late NodeService nodeService;

  // mirrored maps for access to reading managers without using riverpod ref
  static final ListenableMap<String, ChangeNotifierProvider<Manager>>
      _managerProviderMap = ListenableMap();
  static final ListenableMap<String, Manager> _managerMap = ListenableMap();

  bool get hasWallets => _managerProviderMap.isNotEmpty;

  List<ChangeNotifierProvider<Manager>> get managerProviders =>
      _managerProviderMap.values.toList(growable: false);
  List<Manager> get managers => _managerMap.values.toList(growable: false);

  List<String> getWalletIdsFor({required Coin coin}) {
    final List<String> result = [];
    for (final manager in _managerMap.values) {
      if (manager.coin == coin) {
        result.add(manager.walletId);
      }
    }
    return result;
  }

  Map<Coin, List<ChangeNotifierProvider<Manager>>> getManagerProvidersByCoin() {
    Map<Coin, List<ChangeNotifierProvider<Manager>>> result = {};
    for (final manager in _managerMap.values) {
      if (result[manager.coin] == null) {
        result[manager.coin] = [];
      }
      result[manager.coin]!.add(_managerProviderMap[manager.walletId]
          as ChangeNotifierProvider<Manager>);
    }
    return result;
  }

  ChangeNotifierProvider<Manager> getManagerProvider(String walletId) {
    return _managerProviderMap[walletId] as ChangeNotifierProvider<Manager>;
  }

  Manager getManager(String walletId) {
    return _managerMap[walletId] as Manager;
  }

  void addWallet({required String walletId, required Manager manager}) {
    _managerMap.add(walletId, manager, true);
    _managerProviderMap.add(
        walletId, ChangeNotifierProvider<Manager>((_) => manager), true);

    if (manager.isFavorite) {
      _favorites.add(
          _managerProviderMap[walletId] as ChangeNotifierProvider<Manager>,
          false);
    } else {
      _nonFavorites.add(
          _managerProviderMap[walletId] as ChangeNotifierProvider<Manager>,
          false);
    }

    notifyListeners();
  }

  void removeWallet({required String walletId}) {
    if (_managerProviderMap[walletId] == null) {
      Logging.instance.log(
          "Wallets.removeWallet($walletId) failed. ManagerProvider with $walletId not found!",
          level: LogLevel.Warning);
      return;
    }

    final provider = _managerProviderMap[walletId]!;

    // in both non and favorites for removal
    _favorites.remove(provider, true);
    _nonFavorites.remove(provider, true);

    _managerProviderMap.remove(walletId, true);
    _managerMap.remove(walletId, true)!.exitCurrentWallet();

    notifyListeners();
  }

  static bool hasLoaded = false;

  Future<void> _initLinearly(
    List<Tuple2<Manager, bool>> tuples,
  ) async {
    for (final tuple in tuples) {
      await tuple.item1.initializeExisting();
      if (tuple.item2 && !tuple.item1.shouldAutoSync) {
        tuple.item1.shouldAutoSync = true;
      }
    }
  }

  static int _count = 0;
  Future<void> load(Prefs prefs) async {
    debugPrint("++++++++++++++ Wallets().load() called: ${++_count} times");
    if (hasLoaded) {
      return;
    }
    hasLoaded = true;

    // clear out any wallet hive boxes where the wallet was deleted in previous app run
    for (final walletId in DB.instance
        .values<String>(boxName: DB.boxNameWalletsToDeleteOnStart)) {
      await DB.instance.deleteBoxFromDisk(boxName: walletId);
    }
    // clear list
    await DB.instance
        .deleteAll<String>(boxName: DB.boxNameWalletsToDeleteOnStart);

    final map = await walletsService.walletNames;

    List<Future<dynamic>> walletInitFutures = [];
    List<Tuple2<Manager, bool>> walletsToInitLinearly = [];

    final favIdList = await walletsService.getFavoriteWalletIds();

    List<String> walletIdsToEnableAutoSync = [];
    bool shouldAutoSyncAll = false;
    switch (prefs.syncType) {
      case SyncingType.currentWalletOnly:
        // do nothing as this will be set when going into a wallet from the main screen
        break;
      case SyncingType.selectedWalletsAtStartup:
        walletIdsToEnableAutoSync.addAll(prefs.walletIdsSyncOnStartup);
        break;
      case SyncingType.allWalletsOnStartup:
        shouldAutoSyncAll = true;
        break;
    }

    for (final entry in map.entries) {
      try {
        final walletId = entry.value.walletId;

        late final bool isVerified;
        try {
          isVerified =
              await walletsService.isMnemonicVerified(walletId: walletId);
        } catch (e, s) {
          Logging.instance.log("$e $s", level: LogLevel.Warning);
          isVerified = false;
        }

        Logging.instance.log(
            "LOADING WALLET: ${entry.value.toString()} IS VERIFIED: $isVerified",
            level: LogLevel.Info);
        if (isVerified) {
          if (_managerMap[walletId] == null &&
              _managerProviderMap[walletId] == null) {
            final coin = entry.value.coin;
            NodeModel node = nodeService.getPrimaryNodeFor(coin: coin) ??
                DefaultNodes.getNodeFor(coin);
            // ElectrumXNode? node = await nodeService.getCurrentNode(coin: coin);

            // folowing shouldn't be needed as the defaults get saved on init
            // if (node == null) {
            //   node = DefaultNodes.getNodeFor(coin);
            //
            //   // save default node
            //   nodeService.add(node, false);
            // }

            final txTracker =
                TransactionNotificationTracker(walletId: walletId);

            final failovers = NodeService().failoverNodesFor(coin: coin);

            // load wallet
            final wallet = CoinServiceAPI.from(
              coin,
              walletId,
              entry.value.name,
              node,
              txTracker,
              prefs,
              failovers,
            );

            final manager = Manager(wallet);

            final shouldSetAutoSync = shouldAutoSyncAll ||
                walletIdsToEnableAutoSync.contains(manager.walletId);

            if (manager.coin == Coin.monero) {
              walletsToInitLinearly.add(Tuple2(manager, shouldSetAutoSync));
            } else {
              walletInitFutures.add(manager.initializeExisting().then((value) {
                if (shouldSetAutoSync) {
                  manager.shouldAutoSync = true;
                }
              }));
            }

            _managerMap.add(walletId, manager, false);

            final managerProvider =
                ChangeNotifierProvider<Manager>((_) => manager);
            _managerProviderMap.add(walletId, managerProvider, false);

            final favIndex = favIdList.indexOf(walletId);

            if (favIndex == -1) {
              _nonFavorites.add(managerProvider, true);
            } else {
              // it is a favorite
              if (favIndex >= _favorites.length) {
                _favorites.add(managerProvider, true);
              } else {
                _favorites.insert(favIndex, managerProvider, true);
              }
            }
          }
        } else {
          // wallet creation was not completed by user so we remove it completely
          await walletsService.deleteWallet(entry.value.name, false);
        }
      } catch (e, s) {
        Logging.instance.log("$e $s", level: LogLevel.Fatal);
        continue;
      }
    }

    if (walletInitFutures.isNotEmpty && walletsToInitLinearly.isNotEmpty) {
      await Future.wait([
        _initLinearly(walletsToInitLinearly),
        ...walletInitFutures,
      ]);
      notifyListeners();
    } else if (walletInitFutures.isNotEmpty) {
      await Future.wait(walletInitFutures);
      notifyListeners();
    } else if (walletsToInitLinearly.isNotEmpty) {
      await _initLinearly(walletsToInitLinearly);
      notifyListeners();
    }
  }

  Future<void> loadAfterStackRestore(
      Prefs prefs, List<Manager> managers) async {
    List<Future<dynamic>> walletInitFutures = [];
    List<Tuple2<Manager, bool>> walletsToInitLinearly = [];

    final favIdList = await walletsService.getFavoriteWalletIds();

    List<String> walletIdsToEnableAutoSync = [];
    bool shouldAutoSyncAll = false;
    switch (prefs.syncType) {
      case SyncingType.currentWalletOnly:
        // do nothing as this will be set when going into a wallet from the main screen
        break;
      case SyncingType.selectedWalletsAtStartup:
        walletIdsToEnableAutoSync.addAll(prefs.walletIdsSyncOnStartup);
        break;
      case SyncingType.allWalletsOnStartup:
        shouldAutoSyncAll = true;
        break;
    }

    for (final manager in managers) {
      final walletId = manager.walletId;

      final isVerified =
          await walletsService.isMnemonicVerified(walletId: walletId);
      debugPrint(
          "LOADING RESTORED WALLET: ${manager.walletName} ${manager.walletId} IS VERIFIED: $isVerified");

      if (isVerified) {
        if (_managerMap[walletId] == null &&
            _managerProviderMap[walletId] == null) {
          final shouldSetAutoSync = shouldAutoSyncAll ||
              walletIdsToEnableAutoSync.contains(manager.walletId);

          if (manager.coin == Coin.monero) {
            walletsToInitLinearly.add(Tuple2(manager, shouldSetAutoSync));
          } else {
            walletInitFutures.add(manager.initializeExisting().then((value) {
              if (shouldSetAutoSync) {
                manager.shouldAutoSync = true;
              }
            }));
          }

          _managerMap.add(walletId, manager, false);

          final managerProvider =
              ChangeNotifierProvider<Manager>((_) => manager);
          _managerProviderMap.add(walletId, managerProvider, false);

          final favIndex = favIdList.indexOf(walletId);

          if (favIndex == -1) {
            _nonFavorites.add(managerProvider, true);
          } else {
            // it is a favorite
            if (favIndex >= _favorites.length) {
              _favorites.add(managerProvider, true);
            } else {
              _favorites.insert(favIndex, managerProvider, true);
            }
          }
        }
      } else {
        // wallet creation was not completed by user so we remove it completely
        await walletsService.deleteWallet(manager.walletName, false);
      }
    }

    if (walletInitFutures.isNotEmpty && walletsToInitLinearly.isNotEmpty) {
      await Future.wait([
        _initLinearly(walletsToInitLinearly),
        ...walletInitFutures,
      ]);
      notifyListeners();
    } else if (walletInitFutures.isNotEmpty) {
      await Future.wait(walletInitFutures);
      notifyListeners();
    } else if (walletsToInitLinearly.isNotEmpty) {
      await _initLinearly(walletsToInitLinearly);
      notifyListeners();
    }
  }
}
