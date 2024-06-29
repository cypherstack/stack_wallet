import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart' show Box;
import 'package:hive/src/hive_impl.dart';
import 'package:path_provider/path_provider.dart';

import '../app_config.dart';
import '../utilities/util.dart';
import 'hive/db.dart';

abstract class CampfireMigration {
  static const _didRunKey = "campfire_one_time_migration_done_key";

  static bool get didRun =>
      DB.instance.get<dynamic>(
        boxName: DB.boxNameDBInfo,
        key: _didRunKey,
      ) as bool? ??
      false;

  static Future<void> setDidRun() async {
    await DB.instance.put<dynamic>(
      boxName: DB.boxNameDBInfo,
      key: _didRunKey,
      value: true,
    );
  }

  static bool get hasOldWallets =>
      !didRun && (_wallets?.get("names") as Map?)?.isNotEmpty == true;

  static late final FlutterSecureStorage? _secureStore;
  static late final Box<dynamic>? _wallets;

  static Future<void> init() async {
    if (didRun || Util.isDesktop) {
      return;
    }
    final Directory appDirectory = await getApplicationDocumentsDirectory();

    final file = File("${appDirectory.path}/wallets.hive");

    if (await file.exists()) {
      final myHive = HiveImpl();
      myHive.init(appDirectory.path);
      _wallets = await myHive.openBox<dynamic>('wallets');
      _secureStore = const FlutterSecureStorage();
    } else {
      await setDidRun();
    }
  }

  static Future<List<(String, List<String>)>> fetch() async {
    if (didRun ||
        Util.isDesktop ||
        AppConfig.appName != "Campfire" ||
        _wallets == null) {
      return [];
    }

    final names = _wallets!.get("names");

    final List<(String, List<String>)> results = [];
    if (names is Map) {
      for (final entry in names.entries) {
        final name = entry.key as String;
        final id = entry.value as String;
        final mnemonic = await _secureStore!.read(key: "${id}_mnemonic");

        if (mnemonic != null) {
          results.add((name, mnemonic.split(" ")));
        }
      }
    }

    return results;
  }
}
