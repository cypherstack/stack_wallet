part of 'firo_cache.dart';

/// Keep all fetch queries in this separate file
abstract class _Reader {
  // ===========================================================================
  // =============== Spark anonymity set queries ===============================
  //
  // All anon-set reads filter `ss.complete = 1` so in-flight syncs cannot
  // leak partial coin sets to callers. This is especially load-bearing for
  // libspark membership-proof construction: a spend initiated while a sync
  // is running must not see half-populated SparkSetCoins.
  //
  // Coin ordering is reconstructed via `orderKey DESC`. The writer stores
  // orderKey = server-side delta index (0 = newest). Sorting DESC within a
  // set, then Dart-reversing in the coordinator, yields server newest-first
  // order end-to-end — matching the pre-fix behavior. The `ssc.id ASC`
  // tiebreaker preserves pre-migration rows (where all orderKey == 0): the
  // old writer inserted coins in globally-reversed RPC order, so PK-ASC is
  // oldest-first, which Dart's `.reversed` flips back to newest-first.

  static Future<ResultSet> _getSetCoinsForGroupId(
    int groupId, {
    required Database db,
  }) async {
    final query =
        """
      SELECT sc.serialized, sc.txHash, sc.context, sc.groupId
      FROM SparkSet AS ss
      JOIN SparkSetCoins AS ssc ON ss.id = ssc.setId
      JOIN SparkCoin AS sc ON ssc.coinId = sc.id
      WHERE ss.groupId = $groupId AND ss.complete = 1
      ORDER BY ss.id ASC, ssc.orderKey DESC, ssc.id ASC;
    """;

    return db.select("$query;");
  }

  static Future<ResultSet> _getLatestSetInfoForGroupId(
    int groupId, {
    required Database db,
  }) async {
    final query =
        """
      SELECT ss.blockHash, ss.setHash, ss.size
      FROM SparkSet ss
      WHERE ss.groupId = $groupId AND ss.complete = 1
      ORDER BY ss.size DESC, ss.id DESC
      LIMIT 1;
    """;

    return db.select("$query;");
  }

  static Future<ResultSet> _getSetCoinsAndLatestSetInfoForGroupId(
    int groupId, {
    required Database db,
  }) async {
    const query = """
      WITH LatestSet AS (
        SELECT blockHash, setHash, size
        FROM SparkSet
        WHERE groupId = ? AND complete = 1
        ORDER BY size DESC, id DESC
        LIMIT 1
      )
      SELECT
        LatestSet.blockHash,
        LatestSet.setHash,
        LatestSet.size,
        sc.serialized,
        sc.txHash,
        sc.context,
        sc.groupId
      FROM LatestSet
      JOIN SparkSet AS ss ON ss.groupId = ? AND ss.complete = 1
      JOIN SparkSetCoins AS ssc ON ss.id = ssc.setId
      JOIN SparkCoin AS sc ON ssc.coinId = sc.id
      ORDER BY ss.id ASC, ssc.orderKey DESC, ssc.id ASC;
    """;

    return db.select("$query;", [groupId, groupId]);
  }

  static Future<ResultSet> _getSetCoinsForGroupIdAndBlockHash(
    int groupId,
    String blockHash, {
    required Database db,
  }) async {
    const query = """
        WITH TargetBlock AS (
          SELECT id
          FROM SparkSet
          WHERE blockHash = ? AND groupId = ? AND complete = 1
          ORDER BY id DESC
          LIMIT 1
        ),
        TargetSets AS (
          SELECT id AS setId
          FROM SparkSet
          WHERE groupId = ?
            AND complete = 1
            AND (
              NOT EXISTS (SELECT 1 FROM TargetBlock)
              OR id > (SELECT id FROM TargetBlock)
            )
        )
        SELECT
          SparkCoin.serialized,
          SparkCoin.txHash,
          SparkCoin.context,
          SparkCoin.groupId
        FROM SparkSetCoins
        JOIN SparkCoin ON SparkSetCoins.coinId = SparkCoin.id
        WHERE SparkSetCoins.setId IN (SELECT setId FROM TargetSets)
        ORDER BY SparkSetCoins.setId ASC,
                 SparkSetCoins.orderKey DESC,
                 SparkSetCoins.id ASC;
    """;

    return db.select("$query;", [blockHash, groupId, groupId]);
  }

  static Future<bool> _checkSetInfoForGroupIdExists(
    int groupId, {
    required Database db,
  }) async {
    final query =
        """
      SELECT EXISTS (
        SELECT 1
        FROM SparkSet
        WHERE groupId = $groupId AND complete = 1
      ) AS setExists;
    """;

    return db.select("$query;").first["setExists"] == 1;
  }

  /// In-progress (complete=0) SparkSet row for this group, if any. Used by
  /// the coordinator's resume logic to decide whether to continue a partial
  /// sync or discard it.
  ///
  /// In normal flow only one incomplete row can exist per group at a time.
  /// If several exist, the coordinator treats the state as ambiguous and
  /// restarts the in-flight cache.
  static Future<ResultSet> _getIncompleteSetForGroupId(
    int groupId, {
    required Database db,
  }) async {
    final query =
        """
      SELECT id, blockHash, setHash, size
      FROM SparkSet
      WHERE groupId = $groupId AND complete = 0
      ORDER BY id DESC;
    """;
    return db.select("$query;");
  }

  /// Count of coins currently linked to the given SparkSet. Used by the
  /// coordinator to compute the resume cursor.
  static Future<int> _countSetCoins(int setId, {required Database db}) async {
    final rows = db.select(
      "SELECT COUNT(*) AS c FROM SparkSetCoins WHERE setId = ?;",
      [setId],
    );
    return rows.first["c"] as int;
  }

  // ===========================================================================
  // =============== Spark used coin tags queries ==============================

  static Future<ResultSet> _getSparkUsedCoinTags(
    int startNumber, {
    required Database db,
  }) async {
    String query = """
      SELECT tag
      FROM SparkUsedCoinTags
    """;

    if (startNumber > 0) {
      query += " WHERE id >= $startNumber";
    }

    return db.select("$query;");
  }

  static Future<ResultSet> _getUsedCoinTagsCount({required Database db}) async {
    const query = """
      SELECT COUNT(*) AS count
      FROM SparkUsedCoinTags;
    """;

    return db.select("$query;");
  }

  static Future<ResultSet> _getUsedCoinTxidsFor(
    List<String> tags, {
    required Database db,
  }) async {
    final tagsConcat = tags.join("', '");

    final query =
        """
      SELECT tag, GROUP_CONCAT(txid) AS txids
      FROM SparkUsedCoinTags
      WHERE tag IN ('$tagsConcat')
      GROUP BY tag;
    """;

    return db.select("$query;");
  }

  static Future<ResultSet> _getUsedCoinTagsFor(
    String txid, {
    required Database db,
  }) async {
    final query =
        """
      SELECT tag
      FROM SparkUsedCoinTags
      WHERE txid = '$txid';
    """;

    return db.select("$query;");
  }

  static Future<bool> _checkTagIsUsed(
    String tag, {
    required Database db,
  }) async {
    final query =
        """
      SELECT EXISTS (
        SELECT 1
        FROM SparkUsedCoinTags
        WHERE tag = '$tag'
      ) AS tagExists;
    """;

    return db.select("$query;").first["tagExists"] == 1;
  }
}
