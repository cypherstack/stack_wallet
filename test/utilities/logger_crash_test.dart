import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/logger_dispatcher.dart';

const _loggerPortName = "logger_port";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("persists a worker crash and restarts logging", () async {
    final logsDirectory = Directory.systemTemp.createTempSync(
      "logger_crash_test_",
    );
    addTearDown(() => logsDirectory.deleteSync(recursive: true));

    await Logging.instance.initialize(
      logsDirectory.path,
      level: Level.trace,
      debugConsoleLevel: Level.off,
    );
    final initialPort = IsolateNameServer.lookupPortByName(_loggerPortName);
    expect(initialPort, isNotNull);

    initialPort!.send("malformed logger message");

    final emergencyLog = File(emergencyLogPath(logsDirectory.path));
    await _waitFor(() {
      final currentPort = IsolateNameServer.lookupPortByName(_loggerPortName);
      return emergencyLog.existsSync() &&
          emergencyLog.readAsStringSync().contains("Logger isolate failed") &&
          currentPort != null &&
          currentPort != initialPort;
    });

    final contents = emergencyLog.readAsStringSync();
    expect(contents, contains("Logger isolate failed"));
    expect(contents, contains("Logger isolate reported an error"));
    expect(contents, contains("is not a subtype of type"));
    expect(contents, isNot(contains("Logger isolate exited unexpectedly")));

    final restartedPort = IsolateNameServer.lookupPortByName(_loggerPortName)!;
    for (var i = 0; i < 200; i++) {
      restartedPort.send((LogEvent(Level.info, "post-restart $i"), true));
    }
    restartedPort.send((
      LogEvent(Level.warning, "post-restart complete"),
      true,
    ));

    final latestLog = File(path.join(logsDirectory.path, "latest.txt"));
    await _waitFor(
      () =>
          latestLog.existsSync() &&
          latestLog.readAsStringSync().contains("post-restart complete"),
    );
    expect(emergencyLog.readAsStringSync(), contents);
  });
}

Future<void> _waitFor(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail("Timed out waiting for the logger isolate to fail");
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}
