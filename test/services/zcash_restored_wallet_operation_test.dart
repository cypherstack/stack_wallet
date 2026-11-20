import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/services/zcash_restored_wallet_operation.dart';
import 'package:stackwallet/services/zcash_sapling_parameter_service.dart';
import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

void main() {
  test('scans before inspecting and acquiring restored-wallet data', () async {
    final events = <String>[];
    final operation = ZcashRestoredWalletOperation(
      scan: () async => events.add('scan'),
      shouldAcquireParameters: () {
        events.add('inspect');
        return true;
      },
      cancelScan: () async {},
      parameterTaskFactory: () {
        events.add('attach');
        return _PendingParameterTask();
      },
    );

    final ready = await operation.run(
      acquireParameters: (taskFactory) async {
        events.add('acquire');
        taskFactory();
        return true;
      },
    );

    expect(ready, isTrue);
    expect(events, ['scan', 'inspect', 'acquire', 'attach']);
  });

  test(
    'does not create a parameter task without spendable Sapling funds',
    () async {
      var taskCreations = 0;
      final operation = ZcashRestoredWalletOperation(
        scan: () async {},
        shouldAcquireParameters: () => false,
        cancelScan: () async {},
        parameterTaskFactory: () {
          taskCreations++;
          return _PendingParameterTask();
        },
      );

      expect(
        await operation.run(
          acquireParameters: (_) async => fail('must not acquire'),
        ),
        isTrue,
      );
      expect(taskCreations, 0);
    },
  );

  test(
    'cancelling a pending scan completes the operation as cancelled',
    () async {
      final scan = Completer<void>();
      var cancellations = 0;
      final operation = ZcashRestoredWalletOperation(
        scan: () => scan.future,
        shouldAcquireParameters: () => true,
        cancelScan: () async {
          cancellations++;
          if (!scan.isCompleted) {
            scan.completeError(StateError('session closed'));
          }
        },
      );

      final result = operation.run(
        acquireParameters: (_) async => fail('must not acquire'),
      );
      await Future<void>.delayed(Duration.zero);
      await operation.cancel();

      expect(await result, isFalse);
      expect(cancellations, 1);
    },
  );

  test('cancelling parameter acquisition detaches its task', () async {
    final task = _PendingParameterTask();
    final operation = ZcashRestoredWalletOperation(
      scan: () async {},
      shouldAcquireParameters: () => true,
      cancelScan: () async {},
      parameterTaskFactory: () => task,
    );

    final result = operation.run(
      acquireParameters: (taskFactory) async {
        await taskFactory().result;
        return true;
      },
    );
    await Future<void>.delayed(Duration.zero);
    await operation.cancel();

    expect(await result, isFalse);
    expect(task.cancelCalls, 1);
  });

  test('cancellation before run prevents scan and task attachment', () async {
    var scans = 0;
    var taskCreations = 0;
    var scanCancellations = 0;
    final operation = ZcashRestoredWalletOperation(
      scan: () async {
        scans++;
      },
      shouldAcquireParameters: () => true,
      cancelScan: () async {
        scanCancellations++;
      },
      parameterTaskFactory: () {
        taskCreations++;
        return _PendingParameterTask();
      },
    );

    await operation.cancel();
    final ready = await operation.run(
      acquireParameters: (_) async => fail('must not acquire'),
    );

    expect(ready, isFalse);
    expect(scans, 0);
    expect(taskCreations, 0);
    expect(scanCancellations, 1);
  });

  test('maps download bytes to existing restore-card progress', () {
    final activity = zcashRestoreParameterActivity(
      const SaplingParametersDownloading(
        fileName: 'sapling-spend.params',
        receivedBytes: 25,
        totalReceivedBytes: 25,
        totalExpectedBytes: 100,
      ),
    );

    expect(activity.label, 'Downloading Zcash data');
    expect(activity.progress, 0.25);
  });
}

final class _PendingParameterTask implements SaplingParameterTask {
  final _result = Completer<zcash.SaplingProvingParameters>();
  var cancelCalls = 0;

  @override
  Future<void> cancel() async {
    cancelCalls++;
    if (!_result.isCompleted) {
      _result.completeError(const ZcashSaplingParameterDownloadCancelled());
    }
  }

  @override
  Future<zcash.SaplingProvingParameters> get result => _result.future;

  @override
  Stream<SaplingParameterState> get states => const Stream.empty();
}
