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
FCResult _updateSparkUsedTagsWith(
  Database db,
  List<List<dynamic>> tags,
) {
  // hash the tags here since this function is called in a background isolate
  final hashedTags = LibSpark.hashTags(
    base64Tags: tags.map((e) => e[0] as String).toSet(),
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
// ================== write to spark anon set Meta cache ==========================
FCResult _updateSparkAnonSetMetaWith(
  Database db,
  SparkAnonymitySetMeta meta,
) {
  db.execute("BEGIN;");
  try {
    db.execute(
      """
        INSERT OR REPLACE INTO PreviousMetaFetchResult (coinGroupId, blockHash, setHash, size)
        VALUES (?, ?, ?, ?);
      """,
      [meta.coinGroupId, meta.blockHash, meta.setHash, meta.size],
    );

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
FCResult _updateSparkAnonSetCoinsWith(
  Database db,
  Map<String, dynamic> json,
  int groupId,
) {
  final blockHash = json["blockHash"] as String;
  final setHash = json["setHash"] as String;
  final coinsRaw = json["coins"] as List;

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
    [
      blockHash,
      setHash,
      groupId,
    ],
  );

  if (checkResult.isNotEmpty) {
    // already up to date
    return FCResult(success: true);
  }

  final coins = coinsRaw
      .map(
        (e) => [
          e[0] as String,
          e[1] as String,
          e[2] as String,
        ],
      )
      .toList()
      .reversed;

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

    return FCResult(success: true);
  } catch (e) {
    db.execute("ROLLBACK;");
    return FCResult(success: false, error: e);
  }
}
