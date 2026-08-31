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

/// Persist a single sector of a resumable Spark anon-set sync.
///
/// The sector tuple carries `(meta, coins, firstOrderKey)`:
///   - `meta` identifies the SparkSet row this sector contributes to. On
///     first sector for a sync the row is created with `complete = 0`;
///     subsequent sectors find the existing row via INSERT OR IGNORE.
///   - `coins` is the server's newest-first response for this sector.
///   - `firstOrderKey` is the server-side delta index of `coins[0]`
///     (equivalent to the `startIndex` of the `getSparkAnonymitySetBySector`
///     request that produced the sector). Successive coins get
///     `firstOrderKey + i`.
///
/// The row stays invisible to readers (`complete = 0`) until
/// [_markSparkAnonSetComplete] flips the flag. Each sector runs in its own
/// SQLite transaction, so a crash at any point leaves the cache consistent
/// with the last sector that committed. Replay is safe because:
///   - SparkSet: INSERT OR IGNORE against UNIQUE(blockHash, setHash, groupId).
///   - SparkCoin: INSERT OR IGNORE against UNIQUE(serialized, txHash, context,
///     groupId).
///   - SparkSetCoins: INSERT OR IGNORE against UNIQUE(setId, coinId).
FCResult _insertSparkAnonSetCoinsIncremental(
  Database db,
  (SparkAnonymitySetMeta, List<RawSparkCoin>, int) sector,
) {
  final (meta, coinsRaw, firstOrderKey) = sector;

  if (coinsRaw.isEmpty) {
    return FCResult(success: true);
  }

  db.execute("BEGIN;");
  try {
    // Create (or find) the in-progress SparkSet row. size is locked to
    // meta.size at creation; we never UPDATE it per-sector. The row
    // represents "the anon-set meta the coordinator is targeting" — it
    // becomes visible to readers only after complete is flipped to 1.
    db.execute(
      """
        INSERT OR IGNORE INTO SparkSet
        (blockHash, setHash, groupId, size, complete)
        VALUES (?, ?, ?, ?, 0);
      """,
      [meta.blockHash, meta.setHash, meta.coinGroupId, meta.size],
    );
    final setIdRow = db.select(
      """
        SELECT id, complete FROM SparkSet
        WHERE blockHash = ? AND setHash = ? AND groupId = ?;
      """,
      [meta.blockHash, meta.setHash, meta.coinGroupId],
    );
    if (setIdRow.isEmpty) {
      throw StateError(
        "Failed to locate SparkSet row after INSERT OR IGNORE for "
        "groupId=${meta.coinGroupId}",
      );
    }
    final setId = setIdRow.first["id"] as int;
    final existingComplete = (setIdRow.first["complete"] as int) == 1;
    // Defensive: if the target row is already marked complete, the
    // coordinator either has a bug or the server is reporting
    // inconsistent state for (blockHash, setHash). Either way, appending
    // would corrupt a set whose setHash we've committed to. Refuse.
    if (existingComplete) {
      throw StateError(
        "Refusing to append coins to already-finalized SparkSet "
        "setId=$setId (groupId=${meta.coinGroupId}, "
        "blockHash=${meta.blockHash}, setHash=${meta.setHash}).",
      );
    }

    for (int i = 0; i < coinsRaw.length; i++) {
      final coin = coinsRaw[i];

      // Defensive: a mixed-group sector would skew the per-set coin count
      // and break the finalize-time integrity check.
      if (coin.groupId != meta.coinGroupId) {
        throw StateError(
          "Spark anon set sector coin groupId mismatch: "
          "expected ${meta.coinGroupId}, got ${coin.groupId}",
        );
      }

      db.execute(
        """
          INSERT OR IGNORE INTO SparkCoin (serialized, txHash, context, groupId)
          VALUES (?, ?, ?, ?);
        """,
        [coin.serialized, coin.txHash, coin.context, coin.groupId],
      );
      // lastInsertRowId is 0 when INSERT OR IGNORE skipped a duplicate, so
      // always SELECT the id explicitly rather than relying on it.
      final coinIdRow = db.select(
        """
          SELECT id FROM SparkCoin
          WHERE serialized = ? AND txHash = ? AND context = ? AND groupId = ?;
        """,
        [coin.serialized, coin.txHash, coin.context, coin.groupId],
      );
      if (coinIdRow.isEmpty) {
        throw StateError(
          "Failed to locate SparkCoin row after INSERT OR IGNORE "
          "(groupId=${meta.coinGroupId})",
        );
      }
      final coinId = coinIdRow.first["id"] as int;

      // orderKey = server-side delta index. Used by the reader's ORDER BY
      // to emit coins in the same newest-first order as the server.
      final orderKey = firstOrderKey + i;

      db.execute(
        """
          INSERT OR IGNORE INTO SparkSetCoins (setId, coinId, orderKey)
          VALUES (?, ?, ?);
        """,
        [setId, coinId, orderKey],
      );
    }

    db.execute("COMMIT;");
    return FCResult(success: true);
  } catch (e) {
    db.execute("ROLLBACK;");
    return FCResult(success: false, error: e);
  }
}

/// Finalize a resumable sync by flipping the SparkSet row's `complete` flag
/// to 1, gated on a strict integrity check.
///
/// The `(meta, expectedLinkedCount)` tuple carries:
///   - `meta`: identifies the row to finalize.
///   - `expectedLinkedCount`: the number of coins the coordinator believes
///     it appended for this sync. For first-sync of a group this is
///     meta.size; for an incremental sync it is meta.size minus the
///     previously-finalized size for this group.
///
/// If the actual linked count in SparkSetCoins does not match the expected
/// value the transaction rolls back and the row stays `complete = 0`.
/// Coordinator's next sync will observe the over-linked row and reset it.
/// A partial, over-full, or corrupted cache therefore never becomes the
/// current set.
FCResult _markSparkAnonSetComplete(
  Database db,
  (SparkAnonymitySetMeta, int) payload,
) {
  final (meta, expectedLinkedCount) = payload;

  db.execute("BEGIN;");
  try {
    final setIdRow = db.select(
      """
        SELECT id, complete FROM SparkSet
        WHERE blockHash = ? AND setHash = ? AND groupId = ?;
      """,
      [meta.blockHash, meta.setHash, meta.coinGroupId],
    );
    if (setIdRow.isEmpty) {
      // No row to finalize. Only reachable for the empty-delta edge case
      // (blockHash advanced without new coins), and the coordinator already
      // handles that case without calling us. Return success so an
      // accidental call is an idempotent no-op rather than an error.
      db.execute("ROLLBACK;");
      return FCResult(success: true);
    }
    final setId = setIdRow.first["id"] as int;
    final alreadyComplete = (setIdRow.first["complete"] as int) == 1;

    if (alreadyComplete) {
      // Idempotent replay: the row was finalized in a prior call.
      db.execute("COMMIT;");
      return FCResult(success: true);
    }

    final linkedRow = db.select(
      """
        SELECT COUNT(*) AS c FROM SparkSetCoins WHERE setId = ?;
      """,
      [setId],
    );
    final linked = linkedRow.first["c"] as int;
    if (linked != expectedLinkedCount) {
      db.execute("ROLLBACK;");
      return FCResult(
        success: false,
        error: StateError(
          "Cannot finalize SparkSet setId=$setId "
          "(groupId=${meta.coinGroupId}): linked $linked coins "
          "but expected $expectedLinkedCount",
        ),
      );
    }

    db.execute("UPDATE SparkSet SET complete = 1 WHERE id = ?;", [setId]);

    db.execute("COMMIT;");
    return FCResult(success: true);
  } catch (e) {
    db.execute("ROLLBACK;");
    return FCResult(success: false, error: e);
  }
}

/// Delete every incomplete SparkSet row (and its SparkSetCoins links) for
/// this group. Used when:
///   * The server's blockHash has shifted between resume attempts — at the
///     new blockHash, the partial row's orderKeys no longer align with
///     server indices.
///   * The in-progress row's linked count somehow exceeds the expected
///     delta (corruption guard).
///   * An empty-delta sync needs to clear a stray partial before returning.
///
/// Finalized rows (`complete = 1`) are never touched.
FCResult _deleteIncompleteSparkSetsForGroup(Database db, int groupId) {
  db.execute("BEGIN;");
  try {
    db.execute(
      """
        DELETE FROM SparkSetCoins
        WHERE setId IN (
          SELECT id FROM SparkSet WHERE groupId = ? AND complete = 0
        );
      """,
      [groupId],
    );
    db.execute(
      """
        DELETE FROM SparkCoin
        WHERE groupId = ?
          AND id NOT IN (SELECT coinId FROM SparkSetCoins);
      """,
      [groupId],
    );
    db.execute("DELETE FROM SparkSet WHERE groupId = ? AND complete = 0;", [
      groupId,
    ]);
    db.execute("COMMIT;");
    return FCResult(success: true);
  } catch (e) {
    db.execute("ROLLBACK;");
    return FCResult(success: false, error: e);
  }
}
