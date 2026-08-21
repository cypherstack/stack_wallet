import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:stackwallet/utilities/logger_dispatcher.dart';

void main() {
  group("LoggerDispatcher", () {
    test("sends the formatted event to the logger isolate", () async {
      final receivePort = ReceivePort();
      addTearDown(receivePort.close);
      final timestamp = DateTime.utc(2026, 8, 20);
      final dispatcher = LoggerDispatcher(
        lookupSender: () => receivePort.sendPort.send,
        fallback: (_, _, _) => fail("fallback should not run"),
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
      final fallbackCalls = <(LogEvent, Object, StackTrace)>[];
      final dispatcher = LoggerDispatcher(
        lookupSender: () => null,
        fallback: (event, error, stackTrace) {
          fallbackCalls.add((event, error, stackTrace));
        },
      );

      final didSend = dispatcher.log(Level.warning, "not ready");

      expect(didSend, isFalse);
      expect(fallbackCalls, hasLength(1));
      expect(fallbackCalls.single.$1.message, "not ready");
      expect(fallbackCalls.single.$2, isA<StateError>());
    });

    test("uses the fallback when sending fails", () {
      final dispatchError = StateError("send failed");
      final fallbackCalls = <(LogEvent, Object, StackTrace)>[];
      final dispatcher = LoggerDispatcher(
        lookupSender: () =>
            (_) => throw dispatchError,
        fallback: (event, error, stackTrace) {
          fallbackCalls.add((event, error, stackTrace));
        },
      );

      final didSend = dispatcher.log(Level.error, "important");

      expect(didSend, isFalse);
      expect(fallbackCalls, hasLength(1));
      expect(fallbackCalls.single.$1.message, "important");
      expect(fallbackCalls.single.$2, same(dispatchError));
    });

    test("does not throw when the fallback itself fails", () {
      final dispatcher = LoggerDispatcher(
        lookupSender: () => null,
        fallback: (_, _, _) => throw StateError("fallback failed"),
      );

      expect(() => dispatcher.log(Level.error, "important"), returnsNormally);
    });

    test("replaces a message that cannot be stringified", () {
      final sentMessages = <Object?>[];
      final dispatcher = LoggerDispatcher(
        lookupSender: () => sentMessages.add,
        fallback: (_, _, _) => fail("fallback should not run"),
      );

      final didSend = dispatcher.log(Level.info, _UnprintableMessage());

      expect(didSend, isTrue);
      final message = sentMessages.single! as LoggerIsolateMessage;
      expect(message.$1.message, contains("_UnprintableMessage"));
      expect(message.$1.message, contains("could not stringify"));
    });

    test("the developer fallback tolerates unprintable details", () {
      final event = LogEvent(
        Level.error,
        _UnprintableMessage(),
        error: _UnprintableMessage(),
      );

      expect(
        () => developerLoggerFallback(
          event,
          _UnprintableMessage(),
          StackTrace.current,
        ),
        returnsNormally,
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
