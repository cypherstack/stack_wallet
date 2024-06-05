import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_libsparkmobile/flutter_libsparkmobile.dart';
import 'package:mutex/mutex.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

import '../../electrumx_rpc/electrumx_client.dart';
import '../../utilities/extensions/extensions.dart';
import '../../utilities/logger.dart';
import '../../utilities/stack_file_system.dart';

part 'firo_cache_coordinator.dart';
part 'firo_cache_reader.dart';
part 'firo_cache_worker.dart';
part 'firo_cache_writer.dart';

/// Temporary debugging log function for this file
void _debugLog(Object? object) {
  if (kDebugMode) {
    Logging.instance.log(
      object,
      level: LogLevel.Debug,
    );
  }
}

abstract class _FiroCache {
  static const int _setCacheVersion = 1;
  static const int _tagsCacheVersion = 1;
  static const String sparkSetCacheFileName =
      "spark_set_v$_setCacheVersion.sqlite3";
  static const String sparkUsedTagsCacheFileName =
      "spark_tags_v$_tagsCacheVersion.sqlite3";

  static Database? _setCacheDB;
  static Database? _usedTagsCacheDB;
  static Database get setCacheDB {
    if (_setCacheDB == null) {
      throw Exception(
        "FiroCache.init() must be called before accessing FiroCache.db!",
      );
    }
    return _setCacheDB!;
  }

  static Database get usedTagsCacheDB {
    if (_usedTagsCacheDB == null) {
      throw Exception(
        "FiroCache.init() must be called before accessing FiroCache.db!",
      );
    }
    return _usedTagsCacheDB!;
  }

  static Future<void>? _initFuture;
  static Future<void> init() => _initFuture ??= _init();

  static Future<void> _init() async {
    final sqliteDir =
        await StackFileSystem.applicationFiroCacheSQLiteDirectory();

    final sparkSetCacheFile = File("${sqliteDir.path}/$sparkSetCacheFileName");
    final sparkUsedTagsCacheFile =
        File("${sqliteDir.path}/$sparkUsedTagsCacheFileName");

    if (!(await sparkSetCacheFile.exists())) {
      await _createSparkSetCacheDb(sparkSetCacheFile.path);
    }
    if (!(await sparkUsedTagsCacheFile.exists())) {
      await _createSparkUsedTagsCacheDb(sparkUsedTagsCacheFile.path);
    }

    _setCacheDB = sqlite3.open(
      sparkSetCacheFile.path,
      mode: OpenMode.readWrite,
    );
    _usedTagsCacheDB = sqlite3.open(
      sparkUsedTagsCacheFile.path,
      mode: OpenMode.readWrite,
    );
  }

  static Future<void> _deleteAllCache() async {
    final start = DateTime.now();
    setCacheDB.execute(
      """
        DELETE FROM SparkSet;
        DELETE FROM SparkCoin;
        DELETE FROM SparkSetCoins;
        VACUUM;
      """,
    );
    usedTagsCacheDB.execute(
      """
        DELETE FROM SparkUsedCoinTags;
        VACUUM;
      """,
    );
    _debugLog(
      "_deleteAllCache() "
      "duration = ${DateTime.now().difference(start)}",
    );
  }

  static Future<void> _createSparkSetCacheDb(String file) async {
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
      """,
    );

    db.dispose();
  }

  static Future<void> _createSparkUsedTagsCacheDb(String file) async {
    final db = sqlite3.open(
      file,
      mode: OpenMode.readWriteCreate,
    );

    db.execute(
      """
        CREATE TABLE SparkUsedCoinTags (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
          tag TEXT NOT NULL UNIQUE
        );
      """,
    );

    db.dispose();
  }
}
