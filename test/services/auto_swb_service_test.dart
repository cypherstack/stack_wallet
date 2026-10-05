import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/services/auto_swb_service.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';

void main() {
  late AutoSWBService service;
  late Future<void> Function() backupRunner;
  var shouldBackup = true;
  var isDisposed = false;

  setUp(() {
    shouldBackup = true;
    isDisposed = false;
    backupRunner = () async {};
    service = AutoSWBService(
      secureStorageInterface: FakeSecureStorage(),
      shouldBackupAfterChange: () => shouldBackup,
      backupRunner: () => backupRunner(),
      debounceDuration: Duration.zero,
    );
  });

  tearDown(() {
    if (!isDisposed) {
      service.dispose();
    }
  });

  test('only schedules change backups when enabled', () async {
    var backups = 0;
    backupRunner = () async {
      backups++;
    };

    shouldBackup = false;
    service.requestBackupAfterChange();
    await _flushTimers();
    expect(backups, 0);

    shouldBackup = true;
    service.requestBackupAfterChange();
    await _flushTimers();
    expect(backups, 1);
  });

  test(
    'does not back up if the gate closes inside the debounce window',
    () async {
      var backups = 0;
      backupRunner = () async {
        backups++;
      };

      service.requestBackupAfterChange();
      // User turns auto backup off (or switches frequency) before the timer fires.
      shouldBackup = false;
      await _flushTimers();

      expect(backups, 0);
    },
  );

  test('coalesces a burst into one backup', () async {
    var backups = 0;
    backupRunner = () async {
      backups++;
    };

    service.requestBackupAfterChange();
    service.requestBackupAfterChange();
    service.requestBackupAfterChange();
    await _flushTimers();

    expect(backups, 1);
    expect(service.status, AutoSWBStatus.idle);
  });

  test('runs one follow-up for changes during an active backup', () async {
    final firstBackup = Completer<void>();
    var backups = 0;
    backupRunner = () async {
      backups++;
      if (backups == 1) {
        await firstBackup.future;
      }
    };

    final runningBackup = service.doBackup();
    await _flushTimers();
    expect(service.status, AutoSWBStatus.backingUp);

    service.requestBackupAfterChange();
    service.requestBackupAfterChange();
    await _flushTimers();
    expect(backups, 1);

    firstBackup.complete();
    await runningBackup;

    expect(backups, 2);
    expect(service.status, AutoSWBStatus.idle);
  });

  test('recovers after a backup failure', () async {
    var backups = 0;
    backupRunner = () async {
      backups++;
      if (backups == 1) {
        throw StateError('failed');
      }
    };

    await service.doBackup();
    expect(service.status, AutoSWBStatus.error);

    await service.doBackup();
    expect(backups, 2);
    expect(service.status, AutoSWBStatus.idle);
  });

  test('cancels a debounced request on dispose', () async {
    var backups = 0;
    backupRunner = () async {
      backups++;
    };
    service.requestBackup(debounceDuration: const Duration(milliseconds: 20));

    service.dispose();
    isDisposed = true;
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(backups, 0);
  });

  test('finishes an active backup safely after dispose', () async {
    final backup = Completer<void>();
    var backups = 0;
    backupRunner = () async {
      backups++;
      await backup.future;
    };

    final runningBackup = service.doBackup();
    await _flushTimers();
    service.dispose();
    isDisposed = true;
    backup.complete();

    await expectLater(runningBackup, completes);
    service.requestBackupAfterChange();
    await _flushTimers();

    expect(backups, 1);
    expect(service.status, AutoSWBStatus.idle);
  });
}

Future<void> _flushTimers() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
