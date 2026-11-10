import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:stackwallet/db/sqlite/firo_cache.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

// Each isolate simulates a new process opening cache files after termination.
Future<(int, bool, bool)> recover(String root, String intent) async {
  StackFileSystem.setDesktopOverrideDir(root);
  final dir = await StackFileSystem.applicationFiroCacheSQLiteDirectory();
  final sets = sqlite3.open('${dir.path}/spark_set_v2.sqlite3');
  sets.execute('''
    CREATE TABLE SparkSet (id INTEGER PRIMARY KEY, blockHash TEXT,
      setHash TEXT, groupId INTEGER, size INTEGER);
    INSERT INTO SparkSet VALUES (1, 'old', 'old', 1, 1);
  ''');
  sets.close();
  final tags = sqlite3.open('${dir.path}/spark_tags_v2.sqlite3');
  tags.execute('''
    CREATE TABLE SparkUsedCoinTags (id INTEGER PRIMARY KEY, tag TEXT, txid TEXT);
    INSERT INTO SparkUsedCoinTags VALUES (1, 'old', 'tx');
  ''');
  tags.close();
  final marker = File('${dir.path}/spark_reset_main.pending');
  await marker.writeAsString(intent, flush: true);
  await FiroCacheCoordinator.init();
  try {
    return (
      await FiroCacheCoordinator.getUsedCoinTagsCount(
        CryptoCurrencyNetwork.main,
      ),
      await FiroCacheCoordinator.getLatestSetInfoForGroupId(
            1,
            CryptoCurrencyNetwork.main,
          ) ==
          null,
      await marker.exists(),
    );
  } finally {
    await FiroCacheCoordinator.close();
  }
}

void main() {
  for (final intent in ['all-v1', 'tags-v1', '']) {
    test('startup replays persisted reset intent "$intent"', () async {
      final dir = await Directory.systemTemp.createTemp('firo-reset-recovery-');
      final root = dir.path;
      try {
        final result = await Isolate.run(() => recover(root, intent));
        expect(result, (0, intent != 'tags-v1', false));
      } finally {
        await dir.delete(recursive: true);
      }
    });
  }
}
