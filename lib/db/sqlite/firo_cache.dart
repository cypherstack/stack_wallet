import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_libsparkmobile/flutter_libsparkmobile.dart';
import 'package:mutex/mutex.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

import '../../electrumx_rpc/electrumx_client.dart';
import '../../models/electrumx_response/spark_models.dart';
import '../../utilities/extensions/extensions.dart';
import '../../utilities/logger.dart';
import '../../utilities/stack_file_system.dart';
import '../../wallets/crypto_currency/crypto_currency.dart';

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
  static const int _tagsCacheVersion = 2;

  static final networks = [
    CryptoCurrencyNetwork.main,
    CryptoCurrencyNetwork.test,
  ];

  static String sparkSetCacheFileName(CryptoCurrencyNetwork network) =>
      network == CryptoCurrencyNetwork.main
          ? "spark_set_v$_setCacheVersion.sqlite3"
          : "spark_set_v${_setCacheVersion}_${network.name}.sqlite3";
  static String sparkSetMetaCacheFileName(CryptoCurrencyNetwork network) =>
      network == CryptoCurrencyNetwork.main
          ? "spark_set_meta_v$_setCacheVersion.sqlite3"
          : "spark_set_meta_v${_setCacheVersion}_${network.name}.sqlite3";
  static String sparkUsedTagsCacheFileName(CryptoCurrencyNetwork network) =>
      network == CryptoCurrencyNetwork.main
          ? "spark_tags_v$_tagsCacheVersion.sqlite3"
          : "spark_tags_v${_tagsCacheVersion}_${network.name}.sqlite3";

  static final Map<CryptoCurrencyNetwork, Database> _setCacheDB = {};
  static final Map<CryptoCurrencyNetwork, Database> _setMetaCacheDB = {};
  static final Map<CryptoCurrencyNetwork, Database> _usedTagsCacheDB = {};
  static Database setCacheDB(CryptoCurrencyNetwork network) {
    if (_setCacheDB[network] == null) {
      throw Exception(
        "FiroCache.init() must be called before accessing FiroCache.db!",
      );
    }
    return _setCacheDB[network]!;
  }

  static Database setMetaCacheDB(CryptoCurrencyNetwork network) {
    if (_setMetaCacheDB[network] == null) {
      throw Exception(
        "FiroCache.init() must be called before accessing FiroCache.db!",
      );
    }
    return _setMetaCacheDB[network]!;
  }

  static Database usedTagsCacheDB(CryptoCurrencyNetwork network) {
    if (_usedTagsCacheDB[network] == null) {
      throw Exception(
        "FiroCache.init() must be called before accessing FiroCache.db!",
      );
    }
    return _usedTagsCacheDB[network]!;
  }

  static Future<void>? _initFuture;
  static Future<void> init() => _initFuture ??= _init();

  static Future<void> _init() async {
    final sqliteDir =
        await StackFileSystem.applicationFiroCacheSQLiteDirectory();

    for (final network in networks) {
      final sparkSetCacheFile =
          File("${sqliteDir.path}/${sparkSetCacheFileName(network)}");

      final sparkSetMetaCacheFile =
          File("${sqliteDir.path}/${sparkSetMetaCacheFileName(network)}");

      final sparkUsedTagsCacheFile =
          File("${sqliteDir.path}/${sparkUsedTagsCacheFileName(network)}");

      if (!(await sparkSetCacheFile.exists())) {
        await _createSparkSetCacheDb(sparkSetCacheFile.path);
      }
      if (!(await sparkSetMetaCacheFile.exists())) {
        await _createSparkSetMetaCacheDb(sparkSetMetaCacheFile.path);
      }
      if (!(await sparkUsedTagsCacheFile.exists())) {
        await _createSparkUsedTagsCacheDb(sparkUsedTagsCacheFile.path);
      }

      _setCacheDB[network] = sqlite3.open(
        sparkSetCacheFile.path,
        mode: OpenMode.readWrite,
      );
      _setMetaCacheDB[network] = sqlite3.open(
        sparkSetMetaCacheFile.path,
        mode: OpenMode.readWrite,
      );
      _usedTagsCacheDB[network] = sqlite3.open(
        sparkUsedTagsCacheFile.path,
        mode: OpenMode.readWrite,
      );
    }
  }

  static Future<void> _deleteAllCache(CryptoCurrencyNetwork network) async {
    final start = DateTime.now();
    setCacheDB(network).execute(
      """
        DELETE FROM SparkSet;
        DELETE FROM SparkCoin;
        DELETE FROM SparkSetCoins;
        VACUUM;
      """,
    );
    setMetaCacheDB(network).execute(
      """
        DELETE FROM PreviousMetaFetchResult;
        VACUUM;
      """,
    );
    usedTagsCacheDB(network).execute(
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

  static Future<void> _createSparkSetMetaCacheDb(String file) async {
    final db = sqlite3.open(
      file,
      mode: OpenMode.readWriteCreate,
    );

    db.execute(
      """
        CREATE TABLE PreviousMetaFetchResult (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
          coinGroupId INTEGER NOT NULL UNIQUE,
          blockHash TEXT NOT NULL,
          setHash TEXT NOT NULL,
          size INTEGER NOT NULL
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
          tag TEXT NOT NULL UNIQUE,
          txid TEXT NOT NULL
        );
      """,
    );

    db.dispose();
  }
}
