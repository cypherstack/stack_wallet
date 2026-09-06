import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:mutex/mutex.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

import '../../electrumx_rpc/electrumx_client.dart';
import '../../models/electrumx_response/spark_models.dart';
import '../../utilities/extensions/extensions.dart';
import '../../utilities/logger.dart';
import '../../utilities/stack_file_system.dart';
import '../../wallets/crypto_currency/crypto_currency.dart';
import '../../wl_gen/interfaces/lib_spark_interface.dart';

part 'firo_cache_coordinator.dart';
part 'firo_cache_reader.dart';
part 'firo_cache_worker.dart';
part 'firo_cache_writer.dart';

abstract class _FiroCache {
  static const int _setCacheVersion = 2;
  static const int _tagsCacheVersion = 2;

  static final networks = [
    CryptoCurrencyNetwork.main,
    CryptoCurrencyNetwork.test,
  ];

  static String sparkSetCacheFileName(CryptoCurrencyNetwork network) =>
      network == CryptoCurrencyNetwork.main
      ? "spark_set_v$_setCacheVersion.sqlite3"
      : "spark_set_v${_setCacheVersion}_${network.name}.sqlite3";
  static String sparkUsedTagsCacheFileName(CryptoCurrencyNetwork network) =>
      network == CryptoCurrencyNetwork.main
      ? "spark_tags_v$_tagsCacheVersion.sqlite3"
      : "spark_tags_v${_tagsCacheVersion}_${network.name}.sqlite3";

  static final Map<CryptoCurrencyNetwork, Database> _setCacheDB = {};
  static final Map<CryptoCurrencyNetwork, Database> _usedTagsCacheDB = {};
  static Database setCacheDB(CryptoCurrencyNetwork network) {
    if (_setCacheDB[network] == null) {
      throw Exception(
        "FiroCache.init() must be called before accessing FiroCache.db!",
      );
    }
    return _setCacheDB[network]!;
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
      final sparkSetCacheFile = File(
        "${sqliteDir.path}/${sparkSetCacheFileName(network)}",
      );

      final sparkUsedTagsCacheFile = File(
        "${sqliteDir.path}/${sparkUsedTagsCacheFileName(network)}",
      );

      if (!(await sparkSetCacheFile.exists())) {
        await _createSparkSetCacheDb(sparkSetCacheFile.path);
      }
      if (!(await sparkUsedTagsCacheFile.exists())) {
        await _createSparkUsedTagsCacheDb(sparkUsedTagsCacheFile.path);
      }

      _setCacheDB[network] = sqlite3.open(
        sparkSetCacheFile.path,
        mode: OpenMode.readWrite,
      );
      _usedTagsCacheDB[network] = sqlite3.open(
        sparkUsedTagsCacheFile.path,
        mode: OpenMode.readWrite,
      );

      _configureDb(_setCacheDB[network]!);
      _configureDb(_usedTagsCacheDB[network]!);
      _migrateSparkSetCacheDb(_setCacheDB[network]!);
    }
  }

  static void _configureDb(Database db) {
    db.select("PRAGMA journal_mode = WAL;");
    db.execute("PRAGMA busy_timeout = 5000;");
    db.execute("PRAGMA foreign_keys = ON;");
  }

  /// Idempotent migration for Spark anon-set cache databases. Runs on every
  /// open. Safe to invoke repeatedly: each step is gated on a presence
  /// check so subsequent startups are no-ops.
  ///
  /// Migrations:
  ///
  ///   1. SparkSet.complete (ADD COLUMN, DEFAULT 1): 0 while a sync is in
  ///      flight, 1 once every sector has committed and the finalize-time
  ///      integrity check has passed. Readers filter on this; partial
  ///      state is invisible. Existing rows are assumed complete — the
  ///      pre-fix writer was all-or-nothing so any row in a legacy DB
  ///      represents a successfully-finalized sync.
  ///
  ///   2. SparkSetCoins.orderKey (ADD COLUMN, DEFAULT 0): the server-side
  ///      delta index of the coin this link-row references. Used by the
  ///      reader's ORDER BY to reconstruct server newest-first order
  ///      end-to-end. Pre-migration rows default to 0; the reader's
  ///      `ssc.id ASC` tiebreaker then sorts them in PK order, which is
  ///      exactly the layout the pre-fix writer produced (it inserted
  ///      coins in globally-reversed RPC order, so PK-ASC = oldest-first,
  ///      and the coordinator's Dart `.reversed` flips to newest-first).
  ///
  ///   3. UNIQUE INDEX idx_sparksetcoins_set_coin ON SparkSetCoins(setId,
  ///      coinId): required for INSERT OR IGNORE on the link table during
  ///      resumable per-sector writes (idempotent under crash-recovery
  ///      replay). Before creating it, any pre-existing duplicate
  ///      (setId, coinId) rows are removed — keeping the lowest PK — so
  ///      a legacy DB with unexpected duplicates can still upgrade. The
  ///      pre-fix writer shouldn't have produced duplicates (its INSERT
  ///      was not OR IGNORE and would have thrown on collision), but
  ///      scrubbing once is cheaper than failing to open the DB.
  ///
  /// Column and index presence are checked explicitly rather than wrapped
  /// in try/catch, so unrelated SQLite errors don't get silently swallowed.
  static void _migrateSparkSetCacheDb(Database db) {
    if (!_columnExists(db, "SparkSet", "complete")) {
      db.execute("""
          ALTER TABLE SparkSet
          ADD COLUMN complete INTEGER NOT NULL DEFAULT 1;
        """);
    }
    if (!_columnExists(db, "SparkSetCoins", "orderKey")) {
      db.execute("""
          ALTER TABLE SparkSetCoins
          ADD COLUMN orderKey INTEGER NOT NULL DEFAULT 0;
        """);
    }
    if (!_indexExists(db, "idx_sparksetcoins_set_coin")) {
      // Defensive: drop any pre-existing duplicate (setId, coinId) rows
      // before the index creation would fail on them. On a clean legacy
      // DB this DELETE matches zero rows.
      db.execute("""
          DELETE FROM SparkSetCoins
          WHERE id NOT IN (
            SELECT MIN(id) FROM SparkSetCoins
            GROUP BY setId, coinId
          );
        """);
      db.execute("""
          CREATE UNIQUE INDEX idx_sparksetcoins_set_coin
          ON SparkSetCoins(setId, coinId);
        """);
    }
  }

  static bool _columnExists(Database db, String table, String column) {
    final rows = db.select("PRAGMA table_info($table);");
    return rows.any((row) => row["name"] == column);
  }

  static bool _indexExists(Database db, String indexName) {
    final rows = db.select(
      "SELECT 1 FROM sqlite_master WHERE type = 'index' AND name = ?;",
      [indexName],
    );
    return rows.isNotEmpty;
  }

  static Future<void> _deleteAllCache(CryptoCurrencyNetwork network) async {
    final start = DateTime.now();
    setCacheDB(network).execute("""
        DELETE FROM SparkSetCoins;
        DELETE FROM SparkSet;
        DELETE FROM SparkCoin;
        VACUUM;
      """);
    await _deleteUsedTagsCache(network);

    Logging.instance.d(
      "_deleteAllCache() "
      "duration = ${DateTime.now().difference(start)}",
    );
  }

  static Future<void> _deleteUsedTagsCache(
    CryptoCurrencyNetwork network,
  ) async {
    final start = DateTime.now();

    usedTagsCacheDB(network).execute("""
        DELETE FROM SparkUsedCoinTags;
        VACUUM;
      """);

    Logging.instance.d(
      "_deleteUsedTagsCache() "
      "duration = ${DateTime.now().difference(start)}",
    );
  }

  static Future<void> _createSparkSetCacheDb(String file) async {
    final db = sqlite3.open(file, mode: OpenMode.readWriteCreate);
    _configureDb(db);

    db.execute("""
        CREATE TABLE SparkSet (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
          blockHash TEXT NOT NULL,
          setHash TEXT NOT NULL,
          groupId INTEGER NOT NULL,
          size INTEGER NOT NULL,
          complete INTEGER NOT NULL DEFAULT 1,
          UNIQUE (blockHash, setHash, groupId)
        );

        CREATE TABLE SparkCoin (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
          serialized TEXT NOT NULL,
          txHash TEXT NOT NULL,
          context TEXT NOT NULL,
          groupId INTEGER NOT NULL,
          UNIQUE(serialized, txHash, context, groupId)
        );

        CREATE TABLE SparkSetCoins (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
          setId INTEGER NOT NULL,
          coinId INTEGER NOT NULL,
          orderKey INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (setId) REFERENCES SparkSet(id),
          FOREIGN KEY (coinId) REFERENCES SparkCoin(id)
        );

        CREATE UNIQUE INDEX idx_sparksetcoins_set_coin
        ON SparkSetCoins(setId, coinId);
      """);

    db.dispose();
  }

  static Future<void> _createSparkUsedTagsCacheDb(String file) async {
    final db = sqlite3.open(file, mode: OpenMode.readWriteCreate);
    _configureDb(db);

    db.execute("""
        CREATE TABLE SparkUsedCoinTags (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
          tag TEXT NOT NULL UNIQUE,
          txid TEXT NOT NULL
        );
      """);

    db.dispose();
  }
}
