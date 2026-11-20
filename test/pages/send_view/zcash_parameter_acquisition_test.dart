import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/send_view/zcash_parameter_acquisition.dart';
import 'package:stackwallet/services/zcash_sapling_parameter_service.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

import '../../sample_data/theme_json.dart';

final class _ParametersRequired implements Exception {}

void main() {
  test('acquires once and retries the original preparation', () async {
    var preparations = 0;
    var acquisitions = 0;

    final result = await prepareWithSaplingParameterAcquisition<String>(
      prepare: () async {
        preparations++;
        if (preparations == 1) throw _ParametersRequired();
        return 'prepared';
      },
      isParametersRequired: (Object error) => error is _ParametersRequired,
      acquire: () async {
        acquisitions++;
        return true;
      },
    );

    expect(result, 'prepared');
    expect(preparations, 2);
    expect(acquisitions, 1);
  });

  test('does not retry preparation when acquisition is declined', () async {
    var preparations = 0;

    final result = await prepareWithSaplingParameterAcquisition<String>(
      prepare: () async {
        preparations++;
        throw _ParametersRequired();
      },
      isParametersRequired: (Object error) => error is _ParametersRequired,
      acquire: () async => false,
    );

    expect(result, isNull);
    expect(preparations, 1);
  });

  test('propagates a second requirement without acquiring again', () async {
    var preparations = 0;
    var acquisitions = 0;

    await expectLater(
      prepareWithSaplingParameterAcquisition<String>(
        prepare: () async {
          preparations++;
          throw _ParametersRequired();
        },
        isParametersRequired: (Object error) => error is _ParametersRequired,
        acquire: () async {
          acquisitions++;
          return true;
        },
      ),
      throwsA(isA<_ParametersRequired>()),
    );

    expect(preparations, 2);
    expect(acquisitions, 1);
  });

  testWidgets('shared coordinator brackets acquisition before retry', (
    tester,
  ) async {
    var preparations = 0;
    var beforeCalls = 0;
    var afterCalls = 0;
    late Future<String?> result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              result = prepareWithZcashSaplingParameterAcquisition<String>(
                context: context,
                prepare: () async {
                  preparations++;
                  if (preparations == 1) {
                    throw const ZcashSaplingParametersRequired();
                  }
                  return 'prepared';
                },
                beforeAcquisition: () async => beforeCalls++,
                afterAcquisition: () async => afterCalls++,
                acquireParameters: () async => true,
              );
            },
            child: const Text('Prepare'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Prepare'));
    await tester.pump();

    expect(await result, 'prepared');
    expect(preparations, 2);
    expect(beforeCalls, 1);
    expect(afterCalls, 1);
  });

  testWidgets('asks before showing progress and allows cancellation', (
    tester,
  ) async {
    final task = _FakeSaplingParameterTask();
    addTearDown(task.dispose);
    final theme = StackTheme.fromJson(json: lightThemeJsonMap);
    late Future<bool> acquisition;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [themeProvider.overrideWithValue(StateController(theme))],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [StackColors.fromStackColorTheme(theme)],
          ),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                acquisition = acquireSaplingParameters(
                  context: context,
                  taskFactory: () => task,
                );
              },
              child: const Text('Prepare'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Prepare'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Additional Zcash data required'), findsOneWidget);

    await tester.tap(find.text('Download'));
    await tester.pump();
    expect(find.text('Downloading and verifying Zcash data'), findsOneWidget);

    task.progress(received: 10, expected: 100);
    await tester.pump();
    expect(find.text('10.00%'), findsOneWidget);

    await tester.tap(find.byType(SecondaryButton));
    await tester.pump();
    expect(task.cancelCalls, 1);
    expect(await acquisition, isFalse);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Downloading and verifying Zcash data'), findsNothing);
  });
}

final class _FakeSaplingParameterTask implements SaplingParameterTask {
  final _result = Completer<zcash.SaplingProvingParameters>();
  final _states = StreamController<SaplingParameterState>.broadcast();
  var cancelCalls = 0;

  void progress({required int received, required int expected}) {
    _states.add(
      SaplingParametersDownloading(
        fileName: 'sapling-spend.params',
        receivedBytes: received,
        totalReceivedBytes: received,
        totalExpectedBytes: expected,
      ),
    );
  }

  Future<void> dispose() => _states.close();

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
  Stream<SaplingParameterState> get states => _states.stream;
}
