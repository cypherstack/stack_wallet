part of 'firo_cache.dart';

typedef LTagPair = ({String tag, String txid});

/// The cache was reset while this refresh was running. Its caller must stop
/// the old batch, rather than start the next sector against the new cache.
class FiroCacheResetException implements Exception {
  const FiroCacheResetException();
  @override
  String toString() => 'Firo cache update invalidated by reset';
}

class _CacheEpoch {
  _CacheEpoch(this.number);
  final int number;
  bool _cancelled = false;
  final _cancellation = StreamController<void>.broadcast(sync: true);

  void check() {
    if (_cancelled) throw const FiroCacheResetException();
  }

  void invalidate() {
    _cancelled = true;
    _cancellation.add(null);
    unawaited(_cancellation.close());
  }

  Future<T> wait<T>(Future<T> pending) async {
    final result = Completer<T>();
    void cancel() {
      if (!result.isCompleted) {
        result.completeError(const FiroCacheResetException());
      }
    }

    final subscription = _cancellation.stream.listen((_) => cancel());
    unawaited(
      pending.then(
        (value) {
          if (!result.isCompleted) result.complete(value);
        },
        onError: (Object error, StackTrace stack) {
          if (!result.isCompleted) result.completeError(error, stack);
        },
      ),
    );
    if (_cancelled) cancel();
    try {
      return await result.future;
    } finally {
      await subscription.cancel();
    }
  }
}

/// Coordinates network fetches and serialized cache writes per Firo network.
abstract class FiroCacheCoordinator {
  static final Map<CryptoCurrencyNetwork, _FiroCacheWorker> _workers = {};
  static final Map<CryptoCurrencyNetwork, Mutex> _tagLocks = {};
  static final Map<CryptoCurrencyNetwork, Mutex> _setLocks = {};
  static final Map<CryptoCurrencyNetwork, Mutex> _resetLocks = {};
  static final Map<CryptoCurrencyNetwork, _CacheEpoch> _setEpochs = {};
  static final Map<CryptoCurrencyNetwork, _CacheEpoch> _tagEpochs = {};
  static final Map<CryptoCurrencyNetwork, Future<void>> _resets = {};
  static final Map<CryptoCurrencyNetwork, Object> _resetErrors = {};
  static bool _closing = false;

  static Future<void>? _initFuture;
  static Future<void> init() => _initFuture ??= _initialize();

  static Future<void> _initialize() async {
    await _FiroCache.init();
    for (final network in _FiroCache.networks) {
      _tagLocks[network] = Mutex();
      _setLocks[network] = Mutex();
      _resetLocks[network] = Mutex();
      _setEpochs[network] = _CacheEpoch(0);
      _tagEpochs[network] = _CacheEpoch(0);
      _workers[network] = await _FiroCacheWorker.spawn(network);
    }
  }

  /// Terminal shutdown for a desktop reset, followed by process exit.
  static Future<void> close() async {
    _closing = true;
    for (final epochs in [_setEpochs, _tagEpochs]) {
      for (final network in epochs.keys.toList()) {
        _invalidate(epochs, network);
      }
    }
    // Reset work is local only. Even if a reset failed, close every handle.
    await Future.wait(
      _resets.values.toList().map((reset) => reset.catchError((Object _) {})),
    );
    await Future.wait(_workers.values.map((worker) => worker.close()));
    for (final db in [
      ..._FiroCache._setCacheDB.values,
      ..._FiroCache._usedTagsCacheDB.values,
    ]) {
      db.close();
    }
  }

  @visibleForTesting
  static String usedTagsCacheFileName(CryptoCurrencyNetwork network) =>
      _FiroCache.sparkUsedTagsCacheFileName(network);

  static Future<void> clearSharedCache(
    CryptoCurrencyNetwork network, {
    bool clearOnlyUsedTagsCache = false,
  }) async {
    if (_closing) throw StateError('Firo cache is closing');
    if (!_workers.containsKey(network)) {
      throw StateError('Firo cache is not initialized for $network');
    }
    _invalidate(_tagEpochs, network);
    if (!clearOnlyUsedTagsCache) _invalidate(_setEpochs, network);
    final reset = _resetLocks[network]!.protect(() async {
      try {
        await _reset(network, clearSets: !clearOnlyUsedTagsCache);
      } catch (error) {
        _resetErrors[network] = error;
        rethrow;
      }
    });
    late final Future<void> finished;
    finished = reset.whenComplete(() {
      if (identical(_resets[network], finished)) _resets.remove(network);
    });
    _resets[network] = finished;
    return finished;
  }

  static void _invalidate(
    Map<CryptoCurrencyNetwork, _CacheEpoch> epochs,
    CryptoCurrencyNetwork network,
  ) {
    final previous = epochs[network]!;
    previous.invalidate();
    epochs[network] = _CacheEpoch(previous.number + 1);
  }

  static Future<void> _ready(CryptoCurrencyNetwork network) async {
    while (_resets[network] != null) {
      await _resets[network];
    }
    if (_closing) throw StateError('Firo cache is closing');
    if (_resetErrors[network] != null) {
      // Retry the failed local reset before serving reads, so one filesystem
      // error does not disable the cache for the rest of the session.
      await clearSharedCache(network, clearOnlyUsedTagsCache: true);
    }
  }

  static Future<void> _reset(
    CryptoCurrencyNetwork network, {
    required bool clearSets,
  }) async {
    final dir = await StackFileSystem.applicationFiroCacheSQLiteDirectory();
    final marker = File('${dir.path}/${_FiroCache.resetMarkerName(network)}');
    // Preserve an earlier interrupted full reset when retrying a tags reset.
    final resetSets =
        clearSets ||
        (await marker.exists() &&
            (await marker.readAsString()).trim() != 'tags-v1');
    if (resetSets && !clearSets) _invalidate(_setEpochs, network);
    await marker.writeAsString(resetSets ? 'all-v1' : 'tags-v1', flush: true);
    if (resetSets) _FiroCache._setCacheDB.remove(network)?.close();
    _FiroCache._usedTagsCacheDB.remove(network)?.close();
    await _workers[network]!.runTask(
      FCTask(
        func: FCFuncName._reset,
        data: (
          resetSets,
          _setEpochs[network]!.number,
          _tagEpochs[network]!.number,
        ),
      ),
    );
    if (resetSets) {
      _FiroCache._setCacheDB[network] = sqlite3.open(
        '${dir.path}/${_FiroCache.sparkSetCacheFileName(network)}',
        mode: OpenMode.readWrite,
      );
    }
    _FiroCache._usedTagsCacheDB[network] = sqlite3.open(
      '${dir.path}/${_FiroCache.sparkUsedTagsCacheFileName(network)}',
      mode: OpenMode.readWrite,
    );
    await marker.delete();
    _resetErrors.remove(network);
  }

  static Future<String> getSparkCacheSize(CryptoCurrencyNetwork network) async {
    await _ready(network);
    final dir = await StackFileSystem.applicationFiroCacheSQLiteDirectory();
    final setCacheFile = File(
      "${dir.path}/${_FiroCache.sparkSetCacheFileName(network)}",
    );
    final usedTagsCacheFile = File(
      "${dir.path}/${_FiroCache.sparkUsedTagsCacheFileName(network)}",
    );

    final setSize = (await setCacheFile.exists())
        ? await setCacheFile.length()
        : 0;
    final tagsSize = (await usedTagsCacheFile.exists())
        ? await usedTagsCacheFile.length()
        : 0;

    Logging.instance.d("Spark cache used tags size: $tagsSize");
    Logging.instance.d("Spark cache anon set size: $setSize");

    final int bytes = tagsSize + setSize;

    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1048576) {
      final double kbSize = bytes / 1024;
      return '${kbSize.toStringAsFixed(2)} KB';
    } else if (bytes < 1073741824) {
      final double mbSize = bytes / 1048576;
      return '${mbSize.toStringAsFixed(2)} MB';
    } else {
      final double gbSize = bytes / 1073741824;
      return '${gbSize.toStringAsFixed(2)} GB';
    }
  }

  static Future<void> runFetchAndUpdateSparkUsedCoinTags(
    ElectrumXClient client,
    CryptoCurrencyNetwork network,
  ) async {
    final epoch = _tagEpochs[network]!;
    await _tagLocks[network]!.protect(() async {
      epoch.check();
      final count = await FiroCacheCoordinator.getUsedCoinTagsCount(network);
      epoch.check();
      final unhashedTags = await epoch.wait(
        client.getSparkUnhashedUsedCoinsTagsWithTxHashes(startNumber: count),
      );
      epoch.check();
      if (unhashedTags.isNotEmpty) {
        await _workers[network]!.runTask(
          FCTask(
            func: FCFuncName._updateSparkUsedTagsWith,
            data: unhashedTags,
            generation: epoch.number,
          ),
        );
        epoch.check();
      }
    });
  }

  static Future<void> runFetchAndUpdateSparkAnonSetCacheForGroupId(
    int groupId,
    ElectrumXClient client,
    CryptoCurrencyNetwork network,
    void Function(int countFetched, int totalCount)? progressUpdated,
  ) async {
    final epoch = _setEpochs[network]!;
    await _setLocks[network]!.protect(() async {
      epoch.check();
      const sectorSize = 1500; // chosen as a somewhat decent value. Could be changed in the future if wanted/needed
      final prevMeta = await FiroCacheCoordinator.getLatestSetInfoForGroupId(
        groupId,
        network,
      );

      epoch.check();

      final prevSize = prevMeta?.size ?? 0;

      final meta = await epoch.wait(
        client.getSparkAnonymitySetMeta(coinGroupId: groupId),
      );
      epoch.check();

      progressUpdated?.call(prevSize, meta.size);

      if (prevMeta?.blockHash == meta.blockHash) {
        Logging.instance.d("prevMeta?.blockHash == meta.blockHash");
        return;
      }

      final numberOfCoinsToFetch = meta.size - prevSize;

      final fullSectorCount = numberOfCoinsToFetch ~/ sectorSize;
      final remainder = numberOfCoinsToFetch % sectorSize;

      final List<dynamic> coins = [];

      for (int i = 0; i < fullSectorCount; i++) {
        final start = (i * sectorSize);
        final data = await epoch.wait(
          client.getSparkAnonymitySetBySector(
            coinGroupId: groupId,
            latestBlock: meta.blockHash,
            startIndex: start,
            endIndex: start + sectorSize,
          ),
        );
        epoch.check();
        progressUpdated?.call(start + sectorSize, numberOfCoinsToFetch);

        coins.addAll(data);
      }

      if (remainder > 0) {
        final data = await epoch.wait(
          client.getSparkAnonymitySetBySector(
            coinGroupId: groupId,
            latestBlock: meta.blockHash,
            startIndex: numberOfCoinsToFetch - remainder,
            endIndex: numberOfCoinsToFetch,
          ),
        );
        epoch.check();
        progressUpdated?.call(numberOfCoinsToFetch, numberOfCoinsToFetch);

        coins.addAll(data);
      }

      final result = coins
          .map((e) => RawSparkCoin.fromRPCResponse(e as List, groupId))
          .toList();

      await _workers[network]!.runTask(
        FCTask(
          func: FCFuncName._updateSparkAnonSetCoinsWith,
          data: (meta, result),
          generation: epoch.number,
        ),
      );
      epoch.check();
    });
  }

  // ===========================================================================

  static Future<List<String>> getUsedCoinTags(
    int startNumber,
    CryptoCurrencyNetwork network,
  ) async {
    await _ready(network);
    final result = await _Reader._getSparkUsedCoinTags(
      startNumber,
      db: _FiroCache.usedTagsCacheDB(network),
    );
    return result.map((e) => e["tag"] as String).toList();
  }

  static Future<int> getUsedCoinTagsCount(CryptoCurrencyNetwork network) async {
    await _ready(network);
    final result = await _Reader._getUsedCoinTagsCount(
      db: _FiroCache.usedTagsCacheDB(network),
    );
    if (result.isEmpty) {
      return 0;
    }
    return result.first["count"] as int? ?? 0;
  }

  static Future<List<LTagPair>> getUsedCoinTxidsFor({
    required List<String> tags,
    required CryptoCurrencyNetwork network,
  }) async {
    await _ready(network);
    if (tags.isEmpty) {
      return [];
    }
    final result = await _Reader._getUsedCoinTxidsFor(
      tags,
      db: _FiroCache.usedTagsCacheDB(network),
    );

    if (result.isEmpty) {
      return [];
    }
    return result.rows
        .map((e) => (tag: e[0] as String, txid: e[1] as String))
        .toList();
  }

  static Future<List<String>> getUsedCoinTagsFor({
    required String txid,
    required CryptoCurrencyNetwork network,
  }) async {
    await _ready(network);
    final result = await _Reader._getUsedCoinTagsFor(
      txid,
      db: _FiroCache.usedTagsCacheDB(network),
    );
    return result.map((e) => e["tag"] as String).toList();
  }

  static Future<bool> checkTagIsUsed(
    String tag,
    CryptoCurrencyNetwork network,
  ) async {
    await _ready(network);
    return await _Reader._checkTagIsUsed(
      tag,
      db: _FiroCache.usedTagsCacheDB(network),
    );
  }

  static Future<List<RawSparkCoin>> getSetCoinsForGroupId(
    int groupId, {
    String? afterBlockHash,
    required CryptoCurrencyNetwork network,
  }) async {
    await _ready(network);
    final resultSet = afterBlockHash == null
        ? await _Reader._getSetCoinsForGroupId(
            groupId,
            db: _FiroCache.setCacheDB(network),
          )
        : await _Reader._getSetCoinsForGroupIdAndBlockHash(
            groupId,
            afterBlockHash,
            db: _FiroCache.setCacheDB(network),
          );

    return resultSet
        .map(
          (row) => RawSparkCoin(
            serialized: row["serialized"] as String,
            txHash: row["txHash"] as String,
            context: row["context"] as String,
            groupId: groupId,
          ),
        )
        .toList()
        .reversed
        .toList();
  }

  static Future<SparkAnonymitySetMeta?> getLatestSetInfoForGroupId(
    int groupId,
    CryptoCurrencyNetwork network,
  ) async {
    await _ready(network);
    final result = await _Reader._getLatestSetInfoForGroupId(
      groupId,
      db: _FiroCache.setCacheDB(network),
    );

    if (result.isEmpty) {
      return null;
    }

    return SparkAnonymitySetMeta(
      coinGroupId: groupId,
      blockHash: result.first["blockHash"] as String,
      setHash: result.first["setHash"] as String,
      size: result.first["size"] as int,
    );
  }

  static Future<bool> checkSetInfoForGroupIdExists(
    int groupId,
    CryptoCurrencyNetwork network,
  ) async {
    await _ready(network);
    return await _Reader._checkSetInfoForGroupIdExists(
      groupId,
      db: _FiroCache.setCacheDB(network),
    );
  }
}
