import 'dart:convert';

import 'package:stackwallet/electrumx_rpc/electrumx.dart';
import 'package:stackwallet/hive/db.dart';
import 'package:stackwallet/services/coins/firo/firo_wallet.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:string_validator/string_validator.dart';

class CachedElectrumX {
  final ElectrumX? electrumXClient;

  final String server;
  final int port;
  final bool useSSL;

  final Prefs prefs;
  final List<ElectrumXNode> failovers;

  static const minCacheConfirms = 30;

  const CachedElectrumX({
    required this.server,
    required this.port,
    required this.useSSL,
    required this.prefs,
    required this.failovers,
    this.electrumXClient,
  });

  factory CachedElectrumX.from({
    required ElectrumXNode node,
    required Prefs prefs,
    required List<ElectrumXNode> failovers,
    ElectrumX? electrumXClient,
  }) =>
      CachedElectrumX(
          server: node.address,
          port: node.port,
          useSSL: node.useSSL,
          prefs: prefs,
          failovers: failovers,
          electrumXClient: electrumXClient);

  Future<Map<String, dynamic>> getAnonymitySet({
    required String groupId,
    String blockhash = "",
    required Coin coin,
  }) async {
    try {
      final cachedSet = DB.instance.get<dynamic>(
          boxName: DB.instance.boxNameSetCache(coin: coin),
          key: groupId) as Map?;

      Map<String, dynamic> set;

      // null check to see if there is a cached set
      if (cachedSet == null) {
        set = {
          "setId": groupId,
          "blockHash": blockhash,
          "setHash": "",
          "coins": <dynamic>[],
        };

        // try up to 3 times
        for (int i = 0; i < 3; i++) {
          final result = await getInitialAnonymitySetCache(groupId);
          if (result != null) {
            set["setHash"] = result["setHash"];
            set["blockHash"] = result["blockHash"];
            set["coins"] = result["coins"];
            Logging.instance.log(
                "Populated initial anon set cache for group $groupId",
                level: LogLevel.Info);
            break;
          }
        }
      } else {
        set = Map<String, dynamic>.from(cachedSet);
      }

      final client = electrumXClient ??
          ElectrumX(
            host: server,
            port: port,
            useSSL: useSSL,
            prefs: prefs,
            failovers: failovers,
          );

      final newSet = await client.getAnonymitySet(
        groupId: groupId,
        blockhash: set["blockHash"] as String,
      );

      // update set with new data
      if (newSet["setHash"] != "" && set["setHash"] != newSet["setHash"]) {
        set["setHash"] = !isHexadecimal(newSet["setHash"] as String)
            ? base64ToReverseHex(newSet["setHash"] as String)
            : newSet["setHash"];
        set["blockHash"] = !isHexadecimal(newSet["blockHash"] as String)
            ? base64ToHex(newSet["blockHash"] as String)
            : newSet["blockHash"];
        for (int i = (newSet["coins"] as List).length - 1; i >= 0; i--) {
          dynamic newCoin = newSet["coins"][i];
          List translatedCoin = [];
          translatedCoin.add(!isHexadecimal(newCoin[0] as String)
              ? base64ToHex(newCoin[0] as String)
              : newCoin[0]);
          translatedCoin.add(!isHexadecimal(newCoin[1] as String)
              ? base64ToReverseHex(newCoin[1] as String)
              : newCoin[1]);
          try {
            translatedCoin.add(!isHexadecimal(newCoin[2] as String)
                ? base64ToHex(newCoin[2] as String)
                : newCoin[2]);
          } catch (e, s) {
            translatedCoin.add(newCoin[2]);
          }
          translatedCoin.add(!isHexadecimal(newCoin[3] as String)
              ? base64ToReverseHex(newCoin[3] as String)
              : newCoin[3]);
          set["coins"].insert(0, translatedCoin);
        }
        // save set to db
        await DB.instance.put<dynamic>(
            boxName: DB.instance.boxNameSetCache(coin: coin),
            key: groupId,
            value: set);
        Logging.instance.log(
            "Updated currently anonymity set for ${coin.name} with group ID $groupId",
            level: LogLevel.Info);
      }

      return set;
    } catch (e, s) {
      Logging.instance.log(
          "Failed to process CachedElectrumX.getAnonymitySet(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  String base64ToHex(String source) =>
      base64Decode(LineSplitter.split(source).join())
          .map((e) => e.toRadixString(16).padLeft(2, '0'))
          .join();

  String base64ToReverseHex(String source) =>
      base64Decode(LineSplitter.split(source).join())
          .reversed
          .map((e) => e.toRadixString(16).padLeft(2, '0'))
          .join();

  /// Call electrumx getTransaction on a per coin basis, storing the result in local db if not already there.
  ///
  /// ElectrumX api only called if the tx does not exist in local db
  Future<Map<String, dynamic>> getTransaction({
    required String txHash,
    required Coin coin,
    bool verbose = true,
  }) async {
    try {
      final cachedTx = DB.instance.get<dynamic>(
          boxName: DB.instance.boxNameTxCache(coin: coin), key: txHash) as Map?;
      if (cachedTx == null) {
        final client = electrumXClient ??
            ElectrumX(
              host: server,
              port: port,
              useSSL: useSSL,
              prefs: prefs,
              failovers: failovers,
            );
        final Map<String, dynamic> result =
            await client.getTransaction(txHash: txHash, verbose: verbose);

        result.remove("hex");
        result.remove("lelantusData");

        if (result["confirmations"] != null &&
            result["confirmations"] as int > minCacheConfirms) {
          await DB.instance.put<dynamic>(
              boxName: DB.instance.boxNameTxCache(coin: coin),
              key: txHash,
              value: result);
        }

        Logging.instance.log("using fetched result", level: LogLevel.Info);
        return result;
      } else {
        Logging.instance.log("using cached result", level: LogLevel.Info);
        return Map<String, dynamic>.from(cachedTx);
      }
    } catch (e, s) {
      Logging.instance.log(
          "Failed to process CachedElectrumX.getTransaction(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Future<List<dynamic>> getUsedCoinSerials({
    required Coin coin,
    int startNumber = 0,
  }) async {
    try {
      List<dynamic>? cachedSerials = DB.instance.get<dynamic>(
          boxName: DB.instance.boxNameUsedSerialsCache(coin: coin),
          key: "serials") as List?;

      cachedSerials ??= [];

      final startNumber = cachedSerials.length;

      final client = electrumXClient ??
          ElectrumX(
            host: server,
            port: port,
            useSSL: useSSL,
            prefs: prefs,
            failovers: failovers,
          );

      final serials = await client.getUsedCoinSerials(startNumber: startNumber);
      List newSerials = [];
      for (var element in (serials["serials"] as List)) {
        if (!isHexadecimal(element as String)) {
          newSerials.add(base64ToHex(element));
        } else {
          newSerials.add(element);
        }
      }
      cachedSerials.addAll(newSerials);

      await DB.instance.put<dynamic>(
          boxName: DB.instance.boxNameUsedSerialsCache(coin: coin),
          key: "serials",
          value: cachedSerials);

      return cachedSerials;
    } catch (e, s) {
      Logging.instance.log(
          "Failed to process CachedElectrumX.getTransaction(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  /// Clear all cached transactions for the specified coin
  Future<void> clearSharedTransactionCache({required Coin coin}) async {
    await DB.instance
        .deleteAll<dynamic>(boxName: DB.instance.boxNameTxCache(coin: coin));
    await DB.instance
        .deleteAll<dynamic>(boxName: DB.instance.boxNameSetCache(coin: coin));
    await DB.instance.deleteAll<dynamic>(
        boxName: DB.instance.boxNameUsedSerialsCache(coin: coin));
  }
}
