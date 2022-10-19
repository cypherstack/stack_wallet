import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_libmonero/monero/monero.dart';
import 'package:flutter_libmonero/wownero/wownero.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stackwallet/hive/db.dart';
import 'package:stackwallet/services/coins/epiccash/epiccash_wallet.dart';
import 'package:stackwallet/services/notifications_service.dart';
import 'package:stackwallet/services/trade_sent_from_stack_service.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:uuid/uuid.dart';

class WalletInfo {
  final Coin coin;
  final String walletId;
  final String name;

  const WalletInfo(
      {required this.coin, required this.walletId, required this.name});

  factory WalletInfo.fromJson(Map<String, dynamic> jsonObject) {
    return WalletInfo(
      coin: Coin.values.byName(jsonObject["coin"] as String),
      walletId: jsonObject["id"] as String,
      name: jsonObject["name"] as String,
    );
  }

  Map<String, String> toMap() {
    return {
      "name": name,
      "id": walletId,
      "coin": coin.name,
    };
  }

  String toJsonString() {
    return jsonEncode(toMap());
  }

  @override
  String toString() {
    return "WalletInfo: ${toJsonString()}";
  }
}

class WalletsService extends ChangeNotifier {
  late final FlutterSecureStorageInterface _secureStore;

  Future<Map<String, WalletInfo>>? _walletNames;
  Future<Map<String, WalletInfo>> get walletNames =>
      _walletNames ??= _fetchWalletNames();

  WalletsService({
    FlutterSecureStorageInterface secureStorageInterface =
        const SecureStorageWrapper(
      FlutterSecureStorage(),
    ),
  }) {
    _secureStore = secureStorageInterface;
  }

  // Future<Coin> getWalletCryptoCurrency({required String walletName}) async {
  //   final id = await getWalletId(walletName);
  //   final currency = DB.instance.get<dynamic>(
  //       boxName: DB.boxNameAllWalletsData, key: "${id}_cryptoCurrency");
  //   return Coin.values.byName(currency as String);
  // }

  Future<bool> renameWallet({
    required String from,
    required String to,
    required bool shouldNotifyListeners,
  }) async {
    if (from == to) {
      return true;
    }

    final walletInfo = DB.instance
        .get<dynamic>(boxName: DB.boxNameAllWalletsData, key: 'names') as Map;

    final info = walletInfo.values.firstWhere(
        (element) => element['name'] == from,
        orElse: () => <String, String>{}) as Map;

    if (info.isEmpty) {
      // tried to rename a non existing wallet
      Logging.instance
          .log("Tried to rename a non existing wallet!", level: LogLevel.Error);
      return false;
    }

    if (from != to &&
        (walletInfo.values.firstWhere((element) => element['name'] == to,
                orElse: () => <String, String>{}) as Map)
            .isNotEmpty) {
      // name already exists
      Logging.instance.log("wallet with name \"$to\" already exists!",
          level: LogLevel.Error);
      return false;
    }

    info["name"] = to;
    walletInfo[info['id']] = info;

    await DB.instance.put<dynamic>(
        boxName: DB.boxNameAllWalletsData, key: 'names', value: walletInfo);
    await refreshWallets(shouldNotifyListeners);
    return true;
  }

  Future<Map<String, WalletInfo>> _fetchWalletNames() async {
    final names = DB.instance
        .get<dynamic>(boxName: DB.boxNameAllWalletsData, key: 'names') as Map?;
    if (names == null) {
      Logging.instance.log(
          "Fetched wallet 'names' returned null. Setting initializing 'names'",
          level: LogLevel.Info);
      await DB.instance.put<dynamic>(
          boxName: DB.boxNameAllWalletsData,
          key: 'names',
          value: <String, dynamic>{});
      return {};
    }
    Logging.instance.log("Fetched wallet names: $names", level: LogLevel.Info);
    final mapped = Map<String, dynamic>.from(names);
    mapped.removeWhere((name, dyn) {
      final jsonObject = Map<String, dynamic>.from(dyn as Map);
      try {
        Coin.values.byName(jsonObject["coin"] as String);
        return false;
      } catch (e, s) {
        Logging.instance.log("Error, ${jsonObject["coin"]} does not exist",
            level: LogLevel.Error);
        return true;
      }
    });

    return mapped.map((name, dyn) => MapEntry(
        name, WalletInfo.fromJson(Map<String, dynamic>.from(dyn as Map))));
  }

  Future<void> addExistingStackWallet({
    required String name,
    required String walletId,
    required Coin coin,
    required bool shouldNotifyListeners,
  }) async {
    final _names = DB.instance
        .get<dynamic>(boxName: DB.boxNameAllWalletsData, key: 'names') as Map?;

    Map<String, dynamic> names;
    if (_names == null) {
      names = {};
    } else {
      names = Map<String, dynamic>.from(_names);
    }

    if (names.keys.contains(walletId)) {
      throw Exception("Wallet with walletId \"$walletId\" already exists!");
    }
    if (names.values.where((element) => element['name'] == name).isNotEmpty) {
      throw Exception("Wallet with name \"$name\" already exists!");
    }

    names[walletId] = {
      "id": walletId,
      "coin": coin.name,
      "name": name,
    };

    await DB.instance.put<dynamic>(
        boxName: DB.boxNameAllWalletsData, key: 'names', value: names);
    await DB.instance.put<dynamic>(
        boxName: DB.boxNameAllWalletsData,
        key: "${walletId}_cryptoCurrency",
        value: coin.name);
    await DB.instance.put<dynamic>(
        boxName: DB.boxNameAllWalletsData,
        key: "${walletId}_mnemonicHasBeenVerified",
        value: false);
    await DB.instance.addWalletBox(walletId: walletId);
    await refreshWallets(shouldNotifyListeners);
  }

  /// returns the new walletId if successful, otherwise null
  Future<String?> addNewWallet({
    required String name,
    required Coin coin,
    required bool shouldNotifyListeners,
  }) async {
    final _names = DB.instance
        .get<dynamic>(boxName: DB.boxNameAllWalletsData, key: 'names') as Map?;

    Map<String, dynamic> names;
    if (_names == null) {
      names = {};
    } else {
      names = Map<String, dynamic>.from(_names);
    }

    // Prevent overwriting or storing empty names
    if (name.isEmpty ||
        names.values.where((element) => element['name'] == name).isNotEmpty) {
      return null;
    }

    final id = const Uuid().v1();
    names[id] = {
      "id": id,
      "coin": coin.name,
      "name": name,
    };

    await DB.instance.put<dynamic>(
        boxName: DB.boxNameAllWalletsData, key: 'names', value: names);
    await DB.instance.put<dynamic>(
        boxName: DB.boxNameAllWalletsData,
        key: "${id}_cryptoCurrency",
        value: coin.name);
    await DB.instance.put<dynamic>(
        boxName: DB.boxNameAllWalletsData,
        key: "${id}_mnemonicHasBeenVerified",
        value: false);
    await DB.instance.addWalletBox(walletId: id);
    await refreshWallets(shouldNotifyListeners);
    return id;
  }

  Future<List<String>> getFavoriteWalletIds() async {
    return DB.instance
        .values<String>(boxName: DB.boxNameFavoriteWallets)
        .toList();
  }

  Future<void> saveFavoriteWalletIds(List<String> walletIds) async {
    await DB.instance.deleteAll<String>(boxName: DB.boxNameFavoriteWallets);
    await DB.instance
        .addAll(boxName: DB.boxNameFavoriteWallets, values: walletIds);
    debugPrint("saveFavoriteWalletIds list: $walletIds");
  }

  Future<void> addFavorite(String walletId) async {
    final list = await getFavoriteWalletIds();
    if (!list.contains(walletId)) {
      list.add(walletId);
    }
    await saveFavoriteWalletIds(list);
  }

  Future<void> removeFavorite(String walletId) async {
    final list = await getFavoriteWalletIds();
    list.remove(walletId);
    await saveFavoriteWalletIds(list);
  }

  Future<void> moveFavorite({
    required int fromIndex,
    required int toIndex,
  }) async {
    final list = await getFavoriteWalletIds();
    if (fromIndex < toIndex) {
      toIndex -= 1;
    }
    final walletId = list.removeAt(fromIndex);
    list.insert(toIndex, walletId);
    await saveFavoriteWalletIds(list);
  }

  Future<bool> checkForDuplicate(String name) async {
    final names = DB.instance
        .get<dynamic>(boxName: DB.boxNameAllWalletsData, key: 'names') as Map?;
    if (names == null) return false;

    return names.values.where((element) => element['name'] == name).isNotEmpty;
  }

  Future<String?> getWalletId(String walletName) async {
    final names = DB.instance
        .get<dynamic>(boxName: DB.boxNameAllWalletsData, key: 'names') as Map;
    final shells =
        names.values.where((element) => element['name'] == walletName);
    if (shells.isEmpty) {
      return null;
    }
    return shells.first["id"] as String;
  }

  Future<bool> isMnemonicVerified({required String walletId}) async {
    final isVerified = DB.instance.get<dynamic>(
        boxName: DB.boxNameAllWalletsData,
        key: "${walletId}_mnemonicHasBeenVerified") as bool?;

    if (isVerified == null) {
      Logging.instance.log(
        "isMnemonicVerified(walletId: $walletId) returned null which should never happen!",
        level: LogLevel.Error,
      );
      throw Exception(
          "isMnemonicVerified(walletId: $walletId) returned null which should never happen!");
    } else {
      return isVerified;
    }
  }

  Future<void> setMnemonicVerified({required String walletId}) async {
    final isVerified = DB.instance.get<dynamic>(
        boxName: DB.boxNameAllWalletsData,
        key: "${walletId}_mnemonicHasBeenVerified") as bool?;

    if (isVerified == null) {
      Logging.instance.log(
        "setMnemonicVerified(walletId: $walletId) tried running on non existent wallet!",
        level: LogLevel.Error,
      );
      throw Exception(
          "setMnemonicVerified(walletId: $walletId) tried running on non existent wallet!");
    } else if (isVerified) {
      Logging.instance.log(
        "setMnemonicVerified(walletId: $walletId) tried running on already verified wallet!",
        level: LogLevel.Error,
      );
      throw Exception(
          "setMnemonicVerified(walletId: $walletId) tried running on already verified wallet!");
    } else {
      await DB.instance.put<dynamic>(
          boxName: DB.boxNameAllWalletsData,
          key: "${walletId}_mnemonicHasBeenVerified",
          value: true);
      Logging.instance.log(
        "setMnemonicVerified(walletId: $walletId) successful",
        level: LogLevel.Error,
      );
    }
  }

  // pin + mnemonic as well as anything else in secureStore
  Future<int> deleteWallet(String name, bool shouldNotifyListeners) async {
    final names = DB.instance.get<dynamic>(
            boxName: DB.boxNameAllWalletsData, key: 'names') as Map? ??
        {};

    final walletId = await getWalletId(name);
    if (walletId == null) {
      return 3;
    }

    Logging.instance.log(
      "deleteWallet called with name=$name and id=$walletId",
      level: LogLevel.Warning,
    );

    final shell = names.remove(walletId);

    if (shell == null) {
      return 0;
    }

    // TODO delete derivations!!!
    await _secureStore.delete(key: "${walletId}_pin");
    await _secureStore.delete(key: "${walletId}_mnemonic");

    await DB.instance.delete<dynamic>(
        boxName: DB.boxNameAllWalletsData, key: "${walletId}_cryptoCurrency");
    await DB.instance.delete<dynamic>(
        boxName: DB.boxNameAllWalletsData,
        key: "${walletId}_mnemonicHasBeenVerified");
    if (coinFromPrettyName(shell['coin'] as String) == Coin.wownero) {
      final wowService =
          wownero.createWowneroWalletService(DB.instance.moneroWalletInfoBox);
      await wowService.remove(walletId);
      Logging.instance
          .log("monero wallet: $walletId deleted", level: LogLevel.Info);
    } else if (coinFromPrettyName(shell['coin'] as String) == Coin.monero ||
        coinFromPrettyName(shell['coin'] as String) == Coin.moneroTestNet ||
        coinFromPrettyName(shell['coin'] as String) == Coin.moneroStageNet) {
      final xmrService =
          monero.createMoneroWalletService(DB.instance.moneroWalletInfoBox);
      await xmrService.remove(walletId);
      Logging.instance
          .log("monero wallet: $walletId deleted", level: LogLevel.Info);
    } else if (coinFromPrettyName(shell['coin'] as String) == Coin.epicCash) {
      final deleteResult =
          await deleteEpicWallet(walletId: walletId, secureStore: _secureStore);
      Logging.instance.log(
          "epic wallet: $walletId deleted with result: $deleteResult",
          level: LogLevel.Info);
    }

    // box data may currently still be read/written to if wallet was refreshing
    // when delete was requested so instead of deleting now we mark the wallet
    // as needs delete by adding it's id to a list which gets checked on app start
    await DB.instance.add<String>(
        boxName: DB.boxNameWalletsToDeleteOnStart, value: walletId);

    final lookupService = TradeSentFromStackService();
    for (final lookup in lookupService.all) {
      if (lookup.walletIds.contains(walletId)) {
        // update lookup data to reflect deleted wallet
        await lookupService.save(
          tradeWalletLookup: lookup.copyWith(
            walletIds: lookup.walletIds.where((id) => id != walletId).toList(),
          ),
        );
      }
    }

    // delete notifications tied to deleted wallet
    for (final notification in NotificationsService.instance.notifications) {
      if (notification.walletId == walletId) {
        await NotificationsService.instance.delete(notification, false);
      }
    }

    if (names.isEmpty) {
      await DB.instance.deleteAll<dynamic>(boxName: DB.boxNameAllWalletsData);
      _walletNames = Future(() => {});
      notifyListeners();
      return 2; // error code no wallets on device
    }

    await DB.instance.put<dynamic>(
        boxName: DB.boxNameAllWalletsData, key: 'names', value: names);
    await refreshWallets(shouldNotifyListeners);
    return 0;
  }

  Future<void> refreshWallets(bool shouldNotifyListeners) async {
    final newNames = await _fetchWalletNames();
    _walletNames = Future(() => newNames);
    if (shouldNotifyListeners) notifyListeners();
  }
}
