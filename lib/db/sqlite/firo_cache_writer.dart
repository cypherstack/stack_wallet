part of 'firo_cache.dart';

class FCResult {
  final bool success;
  final Object? error;

  FCResult({required this.success, this.error});
}

// ===========================================================================
// ================== write to spark used tags cache =========================

/// update the sqlite cache
/// Expected json format:
/// returns true if successful, otherwise some exception
FCResult _updateSparkUsedTagsWith(Database db, List<List<dynamic>> tags) {
  // hash the tags here since this function is called in a background isolate
  final hashedTags = hashTags(
    base64Tags: tags.map((e) => e[0] as String).toList(),
  ).toList();
  if (hashedTags.isEmpty) {
    // nothing to add, return early
    return FCResult(success: true);
  }

  db.execute("BEGIN;");
  try {
    for (int i = 0; i < hashedTags.length; i++) {
      db.execute(
        """
          INSERT OR IGNORE INTO SparkUsedCoinTags (tag, txid)
          VALUES (?, ?);
        """,
        [hashedTags[i], (tags[i][1] as String).toHexReversedFromBase64],
      );
    }

    db.execute("COMMIT;");

    return FCResult(success: true);
  } catch (e) {
    db.execute("ROLLBACK;");
    return FCResult(success: false, error: e);
  }
}

// ===========================================================================
// ================== write to spark anon set cache ==========================

/// update the sqlite cache
///
/// returns true if successful, otherwise false
FCResult _updateSparkAnonSetCoinsWith(
  Database db,
  final List<RawSparkCoin> coinsRaw,
  SparkAnonymitySetMeta meta,
) {
  if (coinsRaw.isEmpty) {
    // no coins to actually insert
    return FCResult(success: true);
  }

  final checkResult = db.select(
    """
      SELECT *
      FROM SparkSet
      WHERE blockHash = ? AND setHash = ? AND groupId = ?;
    """,
    [meta.blockHash, meta.setHash, meta.coinGroupId],
  );

  if (checkResult.isNotEmpty) {
    // already up to date
    return FCResult(success: true);
  }

  final coins = coinsRaw.reversed;

  db.execute("BEGIN;");
  try {
    db.execute(
      """
        INSERT INTO SparkSet (blockHash, setHash, groupId, size)
        VALUES (?, ?, ?, ?);
      """,
      [meta.blockHash, meta.setHash, meta.coinGroupId, meta.size],
    );
    final setId = db.lastInsertRowId;

    for (final coin in coins) {
      db.execute(
        """
            INSERT OR IGNORE INTO SparkCoin (serialized, txHash, context, groupId)
            VALUES (?, ?, ?, ?);
          """,
        [coin.serialized, coin.txHash, coin.context, coin.groupId],
      );
      final coinIdResult = db.select(
        """
          SELECT id
          FROM SparkCoin
          WHERE serialized = ? AND txHash = ? AND context = ? AND groupId = ?
          LIMIT 1;
        """,
        [coin.serialized, coin.txHash, coin.context, coin.groupId],
      );
      if (coinIdResult.isEmpty) {
        throw Exception(
          "Failed to resolve SparkCoin id after insert/ignore operation",
        );
      }
      final coinId = coinIdResult.first["id"] as int;

      // finally add the row id to the newly added set
      final hasSetCoin = db.select(
        """
          SELECT 1
          FROM SparkSetCoins
          WHERE setId = ? AND coinId = ?
          LIMIT 1;
        """,
        [setId, coinId],
      );
      if (hasSetCoin.isEmpty) {
        db.execute(
          """
            INSERT INTO SparkSetCoins (setId, coinId)
            VALUES (?, ?);
          """,
          [setId, coinId],
        );
      }
    }

    db.execute("COMMIT;");

    return FCResult(success: true);
  } catch (e) {
    db.execute("ROLLBACK;");
    return FCResult(success: false, error: e);
  }
}
