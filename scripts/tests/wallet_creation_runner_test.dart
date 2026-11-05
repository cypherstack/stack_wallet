import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../integration_test/wallet_creation/coin_matrix.dart';
import '../test_wallet_creation.dart';

void main() {
  late Directory root;
  late Directory fixtures;
  late File audit;
  late File fakeFlutter;
  late File report;
  late List<String> output;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('wallet runner ');
    fixtures = await Directory(p.join(root.path, 'fixtures')).create();
    audit = File(p.join(root.path, 'audit.jsonl'));
    report = File(p.join(root.path, 'report.json'));
    fakeFlutter = File(p.join(root.path, 'flutter_fixture.dart'));
    await fakeFlutter.writeAsString(
      _fixture.replaceFirst(
        'COIN_MATRIX_LITERAL',
        jsonEncode(defaultWordCounts.keys.toList()),
      ),
    );
    output = [];
  });
  tearDown(() => root.delete(recursive: true));

  WalletCreationRunner runner({
    String mode = 'pass',
    Duration? timeout,
    String? omitCoin,
  }) => WalletCreationRunner(
    repository: root,
    temporaryParent: fixtures,
    phaseTimeout: timeout,
    shutdownTimeout: const Duration(milliseconds: 100),
    log: output.add,
    startProcess:
        (
          executable,
          arguments, {
          required workingDirectory,
          required environment,
        }) => Process.start(
          Platform.resolvedExecutable,
          [fakeFlutter.path, ...arguments],
          workingDirectory: workingDirectory,
          environment: {
            ...environment,
            'FIXTURE_MODE': mode,
            'FIXTURE_AUDIT': audit.path,
            'FIXTURE_DEVICE_STORAGE': p.join(root.path, 'device'),
            if (omitCoin != null) 'FIXTURE_OMIT_COIN': omitCoin,
          },
        ),
  );

  RunOptions options(List<String> arguments) =>
      RunOptions.parse([...arguments, '--report', report.path]);
  Future<List<Map<String, dynamic>>> events() async =>
      (await audit.readAsLines())
          .map((line) => jsonDecode(line) as Map<String, dynamic>)
          .toList();

  test('the shared matrix covers the 24 base wallets and excludes FROST', () {
    expect(defaultWordCounts, hasLength(24));
    expect(
      defaultWordCounts.keys,
      containsAll(['eCash', 'epicCash', 'monero', 'solana']),
    );
    expect(defaultWordCounts, isNot(contains('bitcoinFrost')));
  });

  test('rejects unsafe or ambiguous targets before launching a process', () {
    for (final arguments in [
      <String>[],
      ['--device', 'phone'],
      ['--device', 'phone', '--platform', 'android'],
      ['--device', 'macos', '--platform', 'linux'],
      ['--device', 'linux', '--all-coins', '--coin', 'bitcoin'],
      ['--device', 'linux', '--coin', 'bitcoinFrost'],
    ]) {
      expect(
        () => RunOptions.parse(arguments),
        throwsFormatException,
        reason: arguments.join(' '),
      );
    }
  });

  test(
    'each desktop coin creates fresh data and reopens only its own state',
    () async {
      final suite = runner();
      expect(
        await suite.run(
          options([
            '--device',
            'linux',
            '--coin',
            'bitcoin',
            '--coin',
            'monero',
          ]),
        ),
        0,
      );
      final calls = await events();
      expect(calls.map((e) => '${e['coin']} ${e['phase']}'), [
        'bitcoin create',
        'bitcoin reopen',
        'monero create',
        'monero reopen',
      ]);
      expect(calls[0]['root'], calls[1]['root']);
      expect(calls[2]['root'], calls[3]['root']);
      expect(calls[0]['root'], isNot(calls[2]['root']));
      expect(await fixtures.list().isEmpty, isTrue);
      expect(suite.results.every((r) => r['status'] == 'passed'), isTrue);
      expect(output.join('\n'), isNot(contains('FAKE_RECOVERY_DATA')));
      expect(
        await report.readAsString(),
        isNot(contains('FAKE_RECOVERY_DATA')),
      );
    },
  );

  test(
    'a desktop creation failure blocks its reopen and continues other coins',
    () async {
      final suite = runner(mode: 'fail-bitcoin');
      expect(
        await suite.run(
          options([
            '--device',
            'linux',
            '--coin',
            'bitcoin',
            '--coin',
            'monero',
          ]),
        ),
        1,
      );
      expect((await events()).map((e) => '${e['coin']} ${e['phase']}'), [
        'bitcoin create',
        'monero create',
        'monero reopen',
      ]);
      expect(suite.results.map((r) => r['status']), [
        'failed',
        'blocked',
        'passed',
        'passed',
      ]);
      expect(await fixtures.list().isEmpty, isTrue);
      expect(output.join('\n'), isNot(contains('FAKE_RECOVERY_DATA')));
      expect(
        await report.readAsString(),
        isNot(contains('FAKE_RECOVERY_DATA')),
      );
    },
  );

  test(
    'mobile phases keep their run ID and use the native platform arguments',
    () async {
      final suite = runner();
      expect(
        await suite.run(
          options([
            '--device',
            'phone',
            '--platform',
            'android',
            '--disposable-mobile',
            '--coin',
            'bitcoin',
          ]),
        ),
        0,
      );
      final calls = await events();
      expect(calls, hasLength(2));
      expect(calls[0]['run_id'], isNotEmpty);
      expect(calls[0]['run_id'], calls[1]['run_id']);
      for (final call in calls) {
        final args = (call['arguments'] as List).cast<String>();
        expect(args, contains('--no-uninstall'));
        expect(args, contains('--dart-define=WALLET_TEST_PLATFORM=android'));
        expect(
          args,
          contains('--dart-define=WALLET_TEST_DISPOSABLE_DEVICE=true'),
        );
        expect(args.any((arg) => arg.contains('WALLET_TEST_ROOT')), isFalse);
        expect(args.any((arg) => arg.contains('layoutPlatform')), isFalse);
      }
    },
  );

  test(
    'a failed mobile case stops and leaves device reset to its operator',
    () async {
      final suite = runner(mode: 'fail-bitcoin');
      expect(
        await suite.run(
          options([
            '--device',
            'phone',
            '--platform',
            'ios',
            '--disposable-mobile',
            '--coin',
            'bitcoin',
            '--coin',
            'monero',
          ]),
        ),
        1,
      );
      expect(await events(), hasLength(1));
      expect(
        File(p.join(root.path, 'device', 'identity')).existsSync(),
        isTrue,
      );
      expect(await fixtures.list().isEmpty, isTrue);
    },
  );

  test(
    'a zero process exit without completed wallet checks cannot pass',
    () async {
      final suite = runner(mode: 'no-markers');
      expect(
        await suite.run(options(['--device', 'linux', '--coin', 'bitcoin'])),
        1,
      );
      expect(await events(), hasLength(1));
      expect(suite.results.first['failure'], 'incomplete_results');
      expect(suite.results.last['status'], 'blocked');
    },
  );

  test(
    'all-coins requires a completion marker for every wallet in both phases',
    () async {
      final suite = runner();
      expect(await suite.run(options(['--device', 'linux', '--all-coins'])), 0);
      for (final result in suite.results) {
        expect(
          result['completed_coins'],
          unorderedEquals(defaultWordCounts.keys),
        );
      }
      expect(await events(), hasLength(2));
    },
  );

  test(
    'an all-coins run missing one wallet fails even when Flutter exits zero',
    () async {
      final suite = runner(omitCoin: 'xelis');
      expect(await suite.run(options(['--device', 'linux', '--all-coins'])), 1);
      expect(suite.results.first['failure'], 'incomplete_results');
      expect(suite.results.first['completed_coins'], hasLength(23));
      expect(await events(), hasLength(1));
    },
  );

  test(
    'timeout stops Flutter and its child before deleting their storage',
    () async {
      final suite = runner(mode: 'stall', timeout: const Duration(seconds: 3));
      expect(
        await suite.run(options(['--device', 'linux', '--coin', 'bitcoin'])),
        1,
      );
      expect(suite.results.first['exit_code'], 124);
      expect(suite.results.first['timed_out'], isTrue);
      final child = int.parse(
        await File(p.join(root.path, 'child.pid')).readAsString(),
      );
      final state = await Process.run('ps', ['-p', '$child', '-o', 'stat=']);
      expect((state.stdout as String).trim(), anyOf(isEmpty, startsWith('Z')));
      expect(await fixtures.list().isEmpty, isTrue);
    },
    skip: Platform.isWindows ? 'POSIX subprocess signal test' : false,
  );

  test('interruption stops the case and writes its report '
      'without starting another coin', () async {
    final suite = runner(mode: 'stall', timeout: const Duration(seconds: 10));
    final running = suite.run(
      options(['--device', 'linux', '--coin', 'bitcoin', '--coin', 'monero']),
    );
    final childFile = File(p.join(root.path, 'child.pid'));
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!await childFile.exists() && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(await childFile.exists(), isTrue);
    suite.interrupt();
    expect(await running, 130);
    expect(await events(), hasLength(1));
    expect(suite.results.first['failure'], 'interrupted');
    expect(await fixtures.list().isEmpty, isTrue);
    expect((jsonDecode(await report.readAsString()) as List), hasLength(2));
  }, skip: Platform.isWindows ? 'POSIX subprocess signal test' : false);

  for (final mode in [
    'false-success-app',
    'false-success-build',
    'false-success-load',
  ]) {
    test(
      'explicit failure rejects zero-exit completion markers: $mode',
      () async {
        final suite = runner(mode: mode);
        expect(
          await suite.run(options(['--device', 'linux', '--coin', 'bitcoin'])),
          1,
        );
        expect(suite.results.first['status'], 'failed');
        expect(
          suite.results.first['failure'],
          mode == 'false-success-app'
              ? 'test_or_app_exception'
              : 'build_or_launch',
        );
        expect(suite.results.last['status'], 'blocked');
      },
    );
  }

  test('ordinary load warning permits a healthy launch', () async {
    final suite = runner(mode: 'benign-load-warning');
    expect(
      await suite.run(options(['--device', 'linux', '--coin', 'bitcoin'])),
      0,
    );
    expect(
      suite.results.every((result) => result['status'] == 'passed'),
      isTrue,
    );
  });
}

const _fixture = r'''
import 'dart:async';
import 'dart:convert';
import 'dart:io';

const supportedCoins = COIN_MATRIX_LITERAL;

Future<void> main(List<String> arguments) async {
  final env = Platform.environment;
  final audit = File(env['FIXTURE_AUDIT']!);
  if (arguments.firstOrNull == 'hold') {
    ProcessSignal.sigterm.watch().listen((_) {});
    Timer.periodic(const Duration(seconds: 1), (_) {});
    await File('${audit.parent.path}/child.pid').writeAsString('${pid}');
    await Completer<void>().future;
    return;
  }
  String? optionalDefine(String name) {
    final prefix = '--dart-define=$name=';
    for (final arg in arguments) {
      if (arg.startsWith(prefix)) return arg.substring(prefix.length);
    }
    return null;
  }
  String define(String name) => optionalDefine(name)!;
  final platform = define('WALLET_TEST_PLATFORM');
  final coin = define('WALLET_TEST_COIN');
  final phase = define('WALLET_TEST_PHASE');
  final root = Directory(platform == 'android' || platform == 'ios'
      ? env['FIXTURE_DEVICE_STORAGE']!
      : define('WALLET_TEST_ROOT'));
  await root.create(recursive: true);
  await audit.writeAsString('${jsonEncode({
    'coin': coin, 'phase': phase, 'platform': platform, 'root': root.path,
    'run_id': optionalDefine('WALLET_TEST_RUN_ID'), 'arguments': arguments,
  })}\n', mode: FileMode.append);
  stdout.writeln('FAKE_RECOVERY_DATA_NOT_FOR_REPORT');
  stdout.writeln('WALLET_CREATION_STAGE $coin: generate');
  stdout.writeln('WALLET_CREATION_STAGE bitcoin: FAKE_RECOVERY_DATA_NOT_FOR_REPORT');
  if (env['FIXTURE_MODE'] == 'stall') {
    ProcessSignal.sigterm.watch().listen((_) {});
    await Process.start(Platform.resolvedExecutable,
        [Platform.script.toFilePath(), 'hold'],
        mode: ProcessStartMode.inheritStdio, environment: env);
    Timer.periodic(const Duration(seconds: 1), (_) {});
    await Completer<void>().future;
    return;
  }
  final identity = File('${root.path}/identity');
  if (phase == 'create') {
    if (await identity.exists()) throw StateError('Creation reused old state');
    await identity.writeAsString(coin);
  } else {
    if (await identity.readAsString() != coin) {
      throw StateError('Reopen used another coin fixture');
    }
  }
  if (env['FIXTURE_MODE'] == 'fail-bitcoin' && coin == 'bitcoin') {
    stderr.writeln('EXCEPTION CAUGHT FAKE_RECOVERY_DATA_NOT_FOR_REPORT');
    exitCode = 1;
    return;
  }
  if (env['FIXTURE_MODE'] == 'no-markers') return;
  if (env['FIXTURE_MODE'] == 'false-success-app') {
    stderr.writeln('EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK');
  }
  if (env['FIXTURE_MODE'] == 'false-success-build') {
    stderr.writeln('BUILD FAILED');
  }
  if (env['FIXTURE_MODE'] == 'false-success-load') {
    stderr.writeln('Failed to load "/tmp/fixture_test.dart": Compilation failed');
  }
  if (env['FIXTURE_MODE'] == 'benign-load-warning') {
    stderr.writeln('Failed to load price data; using cached values');
  }
  for (final id in coin == 'all' ? supportedCoins : [coin]) {
    if (id != env['FIXTURE_OMIT_COIN']) {
      stdout.writeln('flutter: WALLET_CREATION_OK $platform $id $phase');
    }
  }
}
''';
