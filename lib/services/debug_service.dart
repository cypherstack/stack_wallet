import 'dart:async';
import 'dart:io';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/models/isar/models/log.dart';
import 'package:stackwallet/utilities/logger.dart';

class DebugService extends ChangeNotifier {
  DebugService._();
  static final DebugService _instance = DebugService._();
  static DebugService get instance => _instance;

  late final Isar isar;
  // late final Stream<void> logsChanged;

  final int numberOfRecentLogsToLoad = 500;

  // bool _shouldPause = false;
  //
  // void togglePauseUiUpdates() {
  //   _shouldPause = !_shouldPause;
  //   notifyListeners();
  // }

  // bool get isPaused => _shouldPause;

  Future<void> init(Isar isar) async {
    this.isar = isar;
    // logsChanged = this.isar.logs.watchLazy();
    // logsChanged.listen((_) {
    //   if (!_shouldPause) {
    //     updateRecentLogs();
    //   }
    // });
  }

  List<Log> _recentLogs = [];
  List<Log> get recentLogs => _recentLogs;

  Future<void> updateRecentLogs() async {
    int totalCount = await isar.logs.count();
    int offset = totalCount - numberOfRecentLogsToLoad;
    if (offset < 0) {
      offset = 0;
    }

    _recentLogs = (await isar.logs
        .where()
        .anyTimestampInMillisUTC()
        .offset(offset)
        .limit(numberOfRecentLogsToLoad)
        .findAll());
    notifyListeners();
  }

  Future<void> deleteAllMessages() async {
    try {
      await isar.writeTxn(() async => await isar.logs.clear());
      notifyListeners();
    } catch (e, s) {
      debugPrint("$e, $s");
    }
  }

  Future<void> purgeInfoLogs() async {
    final now = DateTime.now();
    await isar.writeTxn(() async {
      await isar.logs.filter().logLevelEqualTo(LogLevel.Info).deleteAll();
    });

    Logging.instance.log(
        "Info logs purged in ${DateTime.now().difference(now).inMilliseconds} milliseconds",
        level: LogLevel.Info);
  }

  Future<void> exportToFile(String directory, EventBus eventBus) async {
    final now = DateTime.now();
    final filename =
        "Stack_Wallet_logs_${now.year}_${now.month}_${now.day}_${now.hour}_${now.minute}_${now.second}.txt";
    final filepath = "$directory/$filename";
    File file = await File(filepath).create();

    final sink = file.openWrite();
    final logs = await isar.logs.where().anyTimestampInMillisUTC().findAll();
    final count = logs.length;
    int counter = 0;

    for (final log in logs) {
      sink.writeln(log);
      await sink.flush();
      counter++;
      final exportPercent = (counter / count).clamp(0.0, 1.0);
      eventBus.fire(exportPercent);
    }

    await sink.flush();
    await sink.close();

    eventBus.fire(1.0);
  }
}
