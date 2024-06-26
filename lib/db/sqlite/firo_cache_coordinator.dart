part of 'firo_cache.dart';

typedef LTagPair = ({String tag, String txid});

/// Wrapper class for [_FiroCache] as [_FiroCache] should eventually be handled in a
/// background isolate and [FiroCacheCoordinator] should manage that isolate
abstract class FiroCacheCoordinator {
  static final Map<CryptoCurrencyNetwork, _FiroCacheWorker> _workers = {};

  static bool _init = false;
  static Future<void> init() async {
    if (_init) {
      return;
    }
    _init = true;
    await _FiroCache.init();
    for (final network in _FiroCache.networks) {
      _workers[network] = await _FiroCacheWorker.spawn(network);
    }
  }

  static Future<void> clearSharedCache(CryptoCurrencyNetwork network) async {
    return await _FiroCache._deleteAllCache(network);
  }

  static Future<String> getSparkCacheSize(CryptoCurrencyNetwork network) async {
    final dir = await StackFileSystem.applicationFiroCacheSQLiteDirectory();
    final setCacheFile = File(
      "${dir.path}/${_FiroCache.sparkSetCacheFileName(network)}",
    );
    final usedTagsCacheFile = File(
      "${dir.path}/${_FiroCache.sparkUsedTagsCacheFileName(network)}",
    );
    final int bytes =
        ((await setCacheFile.exists()) ? await setCacheFile.length() : 0) +
            ((await usedTagsCacheFile.exists())
                ? await usedTagsCacheFile.length()
                : 0);

    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1048576) {
      final double kbSize = bytes / 1024;
      return '${kbSize.toStringAsFixed(2)} KB';
    } else if (bytes < 1073741824) {
      final double mbSize = bytes / 1048576;
      return '${mbSize.toStringAsFixed(2)} MB';
    } else {
      final double gbSize = bytes / 1073741824;
      return '${gbSize.toStringAsFixed(2)} GB';
    }
  }

  static Future<void> runFetchAndUpdateSparkUsedCoinTags(
    ElectrumXClient client,
    CryptoCurrencyNetwork network,
  ) async {
    final count = await FiroCacheCoordinator.getUsedCoinTagsCount(network);
    final unhashedTags = await client.getSparkUnhashedUsedCoinsTagsWithTxHashes(
      startNumber: count,
    );
    if (unhashedTags.isNotEmpty) {
      await _workers[network]!.runTask(
        FCTask(
          func: FCFuncName._updateSparkUsedTagsWith,
          data: unhashedTags,
        ),
      );
    }
  }

  static Future<void> runFetchAndUpdateSparkAnonSetCacheForGroupId(
    int groupId,
    ElectrumXClient client,
    CryptoCurrencyNetwork network,
  ) async {
    final blockhashResult =
        await FiroCacheCoordinator.getLatestSetInfoForGroupId(
      groupId,
      network,
    );
    final blockHash = blockhashResult?.blockHash ?? "";

    final json = await client.getSparkAnonymitySet(
      coinGroupId: groupId.toString(),
      startBlockHash: blockHash.toHexReversedFromBase64,
    );

    await _workers[network]!.runTask(
      FCTask(
        func: FCFuncName._updateSparkAnonSetCoinsWith,
        data: (groupId, json),
      ),
    );
  }

  // ===========================================================================

  static Future<Set<String>> getUsedCoinTags(
    int startNumber,
    CryptoCurrencyNetwork network,
  ) async {
    final result = await _Reader._getSparkUsedCoinTags(
      startNumber,
      db: _FiroCache.usedTagsCacheDB(network),
    );
    return result.map((e) => e["tag"] as String).toSet();
  }

  static Future<int> getUsedCoinTagsCount(
    CryptoCurrencyNetwork network,
  ) async {
    final result = await _Reader._getUsedCoinTagsCount(
      db: _FiroCache.usedTagsCacheDB(network),
    );
    if (result.isEmpty) {
      return 0;
    }
    return result.first["count"] as int? ?? 0;
  }

  static Future<List<LTagPair>> getUsedCoinTxidsFor({
    required List<String> tags,
    required CryptoCurrencyNetwork network,
  }) async {
    if (tags.isEmpty) {
      return [];
    }
    final result = await _Reader._getUsedCoinTxidsFor(
      tags,
      db: _FiroCache.usedTagsCacheDB(network),
    );

    if (result.isEmpty) {
      return [];
    }
    return result.rows
        .map(
          (e) => (
            tag: e[0] as String,
            txid: e[1] as String,
          ),
        )
        .toList();
  }

  static Future<Set<String>> getUsedCoinTagsFor({
    required String txid,
    required CryptoCurrencyNetwork network,
  }) async {
    final result = await _Reader._getUsedCoinTagsFor(
      txid,
      db: _FiroCache.usedTagsCacheDB(network),
    );
    return result.map((e) => e["tag"] as String).toSet();
  }

  static Future<bool> checkTagIsUsed(
    String tag,
    CryptoCurrencyNetwork network,
  ) async {
    return await _Reader._checkTagIsUsed(
      tag,
      db: _FiroCache.usedTagsCacheDB(network),
    );
  }

  static Future<
      List<
          ({
            String serialized,
            String txHash,
            String context,
          })>> getSetCoinsForGroupId(
    int groupId, {
    int? newerThanTimeStamp,
    required CryptoCurrencyNetwork network,
  }) async {
    final resultSet = await _Reader._getSetCoinsForGroupId(
      groupId,
      db: _FiroCache.setCacheDB(network),
      newerThanTimeStamp: newerThanTimeStamp,
    );
    return resultSet
        .map(
          (row) => (
            serialized: row["serialized"] as String,
            txHash: row["txHash"] as String,
            context: row["context"] as String,
          ),
        )
        .toList()
        .reversed
        .toList();
  }

  static Future<
      ({
        String blockHash,
        String setHash,
        int timestampUTC,
      })?> getLatestSetInfoForGroupId(
    int groupId,
    CryptoCurrencyNetwork network,
  ) async {
    final result = await _Reader._getLatestSetInfoForGroupId(
      groupId,
      db: _FiroCache.setCacheDB(network),
    );

    if (result.isEmpty) {
      return null;
    }

    return (
      blockHash: result.first["blockHash"] as String,
      setHash: result.first["setHash"] as String,
      timestampUTC: result.first["timestampUTC"] as int,
    );
  }

  static Future<bool> checkSetInfoForGroupIdExists(
    int groupId,
    CryptoCurrencyNetwork network,
  ) async {
    return await _Reader._checkSetInfoForGroupIdExists(
      groupId,
      db: _FiroCache.setCacheDB(network),
    );
  }
}
