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
// =========== incremental write to spark anon set cache ====================

/// Persist a single sector's worth of coins to the cache, creating or
/// updating the SparkSet row as needed. Safe to call repeatedly — uses
/// INSERT OR IGNORE so duplicate coins (from crash-recovery reruns) are
/// silently skipped.
///
/// [cumulativeSize] should be prevSize + total coins saved so far (including
/// this batch). It is written to SparkSet.size so that on resume,
/// getLatestSetInfoForGroupId returns the correct partial progress.
FCResult _insertSparkAnonSetCoinsIncremental(
  Database db,
  final List<RawSparkCoin> coinsRaw,
  SparkAnonymitySetMeta meta,
  int cumulativeSize,
) {
  if (coinsRaw.isEmpty) {
    return FCResult(success: true);
  }

  final coins = coinsRaw.reversed;

  db.execute("BEGIN;");
  try {
    // Create SparkSet row if it doesn't exist yet for this block state.
    // complete = 0 marks this as an in-progress download.
    db.execute(
      """
        INSERT OR IGNORE INTO SparkSet (blockHash, setHash, groupId, size, complete)
        VALUES (?, ?, ?, 0, 0);
      """,
      [meta.blockHash, meta.setHash, meta.coinGroupId],
    );

    // Get the SparkSet row's id (whether just created or already existing).
    final setIdResult = db.select(
      """
        SELECT id FROM SparkSet
        WHERE blockHash = ? AND setHash = ? AND groupId = ?;
      """,
      [meta.blockHash, meta.setHash, meta.coinGroupId],
    );
    final setId = setIdResult.first["id"] as int;

    for (final coin in coins) {
      // INSERT OR IGNORE handles duplicates from crash-recovery reruns.
      db.execute(
        """
          INSERT OR IGNORE INTO SparkCoin (serialized, txHash, context, groupId)
          VALUES (?, ?, ?, ?);
        """,
        [coin.serialized, coin.txHash, coin.context, coin.groupId],
      );

      // lastInsertRowId is 0 when INSERT OR IGNORE skips a duplicate,
      // so we must SELECT explicitly.
      final coinIdResult = db.select(
        """
          SELECT id FROM SparkCoin
          WHERE serialized = ? AND txHash = ? AND context = ? AND groupId = ?;
        """,
        [coin.serialized, coin.txHash, coin.context, coin.groupId],
      );
      final coinId = coinIdResult.first["id"] as int;

      db.execute(
        """
          INSERT OR IGNORE INTO SparkSetCoins (setId, coinId)
          VALUES (?, ?);
        """,
        [setId, coinId],
      );
    }

    // Update cumulative size to track partial progress.
    db.execute(
      """
        UPDATE SparkSet SET size = ?
        WHERE id = ?;
      """,
      [cumulativeSize, setId],
    );

    db.execute("COMMIT;");

    return FCResult(success: true);
  } catch (e) {
    db.execute("ROLLBACK;");
    return FCResult(success: false, error: e);
  }
}

/// Mark a SparkSet row as complete after all sectors have been downloaded.
FCResult _markSparkAnonSetComplete(
  Database db,
  SparkAnonymitySetMeta meta,
) {
  db.execute(
    """
      UPDATE SparkSet SET complete = 1
      WHERE blockHash = ? AND setHash = ? AND groupId = ?;
    """,
    [meta.blockHash, meta.setHash, meta.coinGroupId],
  );
  return FCResult(success: true);
}
