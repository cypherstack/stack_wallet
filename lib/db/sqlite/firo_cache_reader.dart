part of 'firo_cache.dart';

/// Keep all fetch queries in this separate file
abstract class _Reader {
  // ===========================================================================
  // =============== Spark anonymity set queries ===============================

  static Future<ResultSet> _getSetCoinsForGroupId(
    int groupId, {
    required Database db,
  }) async {
    final query = """
      SELECT sc.serialized, sc.txHash, sc.context, sc.groupId
      FROM SparkSet AS ss
      JOIN SparkSetCoins AS ssc ON ss.id = ssc.setId
      JOIN SparkCoin AS sc ON ssc.coinId = sc.id
      WHERE ss.groupId = $groupId;
    """;

    return db.select("$query;");
  }

  static Future<ResultSet> _getLatestSetInfoForGroupId(
    int groupId, {
    required Database db,
  }) async {
    final query = """
      SELECT ss.blockHash, ss.setHash, ss.size
      FROM SparkSet ss
      WHERE ss.groupId = $groupId
      ORDER BY ss.size DESC
      LIMIT 1;
    """;

    return db.select("$query;");
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
          WHERE blockHash = ?
        ),
        TargetSets AS (
          SELECT id AS setId
          FROM SparkSet
          WHERE groupId = ? AND id > (SELECT id FROM TargetBlock)
        )
        SELECT 
          SparkCoin.serialized,
          SparkCoin.txHash,
          SparkCoin.context,
          SparkCoin.groupId
        FROM SparkSetCoins
        JOIN SparkCoin ON SparkSetCoins.coinId = SparkCoin.id
        WHERE SparkSetCoins.setId IN (SELECT setId FROM TargetSets);
    """;

    return db.select("$query;", [blockHash, groupId]);
  }

  static Future<bool> _checkSetInfoForGroupIdExists(
    int groupId, {
    required Database db,
  }) async {
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

  static Future<ResultSet> _getUsedCoinTagsCount({
    required Database db,
  }) async {
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

    final query = """
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
    final query = """
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
    final query = """
      SELECT EXISTS (
        SELECT 1
        FROM SparkUsedCoinTags
        WHERE tag = '$tag'
      ) AS tagExists;
    """;

    return db.select("$query;").first["tagExists"] == 1;
  }
}
