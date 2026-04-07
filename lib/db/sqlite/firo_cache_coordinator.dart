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

  static Future<void> clearSharedCache(
    CryptoCurrencyNetwork network, {
    bool clearOnlyUsedTagsCache = false,
  }) async {
    if (clearOnlyUsedTagsCache) {
      return await _FiroCache._deleteUsedTagsCache(network);
    }
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

    final setSize =
        (await setCacheFile.exists()) ? await setCacheFile.length() : 0;
    final tagsSize =
        (await usedTagsCacheFile.exists())
            ? await usedTagsCacheFile.length()
            : 0;

    Logging.instance.d("Spark cache used tags size: $tagsSize");
    Logging.instance.d("Spark cache anon set size: $setSize");

    final int bytes = tagsSize + setSize;

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
      final unhashedTags = await client
          .getSparkUnhashedUsedCoinsTagsWithTxHashes(startNumber: count);
      if (unhashedTags.isNotEmpty) {
        await _workers[network]!.runTask(
          FCTask(func: FCFuncName._updateSparkUsedTagsWith, data: unhashedTags),
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
      const sectorSize =
          1500; // chosen as a somewhat decent value. Could be changed in the future if wanted/needed
      final prevMeta = await FiroCacheCoordinator.getLatestSetInfoForGroupId(
        groupId,
        network,
      );

      final prevSize = prevMeta?.size ?? 0;

      final meta = await client.getSparkAnonymitySetMeta(coinGroupId: groupId);

      progressUpdated?.call(prevSize, meta.size);

      if (prevMeta?.blockHash == meta.blockHash &&
          prevMeta!.size >= meta.size) {
        Logging.instance.d(
          "prevMeta matches meta blockHash and size >= meta.size, "
          "already up to date",
        );
        return;
      }

      // When resuming a partial download of the SAME block, we can skip
      // already-saved coins because the index space hasn't shifted.
      //
      // When the block changes, we check the `complete` flag on the
      // previous SparkSet to determine if the old download finished.
      // - Complete: use the delta (meta.size - prevSize) from index 0.
      //   The newest coins in the new block are at the lowest indices.
      // - Partial: indices have shifted due to the new block, so we
      //   can't reliably compute which coins are missing. Re-download
      //   the full set from index 0. INSERT OR IGNORE handles overlap.
      final bool sameBlock = prevMeta?.blockHash == meta.blockHash;

      final int numberOfCoinsToFetch;
      final int indexOffset;

      if (sameBlock) {
        // Same block: resume from where we left off.
        numberOfCoinsToFetch = meta.size - prevSize;
        indexOffset = prevSize;
      } else if (prevMeta != null && prevMeta.complete) {
        // Different block, but previous download was complete.
        // The delta coins are at indices 0..(meta.size - prevSize - 1).
        numberOfCoinsToFetch = meta.size - prevSize;
        indexOffset = 0;
      } else {
        // Different block and previous download was partial (or no
        // previous data). Must re-download the full set.
        numberOfCoinsToFetch = meta.size;
        indexOffset = 0;
      }

      if (numberOfCoinsToFetch <= 0) {
        // Edge case: reorg, stale cache, or already up to date.
        return;
      }

      final fullSectorCount = numberOfCoinsToFetch ~/ sectorSize;
      final remainder = numberOfCoinsToFetch % sectorSize;

      int coinsSaved = 0;

      for (int i = 0; i < fullSectorCount; i++) {
        final start = indexOffset + (i * sectorSize);
        final data = await client.getSparkAnonymitySetBySector(
          coinGroupId: groupId,
          latestBlock: meta.blockHash,
          startIndex: start,
          endIndex: start + sectorSize,
        );

        final sectorCoins =
            data
                .map((e) => RawSparkCoin.fromRPCResponse(e as List, groupId))
                .toList();

        coinsSaved += sectorCoins.length;

        await _workers[network]!.runTask(
          FCTask(
            func: FCFuncName._insertSparkAnonSetCoinsIncremental,
            data: (meta, sectorCoins, indexOffset + coinsSaved),
          ),
        );

        progressUpdated?.call(
          indexOffset + (i + 1) * sectorSize,
          meta.size,
        );
      }

      if (remainder > 0) {
        final remainderStart = indexOffset + numberOfCoinsToFetch - remainder;
        final data = await client.getSparkAnonymitySetBySector(
          coinGroupId: groupId,
          latestBlock: meta.blockHash,
          startIndex: remainderStart,
          endIndex: indexOffset + numberOfCoinsToFetch,
        );

        final sectorCoins =
            data
                .map((e) => RawSparkCoin.fromRPCResponse(e as List, groupId))
                .toList();

        coinsSaved += sectorCoins.length;

        await _workers[network]!.runTask(
          FCTask(
            func: FCFuncName._insertSparkAnonSetCoinsIncremental,
            data: (meta, sectorCoins, indexOffset + coinsSaved),
          ),
        );

        progressUpdated?.call(meta.size, meta.size);
      }

      // Mark this SparkSet as complete so cross-block resume knows
      // the download finished and can safely use the delta approach.
      await _workers[network]!.runTask(
        FCTask(
          func: FCFuncName._markSparkAnonSetComplete,
          data: meta,
        ),
      );
    });
  }

  // ===========================================================================

  static Future<List<String>> getUsedCoinTags(
    int startNumber,
    CryptoCurrencyNetwork network,
  ) async {
    final result = await _Reader._getSparkUsedCoinTags(
      startNumber,
      db: _FiroCache.usedTagsCacheDB(network),
    );
    return result.map((e) => e["tag"] as String).toList();
  }

  static Future<int> getUsedCoinTagsCount(CryptoCurrencyNetwork network) async {
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
        .map((e) => (tag: e[0] as String, txid: e[1] as String))
        .toList();
  }

  static Future<List<String>> getUsedCoinTagsFor({
    required String txid,
    required CryptoCurrencyNetwork network,
  }) async {
    final result = await _Reader._getUsedCoinTagsFor(
      txid,
      db: _FiroCache.usedTagsCacheDB(network),
    );
    return result.map((e) => e["tag"] as String).toList();
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

  static Future<List<RawSparkCoin>> getSetCoinsForGroupId(
    int groupId, {
    String? afterBlockHash,
    required CryptoCurrencyNetwork network,
  }) async {
    final resultSet =
        afterBlockHash == null
            ? await _Reader._getSetCoinsForGroupId(
              groupId,
              db: _FiroCache.setCacheDB(network),
            )
            : await _Reader._getSetCoinsForGroupIdAndBlockHash(
              groupId,
              afterBlockHash,
              db: _FiroCache.setCacheDB(network),
            );

    return resultSet
        .map(
          (row) => RawSparkCoin(
            serialized: row["serialized"] as String,
            txHash: row["txHash"] as String,
            context: row["context"] as String,
            groupId: groupId,
          ),
        )
        .toList()
        .reversed
        .toList();
  }

  static Future<SparkAnonymitySetMeta?> getLatestSetInfoForGroupId(
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

    return SparkAnonymitySetMeta(
      coinGroupId: groupId,
      blockHash: result.first["blockHash"] as String,
      setHash: result.first["setHash"] as String,
      size: result.first["size"] as int,
      complete: (result.first["complete"] as int) == 1,
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
