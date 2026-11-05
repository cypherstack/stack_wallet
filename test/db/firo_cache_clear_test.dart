import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:stackwallet/db/sqlite/firo_cache.dart';
import 'package:stackwallet/electrumx_rpc/electrumx_client.dart';
import 'package:stackwallet/models/electrumx_response/spark_models.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

class _TagsClient extends Mock implements ElectrumXClient {
  final started = Completer<void>();
  final response = Completer<List<List<dynamic>>>();
  @override
  Future<List<List<dynamic>>> getSparkUnhashedUsedCoinsTagsWithTxHashes({
    String? requestID,
    required int startNumber,
  }) {
    started.complete();
    return response.future;
  }
}

class _SetClient extends Mock implements ElectrumXClient {
  final started = Completer<void>();
  final response = Completer<SparkAnonymitySetMeta>();
  final sectorStarted = Completer<void>();
  final sectorResponse = Completer<List<dynamic>>();
  @override
  Future<SparkAnonymitySetMeta> getSparkAnonymitySetMeta({
    String? requestID,
    required int coinGroupId,
  }) {
    started.complete();
    return response.future;
  }

  @override
  Future<List<dynamic>> getSparkAnonymitySetBySector({
    String? requestID,
    required int coinGroupId,
    required String latestBlock,
    required int startIndex,
    required int endIndex,
  }) {
    sectorStarted.complete();
    return sectorResponse.future;
  }

  void releaseMeta({int size = 1}) => response.complete(
    SparkAnonymitySetMeta(
      coinGroupId: 1,
      blockHash: 'block',
      setHash: 'set',
      size: size,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late Directory cache;
  const network = CryptoCurrencyNetwork.main;
  const other = CryptoCurrencyNetwork.test;
  setUpAll(() async {
    root = await Directory.systemTemp.createTemp('firo-immediate-clear-');
    StackFileSystem.setDesktopOverrideDir(root.path);
    await FiroCacheCoordinator.init();
    cache = await StackFileSystem.applicationFiroCacheSQLiteDirectory();
  });
  tearDownAll(() async {
    await FiroCacheCoordinator.close();
    await root.delete(recursive: true);
  });
  setUp(() => FiroCacheCoordinator.clearSharedCache(network));

  Future<void> cancelled(Future<void> fetch) =>
      expectLater(fetch, throwsA(isA<FiroCacheResetException>()));
  Future<void> empty() async {
    expect(await FiroCacheCoordinator.getUsedCoinTagsCount(network), 0);
    expect(
      await FiroCacheCoordinator.getLatestSetInfoForGroupId(1, network),
      isNull,
    );
    expect(
      await FiroCacheCoordinator.getSetCoinsForGroupId(1, network: network),
      isEmpty,
    );
  }

  test('tags reset completes while its RPC never completes', () async {
    final db = sqlite3.open(
      '${cache.path}/${FiroCacheCoordinator.usedTagsCacheFileName(network)}',
    );
    db.execute(
      "INSERT INTO SparkUsedCoinTags (tag, txid) VALUES ('old', 'txid');",
    );
    db.close();
    final client = _TagsClient();
    final fetch = FiroCacheCoordinator.runFetchAndUpdateSparkUsedCoinTags(
      client,
      network,
    );
    final stopped = cancelled(fetch);
    await client.started.future;
    await FiroCacheCoordinator.clearSharedCache(
      network,
      clearOnlyUsedTagsCache: true,
    ).timeout(const Duration(seconds: 3));
    await stopped;
    expect(client.response.isCompleted, isFalse);
    await empty();
    client.response.completeError(StateError('late network failure'));
    await Future<void>.delayed(Duration.zero);
    await empty();
  });

  test(
    'full reset cancels a stalled metadata fetch and queued old batch',
    () async {
      final client = _SetClient();
      final first =
          FiroCacheCoordinator.runFetchAndUpdateSparkAnonSetCacheForGroupId(
            1,
            client,
            network,
            null,
          );
      final stopped = cancelled(first);
      await client.started.future;
      final queuedClient = _SetClient();
      final queued =
          FiroCacheCoordinator.runFetchAndUpdateSparkAnonSetCacheForGroupId(
            1,
            queuedClient,
            network,
            null,
          );
      final queuedStopped = cancelled(queued);
      await FiroCacheCoordinator.clearSharedCache(network)
          .timeout(const Duration(seconds: 3));
      await Future.wait([stopped, queuedStopped]);
      expect(client.response.isCompleted, isFalse);
      expect(queuedClient.started.isCompleted, isFalse);
      client.releaseMeta();
      await Future<void>.delayed(Duration.zero);
      expect(client.sectorStarted.isCompleted, isFalse);
      await empty();
    },
  );

  test('a late sector cannot repopulate the reset cache', () async {
    final client = _SetClient();
    final fetch =
        FiroCacheCoordinator.runFetchAndUpdateSparkAnonSetCacheForGroupId(
          1,
          client,
          network,
          null,
        );
    final stopped = cancelled(fetch);
    await client.started.future;
    client.releaseMeta();
    await client.sectorStarted.future;
    await FiroCacheCoordinator.clearSharedCache(network)
        .timeout(const Duration(seconds: 3));
    await stopped;
    client.sectorResponse.complete([
      ['serialized', 'tx', 'context'],
    ]);
    await Future<void>.delayed(Duration.zero);
    await empty();
  });

  test(
    'reset orders deletion after an already submitted worker write',
    () async {
      final client = _SetClient();
      final fetch =
          FiroCacheCoordinator.runFetchAndUpdateSparkAnonSetCacheForGroupId(
            1,
            client,
            network,
            null,
          );
      // It may complete before reset, or be invalidated during its local write.
      final observed = fetch.onError<FiroCacheResetException>((_, __) {});
      await client.started.future;
      client.releaseMeta();
      await client.sectorStarted.future;
      client.sectorResponse.complete([
        ['serialized', 'tx', 'context'],
      ]);
      await Future<void>.delayed(Duration.zero);
      await FiroCacheCoordinator.clearSharedCache(network);
      await observed;
      await empty();
    },
  );

  test(
    'tags-only reset preserves sets, including an active set fetch',
    () async {
      final client = _SetClient();
      final fetch =
          FiroCacheCoordinator.runFetchAndUpdateSparkAnonSetCacheForGroupId(
            1,
            client,
            network,
            null,
          );
      await client.started.future;
      await FiroCacheCoordinator.clearSharedCache(
        network,
        clearOnlyUsedTagsCache: true,
      );
      client.releaseMeta();
      await client.sectorStarted.future;
      client.sectorResponse.complete([
        ['serialized', 'tx', 'context'],
      ]);
      await fetch;
      expect(
        await FiroCacheCoordinator.getSetCoinsForGroupId(1, network: network),
        hasLength(1),
      );
      await FiroCacheCoordinator.clearSharedCache(
        network,
        clearOnlyUsedTagsCache: true,
      );
      expect(
        await FiroCacheCoordinator.getSetCoinsForGroupId(1, network: network),
        hasLength(1),
      );
    },
  );

  test('a new fetch starts while the retired RPC remains unresolved', () async {
    final old = _SetClient();
    final oldFetch =
        FiroCacheCoordinator.runFetchAndUpdateSparkAnonSetCacheForGroupId(
          1,
          old,
          network,
          null,
        );
    final stopped = cancelled(oldFetch);
    await old.started.future;
    await FiroCacheCoordinator.clearSharedCache(network);
    await stopped;
    final fresh = _SetClient();
    final freshFetch =
        FiroCacheCoordinator.runFetchAndUpdateSparkAnonSetCacheForGroupId(
          1,
          fresh,
          network,
          null,
        );
    await fresh.started.future.timeout(const Duration(seconds: 3));
    fresh.releaseMeta();
    await fresh.sectorStarted.future;
    fresh.sectorResponse.complete([
      ['fresh', 'tx', 'context'],
    ]);
    await freshFetch;
    expect(old.response.isCompleted, isFalse);
    expect(
      (await FiroCacheCoordinator.getSetCoinsForGroupId(
        1,
        network: network,
      )).single.serialized,
      'fresh',
    );
  });

  test('reset of one network does not cancel another network update', () async {
    final client = _SetClient();
    final fetch =
        FiroCacheCoordinator.runFetchAndUpdateSparkAnonSetCacheForGroupId(
          1,
          client,
          other,
          null,
        );
    await client.started.future;
    await FiroCacheCoordinator.clearSharedCache(network);
    client.releaseMeta();
    await client.sectorStarted.future;
    client.sectorResponse.complete([
      ['testnet', 'tx', 'context'],
    ]);
    await fetch;
    expect(
      await FiroCacheCoordinator.getSetCoinsForGroupId(1, network: other),
      hasLength(1),
    );
    await FiroCacheCoordinator.clearSharedCache(other);
  });

  test('a failed local reset is retried by the next read', () async {
    final db = sqlite3.open(
      '${cache.path}/${FiroCacheCoordinator.usedTagsCacheFileName(network)}',
    );
    db.execute(
      "INSERT INTO SparkUsedCoinTags (tag, txid) VALUES ('old', 'txid');",
    );
    db.close();
    final obstruction = Directory('${cache.path}/spark_reset_main.pending');
    await obstruction.create();
    await expectLater(
      FiroCacheCoordinator.clearSharedCache(
        network,
        clearOnlyUsedTagsCache: true,
      ),
      throwsA(isA<FileSystemException>()),
    );
    // Reads retry the reset rather than serve the stale row; it still fails.
    await expectLater(
      FiroCacheCoordinator.getUsedCoinTagsCount(network),
      throwsA(isA<FileSystemException>()),
    );
    await obstruction.delete();
    // The next read completes the reset by itself.
    expect(await FiroCacheCoordinator.getUsedCoinTagsCount(network), 0);
  });

  test(
    'full reset recovery retains its scope and restores set writes',
    () async {
      final db = sqlite3.open('${cache.path}/spark_set_v2.sqlite3');
      db.execute('''
        INSERT INTO SparkSet (blockHash, setHash, groupId, size)
        VALUES ('old', 'old', 1, 0);
      ''');
      db.close();
      final obstruction = Directory('${cache.path}/spark_reset_main.pending');
      await obstruction.create();
      try {
        await expectLater(
          FiroCacheCoordinator.clearSharedCache(network),
          throwsA(isA<FileSystemException>()),
        );
        await expectLater(
          FiroCacheCoordinator.getUsedCoinTagsCount(network),
          throwsA(isA<FileSystemException>()),
        );
      } finally {
        await obstruction.delete();
      }

      // A read must recover the full reset, including removal of the old set.
      await empty();
      final client = _SetClient();
      final fetch =
          FiroCacheCoordinator.runFetchAndUpdateSparkAnonSetCacheForGroupId(
            1,
            client,
            network,
            null,
          );
      await client.started.future;
      client.releaseMeta();
      await client.sectorStarted.future;
      client.sectorResponse.complete([
        ['fresh', 'tx', 'context'],
      ]);
      await fetch;

      // Successful recovery must also retire the remembered full-reset intent.
      await FiroCacheCoordinator.clearSharedCache(
        network,
        clearOnlyUsedTagsCache: true,
      );
      expect(
        (await FiroCacheCoordinator.getSetCoinsForGroupId(
          1,
          network: network,
        )).single.serialized,
        'fresh',
      );
    },
  );

  test(
    'a checkpoint from before a full reset reads the whole new set',
    () async {
      final db = sqlite3.open('${cache.path}/spark_set_v2.sqlite3');
      db.execute('''
      INSERT INTO SparkSet (blockHash, setHash, groupId, size)
      VALUES ('old', 'old', 1, 1);
      INSERT INTO SparkCoin (serialized, txHash, context, groupId)
      VALUES ('known', 'tx', 'context', 1);
      INSERT INTO SparkSetCoins (setId, coinId) VALUES (1, 1);
    ''');
      db.close();
      // Nothing newer than the checkpoint exists yet.
      expect(
        await FiroCacheCoordinator.getSetCoinsForGroupId(
          1,
          afterBlockHash: 'old',
          network: network,
        ),
        isEmpty,
      );

      await FiroCacheCoordinator.clearSharedCache(network);
      final client = _SetClient();
      final fetch =
          FiroCacheCoordinator.runFetchAndUpdateSparkAnonSetCacheForGroupId(
            1,
            client,
            network,
            null,
          );
      await client.started.future;
      client.releaseMeta(size: 2);
      await client.sectorStarted.future;
      client.sectorResponse.complete([
        ['known', 'tx', 'context'],
        ['received', 'tx2', 'context'],
      ]);
      await fetch;

      // The rebuilt cache no longer holds the wallet's checkpoint hash. The
      // wallet advances its checkpoint after this read, so it must see every
      // coin rather than none.
      final coins = await FiroCacheCoordinator.getSetCoinsForGroupId(
        1,
        afterBlockHash: 'old',
        network: network,
      );
      expect(
        coins.map((e) => e.serialized),
        unorderedEquals(['known', 'received']),
      );
      // A checkpoint the cache does know still reads incrementally.
      expect(
        await FiroCacheCoordinator.getSetCoinsForGroupId(
          1,
          afterBlockHash: 'block',
          network: network,
        ),
        isEmpty,
      );
    },
  );

  test('a checkpoint hash stored under another group is ignored', () async {
    final db = sqlite3.open('${cache.path}/spark_set_v2.sqlite3');
    db.execute('''
      INSERT INTO SparkSet (blockHash, setHash, groupId, size)
      VALUES ('new', 'new', 1, 1), ('old', 'old', 2, 1);
      INSERT INTO SparkCoin (serialized, txHash, context, groupId)
      VALUES ('received', 'tx', 'context', 1), ('other', 'tx2', 'context', 2);
      INSERT INTO SparkSetCoins (setId, coinId) VALUES (1, 1), (2, 2);
    ''');
    db.close();
    // Group 1 no longer holds the wallet's checkpoint hash. Another group
    // holding that hash must not set the cutoff for group 1.
    final coins = await FiroCacheCoordinator.getSetCoinsForGroupId(
      1,
      afterBlockHash: 'old',
      network: network,
    );
    expect(coins.map((e) => e.serialized), ['received']);
    expect(
      await FiroCacheCoordinator.getSetCoinsForGroupId(
        2,
        afterBlockHash: 'old',
        network: network,
      ),
      isEmpty,
    );
  });

  test(
    'concurrent reset requests finish with readable empty databases',
    () async {
      await Future.wait([
        FiroCacheCoordinator.clearSharedCache(network),
        FiroCacheCoordinator.clearSharedCache(
          network,
          clearOnlyUsedTagsCache: true,
        ),
        FiroCacheCoordinator.clearSharedCache(network),
      ]);
      await empty();
      expect(
        await File('${cache.path}/spark_reset_main.pending').exists(),
        isFalse,
      );
    },
  );
}
