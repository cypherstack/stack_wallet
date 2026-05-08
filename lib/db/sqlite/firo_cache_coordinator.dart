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

    final setSize = (await setCacheFile.exists())
        ? await setCacheFile.length()
        : 0;
    final tagsSize = (await usedTagsCacheFile.exists())
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

  /// Sync the Spark anonymity set cache for `groupId` from the node.
  ///
  /// Each sector the server returns is persisted to disk in its own SQLite
  /// transaction against an in-progress SparkSet row (`complete = 0`). The
  /// row and its coins are invisible to readers until
  /// [_markSparkAnonSetComplete] flips the flag after a strict integrity
  /// check (linked coin count == expected delta) passes.
  ///
  /// Resumability: if a prior sync crashed mid-download this function
  /// picks up at the count of coins already linked to the in-progress
  /// row, never re-downloading sectors that committed. If the server's
  /// blockHash has shifted between attempts the partial row is discarded
  /// (orderKey indices no longer align at the new blockHash) and the
  /// delta is fetched fresh.
  ///
  /// Integrity: the finalize step rolls back and leaves `complete = 0`
  /// if the link count doesn't match the expected delta — a partial or
  /// over-full cache never becomes the current set.
  static Future<void> runFetchAndUpdateSparkAnonSetCacheForGroupId(
    int groupId,
    ElectrumXClient client,
    CryptoCurrencyNetwork network,
    void Function(int countFetched, int totalCount)? progressUpdated,
  ) async {
    await _setLocks[network]!.protect(() async {
      const sectorSize = 1500;

      final prevMeta = await FiroCacheCoordinator.getLatestSetInfoForGroupId(
        groupId,
        network,
      );
      final prevSize = prevMeta?.size ?? 0;

      final meta = await client.getSparkAnonymitySetMeta(coinGroupId: groupId);

      void updateProgress(int fetchedDelta) {
        progressUpdated?.call(prevSize + fetchedDelta, meta.size);
      }

      if (prevMeta?.blockHash == meta.blockHash) {
        updateProgress(0);
        if (prevMeta?.size == meta.size) {
          Logging.instance.d(
            "Spark anon set groupId=$groupId already up to date "
            "(blockHash=${meta.blockHash}, size=${meta.size})",
          );
          return;
        }
        // Server reports a different size for the same blockHash. On
        // Firo's server this should be impossible (blockHash advances
        // whenever a coin is added), so this is treated as an anomaly.
        // Refuse to sync: appending coins to the existing finalized row
        // (what INSERT OR IGNORE in the writer would produce) would leak
        // unverified coins into a set whose setHash we've already
        // committed to.
        Logging.instance.w(
          "Spark anon set groupId=$groupId server reports different size "
          "(${prevMeta!.size} -> ${meta.size}) at same blockHash "
          "${meta.blockHash}; skipping sync to preserve cached state.",
        );
        return;
      }

      final numberOfCoinsToFetch = meta.size - prevSize;
      if (numberOfCoinsToFetch < 0) {
        updateProgress(0);
        // Reorg-style shrink: server has fewer coins than our last
        // finalized set. Refuse to sync rather than invalidate cached data.
        Logging.instance.w(
          "Spark anon set groupId=$groupId appears to have shrunk "
          "($prevSize -> ${meta.size}); skipping sync to preserve "
          "cached data.",
        );
        return;
      }
      if (numberOfCoinsToFetch == 0) {
        updateProgress(0);
        // blockHash advanced but no new coins in this group's set. We do
        // not materialise a new SparkSet row for an empty delta — a
        // same-size row would create a tiebreaker ambiguity in
        // _getLatestSetInfoForGroupId. Drop any stray in-progress row so
        // it doesn't confuse the next resume attempt.
        final stale = await _Reader._getIncompleteSetForGroupId(
          groupId,
          db: _FiroCache.setCacheDB(network),
        );
        if (stale.isNotEmpty) {
          await _workers[network]!.runTask(
            FCTask(
              func: FCFuncName._deleteIncompleteSparkSetsForGroup,
              data: groupId,
            ),
          );
        }
        return;
      }

      // Decide whether to resume an existing in-progress row or start
      // fresh. Cases:
      //   * no in-progress row                     -> cursor = 0
      //   * in-progress blockHash differs          -> discard, cursor = 0
      //   * in-progress linked > expected delta    -> corrupt, discard,
      //                                               cursor = 0
      //   * in-progress blockHash matches          -> cursor = linkedSoFar
      final incomplete = await _Reader._getIncompleteSetForGroupId(
        groupId,
        db: _FiroCache.setCacheDB(network),
      );

      int cursor;
      if (incomplete.isEmpty) {
        cursor = 0;
      } else if (incomplete.length > 1) {
        Logging.instance.w(
          "Spark anon set groupId=$groupId has ${incomplete.length} "
          "in-progress rows; discarding ambiguous state.",
        );
        await _workers[network]!.runTask(
          FCTask(
            func: FCFuncName._deleteIncompleteSparkSetsForGroup,
            data: groupId,
          ),
        );
        cursor = 0;
      } else {
        final incBlockHash = incomplete.first["blockHash"] as String;
        final incSetHash = incomplete.first["setHash"] as String;
        final incSetId = incomplete.first["id"] as int;

        // Discard the in-progress row if either blockHash or setHash
        // disagrees with the current meta. blockHash disagreement means
        // the server's indexing has shifted; setHash disagreement at the
        // same blockHash would indicate the in-progress row targets a
        // different set snapshot and resuming would mix coin contexts.
        if (incBlockHash != meta.blockHash || incSetHash != meta.setHash) {
          Logging.instance.i(
            "Spark anon set groupId=$groupId in-progress "
            "(blockHash=$incBlockHash, setHash=$incSetHash) does not "
            "match meta (blockHash=${meta.blockHash}, "
            "setHash=${meta.setHash}); discarding in-flight row.",
          );
          await _workers[network]!.runTask(
            FCTask(
              func: FCFuncName._deleteIncompleteSparkSetsForGroup,
              data: groupId,
            ),
          );
          cursor = 0;
        } else {
          final linked = await _Reader._countSetCoins(
            incSetId,
            db: _FiroCache.setCacheDB(network),
          );
          if (linked > numberOfCoinsToFetch) {
            Logging.instance.w(
              "Spark anon set groupId=$groupId in-progress row has "
              "$linked linked coins but delta is only "
              "$numberOfCoinsToFetch; discarding in-flight row.",
            );
            await _workers[network]!.runTask(
              FCTask(
                func: FCFuncName._deleteIncompleteSparkSetsForGroup,
                data: groupId,
              ),
            );
            cursor = 0;
          } else {
            cursor = linked;
          }
        }
      }

      updateProgress(cursor);

      while (cursor < numberOfCoinsToFetch) {
        final endIndex = cursor + sectorSize <= numberOfCoinsToFetch
            ? cursor + sectorSize
            : numberOfCoinsToFetch;
        final expected = endIndex - cursor;

        final data = await client.getSparkAnonymitySetBySector(
          coinGroupId: groupId,
          latestBlock: meta.blockHash,
          startIndex: cursor,
          endIndex: endIndex,
        );

        // Refuse to persist a sector whose size doesn't match the request:
        // a partial or over-full server response would break the finalize-
        // time integrity check and potentially skew the resume cursor.
        if (data.length != expected) {
          throw Exception(
            "Spark anon set sector size mismatch for groupId=$groupId: "
            "requested $expected coins in range [$cursor, $endIndex), "
            "server returned ${data.length}",
          );
        }

        final sectorCoins = data
            .map((e) => RawSparkCoin.fromRPCResponse(e as List, groupId))
            .toList();

        await _workers[network]!.runTask(
          FCTask(
            func: FCFuncName._insertSparkAnonSetCoinsIncremental,
            data: (meta, sectorCoins, cursor),
          ),
        );

        cursor = endIndex;
        updateProgress(cursor);
      }

      // All sectors persisted. Flip `complete = 1` iff the link count
      // matches the expected delta. On failure the in-progress row stays
      // hidden and the error propagates; the next sync will observe the
      // over-linked row and reset.
      await _workers[network]!.runTask(
        FCTask(
          func: FCFuncName._markSparkAnonSetComplete,
          data: (meta, numberOfCoinsToFetch),
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
    final resultSet = afterBlockHash == null
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

  static Future<({SparkAnonymitySetMeta meta, List<RawSparkCoin> coins})?>
  getSetCoinsAndLatestSetInfoForGroupId(
    int groupId,
    CryptoCurrencyNetwork network,
  ) async {
    final resultSet = await _Reader._getSetCoinsAndLatestSetInfoForGroupId(
      groupId,
      db: _FiroCache.setCacheDB(network),
    );
    if (resultSet.isEmpty) {
      return null;
    }

    final first = resultSet.first;
    final coins = resultSet
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

    return (
      meta: SparkAnonymitySetMeta(
        coinGroupId: groupId,
        blockHash: first["blockHash"] as String,
        setHash: first["setHash"] as String,
        size: first["size"] as int,
      ),
      coins: coins,
    );
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
