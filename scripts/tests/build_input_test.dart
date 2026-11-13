// Run with: dart scripts/tests/build_input_test.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final repository = File.fromUri(Platform.script)
      .absolute
      .parent
      .parent
      .parent;
  late Directory root;
  late Directory scripts;
  late File pubspec;
  const originalConfiguration = 'existing project configuration\n';

  setUp(() async {
    // Spaces also exercise path quoting in build_app.sh and env.sh.
    root = await Directory.systemTemp.createTemp('stack wallet build inputs ');
    scripts = await Directory(p.join(root.path, 'scripts')).create();
    for (final name in ['build_app.sh', 'env.sh', 'prebuild.sh']) {
      await File(p.join(repository.path, 'scripts', name))
          .copy(p.join(scripts.path, name));
    }
    pubspec = File(p.join(root.path, 'pubspec.yaml'));
    await pubspec.writeAsString(originalConfiguration);

    // If validation or confirmation moves after configuration, record the
    // unwanted write and stop before any real build tools can run.
    final templates = await Directory(
      p.join(scripts.path, 'app_config', 'templates'),
    ).create(recursive: true);
    await File(p.join(templates.path, 'configure_template_files.sh'))
        .writeAsString(r'''
printf 'unexpected configuration write\n' > "${APP_PROJECT_ROOT_DIR}/pubspec.yaml"
exit 91
''');
  });
  tearDown(() => root.delete(recursive: true));

  Future<ProcessResult> runBuild({
    required bool fromScripts,
    required String confirmation,
    Map<String, String> overrides = const {},
  }) async {
    final options = {
      'v': '1.2.3',
      'b': '12',
      'p': 'macos',
      'a': 'stack_wallet',
      ...overrides,
    };
    final process = await Process.start('bash', [
      fromScripts ? 'build_app.sh' : 'scripts/build_app.sh',
      for (final option in options.entries) ...['-${option.key}', option.value],
    ], workingDirectory: fromScripts ? scripts.path : root.path);
    final output = process.stdout.transform(utf8.decoder).join();
    final errors = process.stderr.transform(utf8.decoder).join();
    try {
      process.stdin.writeln(confirmation);
      await process.stdin.close();
    } on IOException {
      // Invalid inputs can terminate before bash reads its confirmation input.
    }
    final int code;
    try {
      code = await process.exitCode.timeout(const Duration(seconds: 10));
    } on TimeoutException {
      process.kill(ProcessSignal.sigkill);
      await process.exitCode;
      await Future.wait([output, errors]);
      rethrow;
    }
    return ProcessResult(process.pid, code, await output, await errors);
  }

  group('build input validation', () {
    for (final fromScripts in [false, true]) {
      final location = fromScripts ? 'scripts directory' : 'project root';
      for (final invalid in [
        (option: 'p', value: 'unsupported', message: 'Invalid platform'),
        (option: 'a', value: 'unknown', message: 'Invalid app id'),
        (option: 'v', value: '1.2.3/invalid', message: 'Invalid version'),
        (option: 'b', value: '12-invalid', message: 'Invalid build number'),
        (option: 'w', value: '', message: 'Invalid WSL distribution'),
      ]) {
        test('rejects invalid -${invalid.option} before writes '
            'from $location', () async {
          final result = await runBuild(
            fromScripts: fromScripts,
            // A late check must not be hidden by declining confirmation first.
            confirmation: 'yes',
            overrides: {invalid.option: invalid.value},
          );
          expect(result.exitCode, isNot(0), reason: result.stderr as String);
          expect(result.stdout, contains(invalid.message));
          expect(result.stdout, isNot(contains('Continuing...')));
          expect(await pubspec.readAsString(), originalConfiguration);
        });
      }

      for (final version in ['1.2.3', '0.0.0-staging.123', '1.2.3-rc-1']) {
        test(
          'accepts $version and honors cancellation from $location',
          () async {
            final result = await runBuild(
              fromScripts: fromScripts,
              confirmation: 'no',
              overrides: {'v': version},
            );
            expect(result.exitCode, 0, reason: result.stderr as String);
            expect(result.stdout, isNot(contains('Invalid')));
            expect(result.stdout, isNot(contains('Continuing...')));
            expect(await pubspec.readAsString(), originalConfiguration);
          },
        );
      }
    }
  }, skip: Platform.isWindows ? 'Requires POSIX bash' : false);

  for (final toolchainStatus in [0, 42]) {
    test('Isar toolchain invocation handles exit $toolchainStatus', () async {
      final workspace = Directory(p.join(root.path, 'isar source'))
        ..createSync();
      final core = Directory(p.join(workspace.path, 'isar_core_ffi'))
        ..createSync();
      File(p.join(core.path, 'Cargo.toml')).writeAsStringSync('fixture');
      final calls = File(p.join(root.path, 'rustup-call'));
      final result = await Process.run(
        'bash',
        [
          '-c',
          r'''
source "$1"
rustup() {
  printf '%s\n' "$PWD" "$@" > "$ISAR_TEST_CALLS"
  return "$ISAR_TEST_STATUS"
}
cargo() { return 99; }
build_isar_core "$2" "$3"
''',
          'isar-toolchain-test',
          p.join(repository.path, 'scripts/app_config/templates/isar_build.sh'),
          core.path,
          workspace.path,
        ],
        environment: {
          'ISAR_TEST_CALLS': calls.path,
          'ISAR_TEST_STATUS': '$toolchainStatus',
        },
      );
      expect(
        result.exitCode,
        toolchainStatus == 0 ? 0 : 1,
        reason: '${result.stderr}',
      );
      expect(calls.readAsLinesSync(), [
        core.path,
        'run',
        '--install',
        '1.99.1',
        'cargo',
        'build',
        '--release',
      ]);
    }, skip: Platform.isWindows ? 'Requires POSIX bash' : false);
  }

  group('prebuild', () {
    const coins = [
      'bitcoin',
      'bitcoincash',
      'dogecoin',
      'namecoin',
      'firo',
      'particl',
    ];
    File parameters(String coin) => File(
      p.join(
        root.path,
        'test',
        'services',
        'coins',
        coin,
        '${coin}_wallet_test_parameters.dart',
      ),
    );
    File getKeys() => File(p.join(root.path, 'lib', 'external_api_keys.dart'));
    setUp(() async {
      await Directory(p.join(root.path, 'lib')).create();
      for (final coin in coins) {
        await parameters(coin).parent.create(recursive: true);
      }
    });
    Future<ProcessResult> runPrebuild(Directory cwd) => Process.run('bash', [
      p.join(scripts.path, 'prebuild.sh'),
    ], workingDirectory: cwd.path);
    for (final outsideScripts in [false, true]) {
      final location = outsideScripts
          ? 'another directory'
          : 'the project root';
      test('creates stubs in its project from $location', () async {
        final cwd = outsideScripts
            ? await Directory(p.join(root.path, 'elsewhere')).create()
            : root;
        final result = await runPrebuild(cwd);
        expect(result.exitCode, 0, reason: result.stderr as String);
        expect(await getKeys().exists(), isTrue);
        for (final coin in coins) {
          expect(await parameters(coin).exists(), isTrue);
        }
      });
    }
    test('preserves existing keys and wallet parameters', () async {
      await getKeys().writeAsString('existing test keys\n');
      await parameters('bitcoin').writeAsString('existing test parameters\n');
      final result = await runPrebuild(root);
      expect(result.exitCode, 0, reason: result.stderr as String);
      expect(await getKeys().readAsString(), 'existing test keys\n');
      expect(
        await parameters('bitcoin').readAsString(),
        'existing test parameters\n',
      );
    });
    test(
      'stops at a failed write before creating later wallet stubs',
      () async {
        await Directory(parameters('bitcoin').path).create();
        final result = await runPrebuild(root);
        expect(result.exitCode, isNot(0));
        expect(result.stderr, contains('bitcoin_wallet_test_parameters.dart'));
        expect(await parameters('bitcoincash').exists(), isFalse);
      },
    );
  }, skip: Platform.isWindows ? 'Requires POSIX bash' : false);
}
