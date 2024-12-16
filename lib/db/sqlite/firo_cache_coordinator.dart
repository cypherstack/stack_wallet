part of 'firo_cache.dart';

typedef LTagPair = ({String tag, String txid});

/// Wrapper class for [_FiroCache] as [_FiroCache] should eventually be handled in a
/// background isolate and [FiroCacheCoordinator] should manage that isolate
abstract class FiroCacheCoordinator {
  static final Map<CryptoCurrencyNetwork, _FiroCacheWorker> _workers = {};
  static final Map<CryptoCurrencyNetwork, Mutex> _tagLocks = {};
  static final Map<CryptoCurrencyNetwork, Mutex> _setLocks = {};

  static bool _init = false;
  static Future<void> init() async {
    if (_init) {
      return;
    }
    _init = true;
    await _FiroCache.init();
    for (final network in _FiroCache.networks) {
      _tagLocks[network] = Mutex();
      _setLocks[network] = Mutex();
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
    final setMetaCacheFile = File(
      "${dir.path}/${_FiroCache.sparkSetMetaCacheFileName(network)}",
    );
    final usedTagsCacheFile = File(
      "${dir.path}/${_FiroCache.sparkUsedTagsCacheFileName(network)}",
    );

    final setSize =
        (await setCacheFile.exists()) ? await setCacheFile.length() : 0;
    final tagsSize = (await usedTagsCacheFile.exists())
        ? await usedTagsCacheFile.length()
        : 0;
    final setMetaSize =
        (await setMetaCacheFile.exists()) ? await setMetaCacheFile.length() : 0;

    Logging.instance.log(
      "Spark cache used tags size: $tagsSize",
      level: LogLevel.Debug,
    );
    Logging.instance.log(
      "Spark cache anon set size: $setSize",
      level: LogLevel.Debug,
    );
    Logging.instance.log(
      "Spark cache set meta size: $setMetaSize",
      level: LogLevel.Debug,
    );

    final int bytes = tagsSize + setSize + setMetaSize;

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
    await _tagLocks[network]!.protect(() async {
      final count = await FiroCacheCoordinator.getUsedCoinTagsCount(network);
      final unhashedTags =
          await client.getSparkUnhashedUsedCoinsTagsWithTxHashes(
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
    });
  }

  static Future<void> runFetchAndUpdateSparkAnonSetCacheForGroupId(
    int groupId,
    ElectrumXClient client,
    CryptoCurrencyNetwork network,
    void Function(int countFetched, int totalCount)? progressUpdated,
  ) async {
    await _setLocks[network]!.protect(() async {
      Map<String, dynamic> json;
      SparkAnonymitySetMeta? meta;

      if (progressUpdated == null) {
        // Legacy
        final blockhashResult =
            await FiroCacheCoordinator.getLatestSetInfoForGroupId(
          groupId,
          network,
        );
        final blockHash = blockhashResult?.blockHash ?? "";

        json = await client.getSparkAnonymitySet(
          coinGroupId: groupId.toString(),
          startBlockHash: blockHash.toHexReversedFromBase64,
        );
      } else {
        const sectorSize = 2000; // TODO adjust this?
        final prevMetaSize =
            await FiroCacheCoordinator.getSparkMetaSetSizeForGroupId(
          groupId,
          network,
        );
        final prevSize = prevMetaSize ?? 0;

        meta = await client.getSparkAnonymitySetMeta(
          coinGroupId: groupId,
        );

        progressUpdated.call(prevSize, meta.size);

        /// Returns blockHash (last block hash),
        /// setHash (hash of current set)
        /// and coins (the list of pairs serialized coin and tx hash)

        final fullSectorCount = (meta.size - prevSize) ~/ sectorSize;
        final remainder = (meta.size - prevSize) % sectorSize;

        final List<dynamic> coins = [];

        for (int i = 0; i < fullSectorCount; i++) {
          final start = (i * sectorSize) + prevSize;
          final data = await client.getSparkAnonymitySetBySector(
            coinGroupId: groupId,
            latestBlock: meta.blockHash.toHexReversedFromBase64,
            startIndex: start,
            endIndex: start + sectorSize,
          );
          progressUpdated.call(start + sectorSize, meta.size);

          coins.addAll(data);
        }

        if (remainder > 0) {
          final data = await client.getSparkAnonymitySetBySector(
            coinGroupId: groupId,
            latestBlock: meta.blockHash.toHexReversedFromBase64,
            startIndex: meta.size - remainder,
            endIndex: meta.size,
          );
          progressUpdated.call(meta.size, meta.size);

          coins.addAll(data);
        }

        json = {
          "blockHash": meta.blockHash,
          "setHash": meta.setHash,
          "coins": coins,
        };
      }

      await _workers[network]!.runTask(
        FCTask(
          func: FCFuncName._updateSparkAnonSetCoinsWith,
          data: (groupId, json),
        ),
      );

      if (meta != null) {
        await _workers[network]!.runTask(
          FCTask(
            func: FCFuncName._updateSparkAnonSetMetaWith,
            data: meta,
          ),
        );
      }
    });
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

  static Future<int?> getSparkMetaSetSizeForGroupId(
    int groupId,
    CryptoCurrencyNetwork network,
  ) async {
    final result = await _Reader._getSizeForGroupId(
      groupId,
      db: _FiroCache.setMetaCacheDB(network),
    );
    if (result.isEmpty) {
      return null;
    }

    return result.first["size"] as int;
  }
}
