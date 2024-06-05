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
part 'firo_cache_writer.dart';
part 'firo_cache_worker.dart';

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

  static Future<void> _deleteAllCache() async {
    final start = DateTime.now();
    db.execute(
      """
        DELETE FROM SparkSet;
        DELETE FROM SparkCoin;
        DELETE FROM SparkSetCoins;
        DELETE FROM SparkUsedCoinTags;
        VACUUM;
      """,
    );
    _debugLog(
      "_deleteAllCache() "
      "duration = ${DateTime.now().difference(start)}",
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
}
