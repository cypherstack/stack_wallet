import 'dart:async';
import 'dart:core' as core;
import 'dart:core';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:epicmobile/models/isar/models/log.dart';
import 'package:epicmobile/utilities/constants.dart';
import 'package:epicmobile/utilities/enums/log_level_enum.dart';

export 'enums/log_level_enum.dart';

class Logging {
  static const isArmLinux = bool.fromEnvironment("IS_ARM");
  static final isTestEnv = Platform.environment["FLUTTER_TEST"] == "true";
  Logging._();
  static final Logging _instance = Logging._();
  static Logging get instance => _instance;

  static const core.int defaultPrintLength = 1020;

  late final Isar? isar;

  Future<void> init(Isar isar) async {
    this.isar = isar;
  }

  Future<void> initInIsolate() async {
    if (isTestEnv || isArmLinux) {
      // do this for now until we mock Isar properly for testing
      isar = null;
      return;
    }
    isar = await Isar.open(
      [LogSchema],
      inspector: false,
    );
  }

  void log(
    core.Object? object, {
    required LogLevel level,
    core.bool printToConsole = true,
    core.bool printFullLength = false,
  }) {
    try {
      if (isTestEnv || isArmLinux) {
        Logger.print(object, normalLength: !printFullLength);
        return;
      }
      final now = core.DateTime.now().toUtc();
      final log = Log()
        ..message = object.toString()
        ..logLevel = level
        ..timestampInMillisUTC = now.millisecondsSinceEpoch;
      if (level == LogLevel.Error || level == LogLevel.Fatal) {
        printFullLength = true;
      }

      isar!.writeTxnSync(() => log.id = isar!.logs.putSync(log));

      if (printToConsole) {
        final core.String logStr = "Log: ${log.toString()}";
        final core.int logLength = logStr.length;

        if (!printFullLength || logLength <= defaultPrintLength) {
          debugPrint(logStr);
        } else {
          core.int start = 0;
          core.int endIndex = defaultPrintLength;
          core.int tmpLogLength = logLength;
          while (endIndex < logLength) {
            debugPrint(logStr.substring(start, endIndex));
            endIndex += defaultPrintLength;
            start += defaultPrintLength;
            tmpLogLength -= defaultPrintLength;
          }
          if (tmpLogLength > 0) {
            debugPrint(logStr.substring(start, logLength));
          }
        }
      }
    } catch (e, s) {
      print("problem trying to log");
      print("$e $s");
      Logger.print(object);
    }
  }
}

abstract class Logger {
  static final isTestEnv = Platform.environment["FLUTTER_TEST"] == "true";

  static void print(
    core.Object? object, {
    core.bool withTimeStamp = true,
    core.bool normalLength = true,
  }) async {
    if (Constants.disableLogger && !isTestEnv) {
      return;
    }
    final utcTime = withTimeStamp ? "${core.DateTime.now().toUtc()}: " : "";
    core.int defaultPrintLength = 1020 - utcTime.length;
    if (normalLength) {
      debugPrint("$utcTime$object");
    } else if (object == null ||
        object.toString().length <= defaultPrintLength) {
      debugPrint("$utcTime$object");
    } else {
      core.String log = object.toString();
      core.int start = 0;
      core.int endIndex = defaultPrintLength;
      core.int logLength = log.length;
      core.int tmpLogLength = log.length;
      while (endIndex < logLength) {
        debugPrint(utcTime + log.substring(start, endIndex));
        endIndex += defaultPrintLength;
        start += defaultPrintLength;
        tmpLogLength -= defaultPrintLength;
      }
      if (tmpLogLength > 0) {
        debugPrint(utcTime + log.substring(start, logLength));
      }
    }
  }
}
