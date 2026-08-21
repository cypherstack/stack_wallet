import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:stackwallet/utilities/logger_dispatcher.dart';

void main() {
  group("LoggerDispatcher", () {
    test("sends the formatted event to the logger isolate", () async {
      final receivePort = ReceivePort();
      addTearDown(receivePort.close);
      final timestamp = DateTime.utc(2026, 8, 20);
      final dispatcher = LoggerDispatcher(
        lookupSender: () => receivePort.sendPort.send,
        fallback: (_, _, _, _) => fail("fallback should not run"),
      );

      final didSend = dispatcher.log(
        Level.info,
        {"status": "ready"},
        time: timestamp,
        toFile: false,
      );

      expect(didSend, isTrue);
      final message = await receivePort.first as LoggerIsolateMessage;
      expect(message.$1.level, Level.info);
      expect(message.$1.message, '{\n  "status": "ready"\n}');
      expect(message.$1.time, timestamp);
      expect(message.$2, isFalse);
    });

    test("uses the fallback when the logger isolate is unavailable", () {
      final fallbackCalls = <(LogEvent, bool, Object, StackTrace)>[];
      final dispatcher = LoggerDispatcher(
        lookupSender: () => null,
        fallback: (event, toFile, error, stackTrace) {
          fallbackCalls.add((event, toFile, error, stackTrace));
        },
      );

      final didSend = dispatcher.log(Level.warning, "not ready");

      expect(didSend, isFalse);
      expect(fallbackCalls, hasLength(1));
      expect(fallbackCalls.single.$1.message, "not ready");
      expect(fallbackCalls.single.$2, isTrue);
      expect(fallbackCalls.single.$3, isA<StateError>());
    });

    test("uses the fallback when sending fails", () {
      final dispatchError = StateError("send failed");
      final fallbackCalls = <(LogEvent, bool, Object, StackTrace)>[];
      final dispatcher = LoggerDispatcher(
        lookupSender: () =>
            (_) => throw dispatchError,
        fallback: (event, toFile, error, stackTrace) {
          fallbackCalls.add((event, toFile, error, stackTrace));
        },
      );

      final didSend = dispatcher.log(Level.error, "important");

      expect(didSend, isFalse);
      expect(fallbackCalls, hasLength(1));
      expect(fallbackCalls.single.$1.message, "important");
      expect(fallbackCalls.single.$3, same(dispatchError));
    });

    test("does not throw when the fallback itself fails", () {
      final dispatcher = LoggerDispatcher(
        lookupSender: () => null,
        fallback: (_, _, _, _) => throw StateError("fallback failed"),
      );

      expect(() => dispatcher.log(Level.error, "important"), returnsNormally);
    });

    test("replaces a message that cannot be stringified", () {
      final sentMessages = <Object?>[];
      final dispatcher = LoggerDispatcher(
        lookupSender: () => sentMessages.add,
        fallback: (_, _, _, _) => fail("fallback should not run"),
      );

      final didSend = dispatcher.log(Level.info, _UnprintableMessage());

      expect(didSend, isTrue);
      final message = sentMessages.single! as LoggerIsolateMessage;
      expect(message.$1.message, contains("_UnprintableMessage"));
      expect(message.$1.message, contains("could not stringify"));
    });

    test("writes dispatch failures to the emergency log", () {
      final directory = Directory.systemTemp.createTempSync(
        "logger_dispatcher_test_",
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      final timestamp = DateTime.utc(2026, 8, 20, 12, 34, 56);
      final event = LogEvent(
        Level.error,
        "wallet recovery failed",
        time: timestamp,
        error: StateError("original failure"),
        stackTrace: StackTrace.fromString("original stack"),
      );

      emergencyLoggerFallback(
        event,
        true,
        StateError("logger isolate unavailable"),
        StackTrace.fromString("dispatch stack"),
        logsDirectoryPath: directory.path,
      );
      emergencyLoggerFallback(
        LogEvent(
          Level.warning,
          "subsequent failure",
          time: timestamp.add(const Duration(seconds: 1)),
        ),
        true,
        StateError("logger still unavailable"),
        StackTrace.fromString("second dispatch stack"),
        logsDirectoryPath: directory.path,
      );

      final contents = File(
        emergencyLogPath(directory.path),
      ).readAsStringSync();
      expect(contents, contains(timestamp.toIso8601String()));
      expect(contents, contains("[error] wallet recovery failed"));
      expect(contents, contains("original failure"));
      expect(contents, contains("logger isolate unavailable"));
      expect(contents, contains("original stack"));
      expect(contents, contains("dispatch stack"));
      expect(contents, contains("subsequent failure"));
      expect(contents, contains("logger still unavailable"));
    });

    test("does not persist console-only messages", () {
      var writeCalls = 0;

      emergencyLoggerFallback(
        LogEvent(Level.info, "console only"),
        false,
        StateError("logger isolate unavailable"),
        StackTrace.current,
        logsDirectoryPath: "unused",
        writeToFile: (_, _) => writeCalls++,
      );

      expect(writeCalls, isZero);
    });

    test("tolerates emergency file and formatting failures", () {
      final event = LogEvent(
        Level.error,
        _UnprintableMessage(),
        error: _UnprintableMessage(),
      );

      expect(
        () => emergencyLoggerFallback(
          event,
          true,
          _UnprintableMessage(),
          StackTrace.current,
          logsDirectoryPath: "unwritable",
          writeToFile: (_, _) => throw StateError("write failed"),
        ),
        returnsNormally,
      );
    });

    test("builds emergency log paths for every native platform", () {
      final posix = path.Context(style: path.Style.posix);
      final windows = path.Context(style: path.Style.windows);

      for (final directory in [
        "/home/stack/Documents/StackWallet_Logs/",
        "/Users/stack/Documents/StackWallet_Logs/",
        "/data/user/0/com.cypherstack.stackwallet/files/logs/",
        "/var/mobile/Containers/Data/Application/id/Documents/logs/",
      ]) {
        expect(
          emergencyLogPath(directory, context: posix),
          "${directory}emergency.txt",
        );
      }
      expect(
        emergencyLogPath(
          r"C:\Users\Stack\Documents\StackWallet_Logs\",
          context: windows,
        ),
        r"C:\Users\Stack\Documents\StackWallet_Logs\emergency.txt",
      );
    });
  });

  group("LoggerPortRegistry", () {
    test("removes the logger port when its worker exits", () {
      final receivePort = ReceivePort();
      addTearDown(receivePort.close);
      SendPort? registeredPort = receivePort.sendPort;
      var removeCalls = 0;
      final registry = LoggerPortRegistry(
        lookupPort: () => registeredPort,
        registerPort: (_) => true,
        removePort: () {
          removeCalls++;
          registeredPort = null;
          return true;
        },
      );

      final didRemove = registry.removeIfCurrent(receivePort.sendPort);

      expect(didRemove, isTrue);
      expect(removeCalls, 1);
      expect(registeredPort, isNull);
    });

    test("does not remove a replacement logger port", () {
      final workerPort = ReceivePort();
      final replacementPort = ReceivePort();
      addTearDown(workerPort.close);
      addTearDown(replacementPort.close);
      var removeCalls = 0;
      final registry = LoggerPortRegistry(
        lookupPort: () => replacementPort.sendPort,
        registerPort: (_) => true,
        removePort: () {
          removeCalls++;
          return true;
        },
      );

      final didRemove = registry.removeIfCurrent(workerPort.sendPort);

      expect(didRemove, isFalse);
      expect(removeCalls, 0);
    });
  });
}

class _UnprintableMessage {
  @override
  String toString() => throw StateError("broken toString");
}
