#!/usr/bin/env dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import '../integration_test/wallet_creation/coin_matrix.dart';

const _walletStages = {
  'select and name',
  'default options',
  'generate',
  'confirm recovery phrase',
  'open created wallet',
  'recovery identity',
  'check persisted wallet',
};

ArgParser argumentParser() => ArgParser()
  ..addOption('device', help: 'Flutter device ID, e.g. macos, linux, windows.')
  ..addOption(
    'platform',
    allowed: ['macos', 'linux', 'windows', 'android', 'ios'],
    help: 'Required for mobile; inferred from desktop device IDs.',
  )
  ..addMultiOption(
    'coin',
    allowed: defaultWordCounts.keys.toList(),
    help: 'Repeat to select coins; default: every coin independently.',
  )
  ..addFlag(
    'all-coins',
    negatable: false,
    help: 'Accumulate all 24 wallets in one installation.',
  )
  ..addFlag(
    'disposable-mobile',
    negatable: false,
    help: 'Confirm that the mobile app installation is clean and disposable.',
  )
  ..addOption(
    'flutter',
    defaultsTo: Platform.environment['FLUTTER_BIN'] ?? 'flutter',
  )
  ..addOption('report', help: 'Write sanitized results to this JSON file.')
  ..addFlag(
    'list',
    negatable: false,
    help: 'List coin IDs without launching the app.',
  )
  ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage.');

class RunOptions {
  RunOptions.fromResults(ArgResults args)
    : device = args['device'] as String? ?? '',
      platform =
          args['platform'] as String? ??
          (const ['macos', 'linux', 'windows'].contains(args['device'])
              ? args['device'] as String
              : ''),
      coins = List<String>.from(args['coin'] as List),
      allCoins = args['all-coins'] as bool,
      disposableMobile = args['disposable-mobile'] as bool,
      flutter = args['flutter'] as String,
      report = args['report'] == null ? null : File(args['report'] as String) {
    if (args.rest.isNotEmpty) {
      throw const FormatException('Unexpected positional arguments.');
    }
    if (device.isEmpty) throw const FormatException('--device is required.');
    if (platform.isEmpty) {
      throw const FormatException(
        'Pass --platform android or ios for a mobile device ID.',
      );
    }
    if (mobile && !disposableMobile) {
      throw const FormatException(
        'Mobile tests require --disposable-mobile '
        'and a clean dedicated app install.',
      );
    }
    if (const ['macos', 'linux', 'windows'].contains(device) &&
        device != platform) {
      throw const FormatException(
        'The desktop device and platform must match.',
      );
    }
    if (allCoins && coins.isNotEmpty) {
      throw const FormatException('--all-coins and --coin cannot be combined.');
    }
  }

  factory RunOptions.parse(List<String> arguments) =>
      RunOptions.fromResults(argumentParser().parse(arguments));

  final String device;
  final String platform;
  final List<String> coins;
  final bool allCoins;
  final bool disposableMobile;
  final String flutter;
  final File? report;

  bool get mobile => platform == 'android' || platform == 'ios';
  List<String> get cases => allCoins
      ? ['all']
      : coins.isEmpty
      ? defaultWordCounts.keys.toList()
      : coins;
}

typedef ProcessStarter = Future<Process> Function(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
  required Map<String, String> environment,
});

Future<Process> _startProcess(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
  required Map<String, String> environment,
}) => Process.start(
  executable,
  arguments,
  workingDirectory: workingDirectory,
  environment: environment,
  runInShell: Platform.isWindows,
);

void _printProgress(String message) => stdout.writeln(message);

/// Runs real create/reopen processes against a fresh directory for each case.
class WalletCreationRunner {
  WalletCreationRunner({
    required this.repository,
    this.temporaryParent,
    this.phaseTimeout,
    this.shutdownTimeout = const Duration(seconds: 20),
    this.log = _printProgress,
    this.startProcess = _startProcess,
  });

  final Directory repository;
  final Directory? temporaryParent;
  final Duration? phaseTimeout;
  final Duration shutdownTimeout;
  final void Function(String) log;
  final ProcessStarter startProcess;
  final results = <Map<String, Object?>>[];
  Process? _active;
  Future<void>? _stopping;
  bool _interrupted = false;
  bool _cleanupFailed = false;

  void interrupt() {
    _interrupted = true;
    // runPhase awaits this same future before deleting any test files.
    _stopActive().ignore();
  }

  Future<Directory> _parent(RunOptions options) async {
    if (temporaryParent != null) return temporaryParent!;
    if (options.platform != 'macos') return Directory.systemTemp;
    final config = await File(
      p.join(repository.path, 'macos/Runner/Configs/AppInfo.xcconfig'),
    ).readAsString();
    final bundle = RegExp(
      r'^PRODUCT_BUNDLE_IDENTIFIER\s*=\s*([A-Za-z0-9_.-]+)\s*$',
      multiLine: true,
    ).firstMatch(config)?.group(1);
    if (bundle == null) {
      throw const FormatException(
        'Configure the macOS app before running integration tests.',
      );
    }
    final home = Platform.environment['HOME'];
    if (home == null) {
      throw const FormatException('Cannot locate the macOS home directory.');
    }
    return Directory(
      p.join(home, 'Library', 'Containers', bundle, 'Data', 'tmp'),
    )..createSync(recursive: true);
  }

  Future<int> run(RunOptions options) async {
    try {
      final parent = await _parent(options);
      for (final coin in options.cases) {
        if (_interrupted) break;
        final root = await parent.createTemp('stack_wallet_creation_');
        final random = Random.secure();
        final runId = List.generate(
          16,
          (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
        ).join();
        try {
          final created = await runPhase(options, coin, 'create', root, runId);
          results.add(created);
          if (created['status'] == 'passed' && !_interrupted) {
            results.add(await runPhase(options, coin, 'reopen', root, runId));
          } else {
            results.add({
              'platform': options.platform,
              'coin': coin,
              'phase': 'reopen',
              'status': 'blocked',
              'reason': 'creation did not complete',
            });
          }
        } finally {
          if (!_cleanupFailed) await root.delete(recursive: true);
        }
        // A failed mobile install requires explicit reset by its operator.
        if (options.mobile && results.any((r) => r['status'] != 'passed')) {
          break;
        }
      }
    } finally {
      final report = options.report;
      if (report != null) {
        await report.parent.create(recursive: true);
        await report.writeAsString(
          '${const JsonEncoder.withIndent('  ').convert(results)}\n',
        );
      }
    }
    log(
      jsonEncode({
        for (final status in ['passed', 'failed', 'blocked'])
          status: results.where((r) => r['status'] == status).length,
      }),
    );
    if (_interrupted) return 130;
    return results.isNotEmpty && results.every((r) => r['status'] == 'passed')
        ? 0
        : 1;
  }

  Future<Map<String, Object?>> runPhase(
    RunOptions options,
    String coin,
    String phase,
    Directory root,
    String runId,
  ) async {
    final target = options.allCoins
        ? 'all_coins_test.dart'
        : 'fresh_install_test.dart';
    final arguments = [
      'test',
      '--no-pub',
      '--no-uninstall',
      '-d',
      options.device,
      'integration_test/wallet_creation/$target',
      '--reporter',
      'expanded',
      '--dart-define=IS_INTEGRATION_TEST=true',
      '--dart-define=WALLET_TEST_PLATFORM=${options.platform}',
      '--dart-define=WALLET_TEST_PHASE=$phase',
      '--dart-define=WALLET_TEST_COIN=$coin',
      if (options.mobile) ...[
        '--dart-define=WALLET_TEST_DISPOSABLE_DEVICE=true',
        '--dart-define=WALLET_TEST_RUN_ID=$runId',
      ] else
        '--dart-define=WALLET_TEST_ROOT=${p.join(root.path, 'state')}',
    ];
    final environment = Map<String, String>.from(Platform.environment);
    const xcode = '/Applications/Xcode.app/Contents/Developer';
    if (Platform.isMacOS && Directory(xcode).existsSync()) {
      environment.putIfAbsent('DEVELOPER_DIR', () => xcode);
    }
    final watch = Stopwatch()..start();
    final output = File(p.join(root.path, '$phase.log')).openWrite();
    final completed = <String>{};
    String? lastStage;
    bool buildFailed = false;
    bool appException = false;
    bool timedOut = false;
    int code;

    Future<void> consume(Stream<List<int>> stream) async {
      await for (final line
          in stream
              .map((bytes) {
                output.add(bytes);
                return bytes;
              })
              .transform(const Utf8Decoder(allowMalformed: true))
              .transform(const LineSplitter())) {
        // Native output can include generated seeds. Only fixed-schema progress
        // is forwarded to the terminal; raw logs stay in the disposable root.
        final ok = RegExp(
          r'\bWALLET_CREATION_OK (\w+) (\w+) (create|reopen)\s*$',
        ).firstMatch(line);
        if (ok != null &&
            ok[1] == options.platform &&
            ok[3] == phase &&
            defaultWordCounts.containsKey(ok[2]) &&
            completed.add(ok[2]!)) {
          log('WALLET_CREATION_OK ${ok[1]} ${ok[2]} ${ok[3]}');
        }
        final stage = RegExp(r'\bWALLET_CREATION_STAGE (.+)$')
            .firstMatch(line)?[1];
        final parts = stage?.split(': ');
        final knownStage =
            stage == 'fresh install onboarding' ||
            parts != null &&
                parts.length == 2 &&
                defaultWordCounts.containsKey(parts[0]) &&
                _walletStages.contains(parts[1]);
        if (stage != null && knownStage && stage != lastStage) {
          lastStage = stage;
          log('Stage: $stage');
        }
        buildFailed |=
            line.contains('BUILD FAILED') || line.contains('Failed to load "');
        appException |= line.contains('EXCEPTION CAUGHT');
      }
    }

    log('${options.platform} $coin $phase: starting');
    try {
      final process = _active = await startProcess(
        options.flutter,
        arguments,
        workingDirectory: repository.path,
        environment: environment,
      );
      _stopping = null;
      final streams = Future.wait([
        consume(process.stdout),
        consume(process.stderr),
      ]);
      if (_interrupted) await _stopActive();
      try {
        code = await process.exitCode.timeout(
          phaseTimeout ?? Duration(minutes: options.allCoins ? 90 : 30),
        );
      } on TimeoutException {
        timedOut = true;
        await _stopActive();
        code = 124;
      } finally {
        try {
          await _stopping;
        } finally {
          await streams;
        }
      }
    } finally {
      _active = null;
      _stopping = null;
      await output.close();
    }
    final expected = options.allCoins ? defaultWordCounts.keys.toSet() : {coin};
    final complete =
        completed.length == expected.length && completed.containsAll(expected);
    final passed =
        code == 0 && complete && !_interrupted && !buildFailed && !appException;
    final seconds = (watch.elapsedMilliseconds / 100).round() / 10;
    final failure = _interrupted
        ? 'interrupted'
        : timedOut
        ? 'timeout'
        : code == 0 && !complete
        ? 'incomplete_results'
        : buildFailed
        ? 'build_or_launch'
        : appException
        ? 'test_or_app_exception'
        : 'process_failure';
    log(
      '${options.platform} $coin $phase: '
      '${passed ? 'passed' : 'failed'} (${seconds}s)',
    );
    if (!passed) {
      log('Failure: $failure');
      if (lastStage != null) log('Last stage: $lastStage');
    }
    return {
      'platform': options.platform,
      'device': options.device,
      'coin': coin,
      'phase': phase,
      'status': passed ? 'passed' : 'failed',
      'seconds': seconds,
      'exit_code': code,
      'timed_out': timedOut,
      'completed_coins': completed.toList(),
      'last_stage': lastStage,
      'failure': passed ? null : failure,
    };
  }

  Future<void> _stopActive() {
    final process = _active;
    if (process == null) return Future.value();
    return _stopping ??= stopProcessTree(process, grace: shutdownTimeout)
        .catchError((Object error) {
          _cleanupFailed = true;
          throw error;
        });
  }
}

/// Stop the child app as well as Flutter before removing their test storage.
Future<void> stopProcessTree(Process process, {required Duration grace}) async {
  if (Platform.isWindows) {
    await Process.run('taskkill', ['/PID', '${process.pid}', '/T', '/F']);
    await process.exitCode.timeout(grace);
    return;
  }
  final table = await Process.run('ps', ['-eo', 'pid=,ppid=']);
  if (table.exitCode != 0) {
    throw StateError('Cannot identify test subprocesses.');
  }
  final rows = (table.stdout as String)
      .split('\n')
      .map((line) => line.trim().split(RegExp(r'\s+')))
      .where((row) => row.length == 2)
      .map((row) => (pid: int.parse(row[0]), parent: int.parse(row[1])))
      .toList();
  final ids = <int>{process.pid};
  int previous;
  do {
    previous = ids.length;
    for (final row in rows) {
      if (ids.contains(row.parent)) ids.add(row.pid);
    }
  } while (ids.length != previous);
  for (final id in ids.toList().reversed) {
    Process.killPid(id, ProcessSignal.sigterm);
  }
  Future<List<int>> alive() async {
    final result = await Process.run('ps', [
      '-p',
      ids.join(','),
      '-o',
      'pid=,stat=',
    ]);
    return (result.stdout as String)
        .split('\n')
        .map((line) => line.trim().split(RegExp(r'\s+')))
        .where((row) => row.length == 2 && !row[1].startsWith('Z'))
        .map((row) => int.parse(row[0]))
        .toList();
  }

  final watch = Stopwatch()..start();
  var remaining = await alive();
  while (remaining.isNotEmpty && watch.elapsed < grace) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    remaining = await alive();
  }
  for (final id in remaining) {
    Process.killPid(id, ProcessSignal.sigkill);
  }
  await process.exitCode.timeout(const Duration(seconds: 5));
  for (var attempt = 0; attempt < 50; attempt++) {
    if ((await alive()).isEmpty) return;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  throw StateError(
    'Test subprocesses are still alive; disposable data was retained.',
  );
}

Future<void> main(List<String> arguments) async {
  final parser = argumentParser();
  try {
    final args = parser.parse(arguments);
    if (args['help'] as bool) {
      stdout.writeln(
        'Run wallet creation and separate-process reopening:\n${parser.usage}',
      );
      return;
    }
    if (args['list'] as bool) {
      stdout.writeln(defaultWordCounts.keys.join('\n'));
      return;
    }
    final options = RunOptions.fromResults(args);
    final runner = WalletCreationRunner(
      repository: File.fromUri(Platform.script).absolute.parent.parent,
    );
    final signals = <StreamSubscription<ProcessSignal>>[
      ProcessSignal.sigint.watch().listen((_) => runner.interrupt()),
      if (!Platform.isWindows)
        ProcessSignal.sigterm.watch().listen((_) => runner.interrupt()),
    ];
    try {
      exitCode = await runner.run(options);
    } finally {
      for (final signal in signals) {
        await signal.cancel();
      }
    }
  } on FormatException catch (error) {
    stderr.writeln('${error.message}\n${parser.usage}');
    exitCode = 64;
  } catch (error) {
    stderr.writeln(
      'Wallet creation runner failed (${error.runtimeType}). '
      'Raw app output was not printed.',
    );
    exitCode = 1;
  }
}
