import 'dart:async';
import 'dart:io';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:stackduo/models/isar/models/log.dart';
import 'package:stackduo/utilities/logger.dart';

class DebugService extends ChangeNotifier {
  DebugService._();
  static final DebugService _instance = DebugService._();
  static DebugService get instance => _instance;

  late final Isar isar;
  // late final Stream<void> logsChanged;

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

  List<Log> get recentLogs => isar.logs.where().limit(200).findAllSync();

  // Future<void> updateRecentLogs() async {
  //   int totalCount = await isar.logs.count();
  //   int offset = totalCount - numberOfRecentLogsToLoad;
  //   if (offset < 0) {
  //     offset = 0;
  //   }
  //
  //   _recentLogs = (await isar.logs
  //       .where()
  //       .anyTimestampInMillisUTC()
  //       .offset(offset)
  //       .limit(numberOfRecentLogsToLoad)
  //       .findAll());
  //   notifyListeners();
  // }

  Future<bool> deleteAllLogs() async {
    try {
      await isar.writeTxn(() async => await isar.logs.clear());
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteLogsOlderThan({
    Duration timeframe = const Duration(days: 30),
  }) async {
    final cutoffDate = DateTime.now().subtract(timeframe).toUtc();
    await isar.writeTxn(() async {
      await isar.logs
          .where()
          .timestampInMillisUTCLessThan(cutoffDate.millisecondsSinceEpoch)
          .deleteAll();
    });

    Logging.instance.log(
      "Logs older than $cutoffDate cleared!",
      level: LogLevel.Info,
    );
  }

  /// returns the filename of the saved logs file
  Future<String> exportToFile(String directory, EventBus eventBus) async {
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
    return filename;
  }
}
