import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_libsparkmobile/flutter_libsparkmobile.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../electrumx_rpc/electrumx_client.dart';
import '../../utilities/extensions/extensions.dart';
import '../../utilities/logger.dart';
import '../../utilities/stack_file_system.dart';

/// Temporary debugging log function for this file
void _debugLog(Object? object) {
  if (kDebugMode) {
    Logging.instance.log(
      object,
      level: LogLevel.Debug,
    );
  }
}

List<String> _ffiHashTagsComputeWrapper(List<String> base64Tags) {
  return LibSpark.hashTags(base64Tags: base64Tags);
}

/// Wrapper class for [_FiroCache] as [_FiroCache] should eventually be handled in a
/// background isolate and [FiroCacheCoordinator] should manage that isolate
abstract class FiroCacheCoordinator {
  static Future<void> init() => _FiroCache.init();

  static Future<void> runFetchAndUpdateSparkUsedCoinTags(
    ElectrumXClient client,
  ) async {
    final count = await FiroCacheCoordinator.getUsedCoinTagsLastAddedRowId();
    final unhashedTags = await client.getSparkUnhashedUsedCoinsTags(
      startNumber: count,
    );
    if (unhashedTags.isNotEmpty) {
      final hashedTags = await compute(
        _ffiHashTagsComputeWrapper,
        unhashedTags,
      );
      await _FiroCache._updateSparkUsedTagsWith(hashedTags);
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

    await _FiroCache._updateSparkAnonSetCoinsWith(json, groupId);
  }

  // ===========================================================================

  static Future<Set<String>> getUsedCoinTags(int startNumber) async {
    final result = await _FiroCache._getSparkUsedCoinTags(
      startNumber,
    );
    return result.map((e) => e["tag"] as String).toSet();
  }

  /// This should be the equivalent of counting the number of tags in the db.
  /// Assuming the integrity of the data. Faster than actually calling count on
  /// a table where no records have been deleted. None should be deleted from
  /// this table in practice.
  static Future<int> getUsedCoinTagsLastAddedRowId() async {
    final result = await _FiroCache._getUsedCoinTagsLastAddedRowId();
    if (result.isEmpty) {
      return 0;
    }
    return result.first["highestId"] as int? ?? 0;
  }

  static Future<bool> checkTagIsUsed(
    String tag,
  ) async {
    return await _FiroCache._checkTagIsUsed(
      tag,
    );
  }

  static Future<ResultSet> getSetCoinsForGroupId(
    int groupId, {
    int? newerThanTimeStamp,
  }) async {
    return await _FiroCache._getSetCoinsForGroupId(
      groupId,
      newerThanTimeStamp: newerThanTimeStamp,
    );
  }

  static Future<
      ({
        String blockHash,
        String setHash,
        int timestampUTC,
      })?> getLatestSetInfoForGroupId(
    int groupId,
  ) async {
    final result = await _FiroCache._getLatestSetInfoForGroupId(groupId);

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
    return await _FiroCache._checkSetInfoForGroupIdExists(
      groupId,
    );
  }
}

abstract class _FiroCache {
  static const String sqliteDbFileName = "firo_ex_cache.sqlite3";

  static Database? _db;
  static Database get db {
    if (_db == null) {
      throw Exception(
        "FiroCache.init() must be called before accessing FiroCache.db!",
      );
    }
    return _db!;
  }

  static Future<void>? _initFuture;
  static Future<void> init() => _initFuture ??= _init();

  static Future<void> _init() async {
    final sqliteDir = await StackFileSystem.applicationSQLiteDirectory();

    final file = File("${sqliteDir.path}/$sqliteDbFileName");

    final exists = await file.exists();
    if (!exists) {
      await _createDb(file.path);
    }

    _db = sqlite3.open(
      file.path,
      mode: OpenMode.readWrite,
    );
  }

  static Future<void> _createDb(String file) async {
    final db = sqlite3.open(
      file,
      mode: OpenMode.readWriteCreate,
    );

    db.execute(
      """
        CREATE TABLE SparkSet (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
            blockHash TEXT NOT NULL,
            setHash TEXT NOT NULL,
            groupId INTEGER NOT NULL,
            timestampUTC INTEGER NOT NULL,
            UNIQUE (blockHash, setHash, groupId)
        );
    
        CREATE TABLE SparkCoin (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
          serialized TEXT NOT NULL,
          txHash TEXT NOT NULL,
          context TEXT NOT NULL,
          UNIQUE(serialized, txHash, context)
        );
    
        CREATE TABLE SparkSetCoins (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
            setId INTEGER NOT NULL,
            coinId INTEGER NOT NULL,
            FOREIGN KEY (setId) REFERENCES SparkSet(id),
            FOREIGN KEY (coinId) REFERENCES SparkCoin(id)
        );
        
        CREATE TABLE SparkUsedCoinTags (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
          tag TEXT NOT NULL UNIQUE
        );
    """,
    );

    db.dispose();
  }

  // ===========================================================================
  // =============== Spark anonymity set queries ===============================

  static Future<ResultSet> _getSetCoinsForGroupId(
    int groupId, {
    int? newerThanTimeStamp,
  }) async {
    String query = """
      SELECT sc.serialized, sc.txHash, sc.context
      FROM SparkSet AS ss
      JOIN SparkSetCoins AS ssc ON ss.id = ssc.setId
      JOIN SparkCoin AS sc ON ssc.coinId = sc.id
      WHERE ss.groupId = $groupId
    """;

    if (newerThanTimeStamp != null) {
      query += " AND ss.timestampUTC"
          " > $newerThanTimeStamp";
    }

    return db.select("$query;");
  }

  static Future<ResultSet> _getLatestSetInfoForGroupId(
    int groupId,
  ) async {
    final query = """
      SELECT ss.blockHash, ss.setHash, ss.timestampUTC
      FROM SparkSet ss
      WHERE ss.groupId = $groupId
      ORDER BY ss.timestampUTC DESC
      LIMIT 1;
    """;

    return db.select("$query;");
  }

  static Future<bool> _checkSetInfoForGroupIdExists(
    int groupId,
  ) async {
    final query = """
      SELECT EXISTS (
        SELECT 1
        FROM SparkSet
        WHERE groupId = $groupId
      ) AS setExists;
    """;

    return db.select("$query;").first["setExists"] == 1;
  }

  // ===========================================================================
  // =============== Spark used coin tags queries ==============================

  static Future<ResultSet> _getSparkUsedCoinTags(
    int startNumber,
  ) async {
    String query = """
      SELECT tag
      FROM SparkUsedCoinTags
    """;

    if (startNumber > 0) {
      query += " WHERE id >= $startNumber";
    }

    return db.select("$query;");
  }

  static Future<ResultSet> _getUsedCoinTagsLastAddedRowId() async {
    const query = """
      SELECT MAX(id) AS highestId
      FROM SparkUsedCoinTags;
    """;

    return db.select("$query;");
  }

  static Future<bool> _checkTagIsUsed(String tag) async {
    final query = """
      SELECT EXISTS (
        SELECT 1
        FROM SparkUsedCoinTags
        WHERE tag = '$tag'
      ) AS tagExists;
    """;

    return db.select("$query;").first["tagExists"] == 1;
  }

  // ===========================================================================
  // ================== write to spark used tags cache =========================

  // debug log counter var
  static int _updateTagsCount = 0;

  /// update the sqlite cache
  /// Expected json format:
  ///    {
  ///         "blockHash": "someBlockHash",
  ///         "setHash": "someSetHash",
  ///         "coins": [
  ///           ["serliazed1", "hash1", "context1"],
  ///           ["serliazed2", "hash2", "context2"],
  ///           ...
  ///           ["serliazed3", "hash3", "context3"],
  ///           ["serliazed4", "hash4", "context4"],
  ///         ],
  ///     }
  ///
  /// returns true if successful, otherwise false
  static Future<bool> _updateSparkUsedTagsWith(
    List<String> tags,
  ) async {
    final start = DateTime.now();
    _updateTagsCount++;

    if (tags.isEmpty) {
      _debugLog(
        "$_updateTagsCount _updateSparkUsedTagsWith(tags) called "
        "where tags is empty",
      );
      _debugLog(
        "$_updateTagsCount _updateSparkUsedTagsWith() "
        "duration = ${DateTime.now().difference(start)}",
      );
      // nothing to add, return early
      return true;
    } else if (tags.length <= 10) {
      _debugLog("$_updateTagsCount _updateSparkUsedTagsWith() called where "
          "tags.length=${tags.length}, tags: $tags,");
    } else {
      _debugLog(
        "$_updateTagsCount _updateSparkUsedTagsWith() called where"
        " tags.length=${tags.length},"
        " first 5 tags: ${tags.sublist(0, 5)},"
        " last 5 tags: ${tags.sublist(tags.length - 5, tags.length)}",
      );
    }

    db.execute("BEGIN;");
    try {
      for (final tag in tags) {
        db.execute(
          """
              INSERT OR IGNORE INTO SparkUsedCoinTags (tag)
              VALUES (?);
            """,
          [tag],
        );
      }

      db.execute("COMMIT;");
      _debugLog("$_updateTagsCount _updateSparkUsedTagsWith() COMMITTED");
      _debugLog(
        "$_updateTagsCount _updateSparkUsedTagsWith() "
        "duration = ${DateTime.now().difference(start)}",
      );
      return true;
    } catch (e, s) {
      db.execute("ROLLBACK;");
      _debugLog("$_updateTagsCount _updateSparkUsedTagsWith() ROLLBACK");
      _debugLog(
        "$_updateTagsCount _updateSparkUsedTagsWith() "
        "duration = ${DateTime.now().difference(start)}",
      );
      // NOTE THIS LOGGER MUST BE CALLED ON MAIN ISOLATE FOR NOW
      Logging.instance.log(
        "$e\n$s",
        level: LogLevel.Error,
      );
    }

    return false;
  }

  // ===========================================================================
  // ================== write to spark anon set cache ==========================

  // debug log counter var
  static int _updateAnonSetCount = 0;

  /// update the sqlite cache
  /// Expected json format:
  ///    {
  ///         "blockHash": "someBlockHash",
  ///         "setHash": "someSetHash",
  ///         "coins": [
  ///           ["serliazed1", "hash1", "context1"],
  ///           ["serliazed2", "hash2", "context2"],
  ///           ...
  ///           ["serliazed3", "hash3", "context3"],
  ///           ["serliazed4", "hash4", "context4"],
  ///         ],
  ///     }
  ///
  /// returns true if successful, otherwise false
  static Future<bool> _updateSparkAnonSetCoinsWith(
    Map<String, dynamic> json,
    int groupId,
  ) async {
    final start = DateTime.now();
    _updateAnonSetCount++;
    final blockHash = json["blockHash"] as String;
    final setHash = json["setHash"] as String;
    final coinsRaw = json["coins"] as List;

    _debugLog(
      "$_updateAnonSetCount _updateSparkAnonSetCoinsWith() "
      "called where groupId=$groupId, "
      "blockHash=$blockHash (${blockHash.toHexReversedFromBase64}), "
      "setHash=$setHash, "
      "coins.length: ${coinsRaw.isEmpty ? 0 : coinsRaw.length}",
    );

    if ((json["coins"] as List).isEmpty) {
      _debugLog(
        "$_updateAnonSetCount _updateSparkAnonSetCoinsWith()"
        " called where json[coins] is Empty",
      );
      _debugLog(
        "$_updateAnonSetCount _updateSparkAnonSetCoinsWith()"
        " duration = ${DateTime.now().difference(start)}",
      );
      // no coins to actually insert
      return true;
    }

    final checkResult = db.select(
      """
        SELECT *
        FROM SparkSet
        WHERE blockHash = ? AND setHash = ? AND groupId = ?;
      """,
      [
        blockHash,
        setHash,
        groupId,
      ],
    );

    _debugLog(
      "$_updateAnonSetCount _updateSparkAnonSetCoinsWith()"
      " called where checkResult=$checkResult",
    );

    if (checkResult.isNotEmpty) {
      _debugLog(
        "$_updateAnonSetCount _updateSparkAnonSetCoinsWith()"
        " duration = ${DateTime.now().difference(start)}",
      );
      // already up to date
      return true;
    }

    final coins = coinsRaw
        .map(
          (e) => [
            e[0] as String,
            e[1] as String,
            e[2] as String,
          ],
        )
        .toList();

    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

    db.execute("BEGIN;");
    try {
      db.execute(
        """
          INSERT INTO SparkSet (blockHash, setHash, groupId, timestampUTC)
          VALUES (?, ?, ?, ?);
        """,
        [blockHash, setHash, groupId, timestamp],
      );
      final setId = db.lastInsertRowId;

      for (final coin in coins) {
        int coinId;
        try {
          // try to insert and get row id
          db.execute(
            """
              INSERT INTO SparkCoin (serialized, txHash, context)
              VALUES (?, ?, ?);
            """,
            coin,
          );
          coinId = db.lastInsertRowId;
        } on SqliteException catch (e) {
          // if there already is a matching coin in the db
          // just grab its row id
          if (e.extendedResultCode == 2067) {
            final result = db.select(
              """
                SELECT id
                FROM SparkCoin
                WHERE serialized = ? AND txHash = ? AND context = ?;
              """,
              coin,
            );
            coinId = result.first["id"] as int;
          } else {
            rethrow;
          }
        }

        // finally add the row id to the newly added set
        db.execute(
          """
            INSERT INTO SparkSetCoins (setId, coinId)
            VALUES (?, ?);
          """,
          [setId, coinId],
        );
      }

      db.execute("COMMIT;");
      _debugLog(
        "$_updateAnonSetCount _updateSparkAnonSetCoinsWith() COMMITTED",
      );
      _debugLog(
        "$_updateAnonSetCount _updateSparkAnonSetCoinsWith() duration"
        " = ${DateTime.now().difference(start)}",
      );
      return true;
    } catch (e, s) {
      db.execute("ROLLBACK;");
      _debugLog("$_updateAnonSetCount _updateSparkAnonSetCoinsWith() ROLLBACK");
      _debugLog(
        "$_updateAnonSetCount _updateSparkAnonSetCoinsWith()"
        " duration = ${DateTime.now().difference(start)}",
      );
      // NOTE THIS LOGGER MUST BE CALLED ON MAIN ISOLATE FOR NOW
      Logging.instance.log(
        "$e\n$s",
        level: LogLevel.Error,
      );
    }

    return false;
  }
}
