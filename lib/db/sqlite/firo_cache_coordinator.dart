part of 'firo_cache.dart';

/// Wrapper class for [_FiroCache] as [_FiroCache] should eventually be handled in a
/// background isolate and [FiroCacheCoordinator] should manage that isolate
abstract class FiroCacheCoordinator {
  static _FiroCacheWorker? _worker;

  static bool _init = false;
  static Future<void> init() async {
    if (_init) {
      return;
    }
    _init = true;
    await _FiroCache.init();
    _worker = await _FiroCacheWorker.spawn();
  }

  static Future<void> clearSharedCache() async {
    return await _FiroCache._deleteAllCache();
  }

  static Future<String> getSparkCacheSize() async {
    final dir = await StackFileSystem.applicationFiroCacheSQLiteDirectory();
    final setCacheFile = File(
      "${dir.path}/${_FiroCache.sparkSetCacheFileName}",
    );
    final usedTagsCacheFile = File(
      "${dir.path}/${_FiroCache.sparkUsedTagsCacheFileName}",
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
  ) async {
    final count = await FiroCacheCoordinator.getUsedCoinTagsCount();
    final unhashedTags = await client.getSparkUnhashedUsedCoinsTags(
      startNumber: count,
    );
    if (unhashedTags.isNotEmpty) {
      await _worker!.runTask(
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
  ) async {
    final blockhashResult =
        await FiroCacheCoordinator.getLatestSetInfoForGroupId(
      groupId,
    );
    final blockHash = blockhashResult?.blockHash ?? "";

    final json = await client.getSparkAnonymitySet(
      coinGroupId: groupId.toString(),
      startBlockHash: blockHash.toHexReversedFromBase64,
    );

    await _worker!.runTask(
      FCTask(
        func: FCFuncName._updateSparkAnonSetCoinsWith,
        data: (groupId, json),
      ),
    );
  }

  // ===========================================================================

  static Future<Set<String>> getUsedCoinTags(int startNumber) async {
    final result = await _Reader._getSparkUsedCoinTags(
      startNumber,
      db: _FiroCache.usedTagsCacheDB,
    );
    return result.map((e) => e["tag"] as String).toSet();
  }

  /// This should be the equivalent of counting the number of tags in the db.
  /// Assuming the integrity of the data. Faster than actually calling count on
  /// a table where no records have been deleted. None should be deleted from
  /// this table in practice.
  static Future<int> getUsedCoinTagsCount() async {
    final result = await _Reader._getUsedCoinTagsCount(
      db: _FiroCache.usedTagsCacheDB,
    );
    if (result.isEmpty) {
      return 0;
    }
    return result.first["count"] as int? ?? 0;
  }

  static Future<bool> checkTagIsUsed(
    String tag,
  ) async {
    return await _Reader._checkTagIsUsed(
      tag,
      db: _FiroCache.usedTagsCacheDB,
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
  }) async {
    final resultSet = await _Reader._getSetCoinsForGroupId(
      groupId,
      db: _FiroCache.setCacheDB,
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
  ) async {
    final result = await _Reader._getLatestSetInfoForGroupId(
      groupId,
      db: _FiroCache.setCacheDB,
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
  ) async {
    return await _Reader._checkSetInfoForGroupIdExists(
      groupId,
      db: _FiroCache.setCacheDB,
    );
  }
}
