import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../electrumx_rpc/electrumx_client.dart';
import '../../utilities/logger.dart';
import '../../utilities/stack_file_system.dart';

/// Temporary debugging log function for this file
void _debugLog(Object? object) {
  if (kDebugMode) {
    Logging.instance.log(
      object,
      level: LogLevel.Fatal,
    );
  }
}

/// Wrapper class for [FiroCache] as [FiroCache] should eventually be handled in a
/// background isolate and [FiroCacheCoordinator] should manage that isolate
abstract class FiroCacheCoordinator {
  static Future<void> init() => _FiroCache.init();

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
      startBlockHash: blockHash,
    );

    await _FiroCache._updateWith(json, groupId);
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
            timestampUTC INTEGER NOT NULL,
            setId INTEGER NOT NULL,
            coinId INTEGER NOT NULL,
            FOREIGN KEY (setId) REFERENCES SparkSet(id),
            FOREIGN KEY (coinId) REFERENCES SparkCoin(id)
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
      SELECT sc.id, sc.serialized, sc.txHash, sc.context
      FROM SparkSetCoins AS ssc
      JOIN SparkSet AS ss ON ssc.setId = ss.id
      JOIN SparkCoin AS sc ON ssc.coinId = sc.id
      WHERE ss.groupId = $groupId
    """;

    if (newerThanTimeStamp != null) {
      query += " AND ssc.timestampUTC"
          " > $newerThanTimeStamp";
    }

    return db.select("$query;");
  }

  static Future<ResultSet> _getLatestSetInfoForGroupId(
    int groupId,
  ) async {
    final query = """
      SELECT ss.blockHash, ss.setHash, ssc.timestampUTC
      FROM SparkSet ss
      JOIN SparkSetCoins ssc ON ss.id = ssc.setId
      WHERE ss.groupId = $groupId
      ORDER BY ssc.timestampUTC DESC
      LIMIT 1;
    """;

    return db.select("$query;");
  }

  // ===========================================================================
  // ===========================================================================

  static int _upCount = 0;

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
  static Future<bool> _updateWith(
    Map<String, dynamic> json,
    int groupId,
  ) async {
    final start = DateTime.now();
    _upCount++;
    final blockHash = json["blockHash"] as String;
    final setHash = json["setHash"] as String;

    _debugLog(
      "$_upCount _updateWith() called where groupId=$groupId,"
      " blockHash=$blockHash, setHash=$setHash",
    );

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

    _debugLog("$_upCount _updateWith() called where checkResult=$checkResult");

    if (checkResult.isNotEmpty) {
      _debugLog(
        "$_upCount _updateWith() duration = ${DateTime.now().difference(start)}",
      );
      // already up to date
      return true;
    }

    if ((json["coins"] as List).isEmpty) {
      _debugLog("$_upCount _updateWith() called where json[coins] is Empty");
      _debugLog(
        "$_upCount _updateWith() duration = ${DateTime.now().difference(start)}",
      );
      // no coins to actually insert
      return true;
    }

    final coins = (json["coins"] as List)
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
          INSERT INTO SparkSet (blockHash, setHash, groupId)
          VALUES (?, ?, ?);
        """,
        [blockHash, setHash, groupId],
      );
      final setId = db.lastInsertRowId;

      for (final coin in coins) {
        int coinId;
        try {
          db.execute(
            """
              INSERT INTO SparkCoin (serialized, txHash, context)
              VALUES (?, ?, ?);
            """,
            coin,
          );
          coinId = db.lastInsertRowId;
        } on SqliteException catch (e) {
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

        db.execute(
          """
            INSERT INTO SparkSetCoins (timestampUTC, setId, coinId)
            VALUES (?, ?, ?);
          """,
          [timestamp, setId, coinId],
        );
      }

      db.execute("COMMIT;");
      _debugLog("$_upCount _updateWith() COMMITTED");
      _debugLog(
        "$_upCount _updateWith() duration = ${DateTime.now().difference(start)}",
      );
      return true;
    } catch (e, s) {
      db.execute("ROLLBACK;");
      _debugLog("$_upCount _updateWith() ROLLBACK");
      _debugLog(
        "$_upCount _updateWith() duration = ${DateTime.now().difference(start)}",
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
