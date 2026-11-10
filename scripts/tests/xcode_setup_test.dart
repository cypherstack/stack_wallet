// Run with: dart scripts/tests/xcode_setup_test.dart
import 'dart:io';

import 'package:test/test.dart';

import '../../tool/setup_xcode.dart' as setup;

void main() {
  const fixtureVersion = '27.0';
  const fixtureBuild = '27A266a';
  late Directory root;
  late Directory apps;
  late Directory bin;
  late File calls;
  late setup.SetupTools tools;

  void script(String path, String body) {
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('#!/bin/bash\nset -eu\n$body\n');
    expect(Process.runSync('chmod', ['+x', path]).exitCode, 0);
  }

  void xcode(
    String name, {
    String version = fixtureVersion,
    String build = fixtureBuild,
  }) {
    final contents = '${apps.path}/$name/Contents';
    Directory(contents).createSync(recursive: true);
    File('$contents/Info.plist').writeAsStringSync(version);
    File('$contents/version.plist').writeAsStringSync(build);
    script('$contents/Developer/usr/bin/xcodebuild', r'''
case "$1" in
  -version) printf 'Xcode %s\nBuild version %s\n' "${REPORTED_VERSION:-27.0}" "${REPORTED_BUILD:-27A266a}" ;;
  -runFirstLaunch) echo setup >> "$CALLS"; exit "${SETUP_EXIT:-0}" ;;
  -checkFirstLaunchStatus) echo checked >> "$CALLS" ;;
  *) exit 99 ;;
esac
''');
  }

  setUp(() {
    root = Directory.systemTemp.createTempSync("xcode setup ' quotes ");
    apps = Directory('${root.path}/Applications')..createSync();
    bin = Directory('${root.path}/bin')..createSync();
    calls = File('${root.path}/calls');
    tools = setup.SetupTools(
      applications: apps.path,
      id: '${bin.path}/id',
      uname: '${bin.path}/uname',
      plistBuddy: '${bin.path}/PlistBuddy',
      sudo: '${bin.path}/sudo',
    );
    script(tools.id, 'echo "\${FIXTURE_UID:-1000}"');
    script(tools.uname, 'echo arm64');
    script(tools.plistBuddy, r'cat "$3"');
    script(tools.sudo, r'''
# No actual elevation: only our fixture xcodebuild may run.
test "$#" = 3
test "$1" = -k
test "$3" = -runFirstLaunch
case "$2" in "$FIXTURE_APPS"/*/Contents/Developer/usr/bin/xcodebuild) ;; *) exit 98;; esac
echo sudo-without-cache >> "$CALLS"
shift
"$@"
''');
    script('${bin.path}/xcodes', r'''
if [ "$*" = 'install --help' ]; then
  if [ "${HELP_EXIT:-0}" != 0 ]; then exit "$HELP_EXIT"; fi
  echo "${HELP_FLAG:---no-superuser}"
  exit 0
fi
test "$#" = 6
test "$1" = install
test "$2" = 27.0
test "$3" = --directory
test "$4" = "$FIXTURE_APPS"
test "$5" = --no-superuser
test "$6" = --update
echo download-without-sudo >> "$CALLS"
if [ "${DOWNLOAD_EXIT:-0}" != 0 ]; then exit "$DOWNLOAD_EXIT"; fi
cp -R "$SPARE" "$4/Xcode-27.0.0.app"
''');
    xcode('Spare.app');
    Directory('${apps.path}/Spare.app').renameSync('${root.path}/Spare.app');
  });
  tearDown(() => root.delete(recursive: true));

  Future<ProcessResult> runInstaller({
    Map<String, String> env = const {},
    bool interactive = false,
    String? xcodes,
  }) {
    // Pass fixture dependencies explicitly. No string substitution can silently
    // fail and leave a real privileged command in the script under test.
    for (final executable in [
      tools.id,
      tools.uname,
      tools.plistBuddy,
      tools.sudo,
    ]) {
      expect(executable, startsWith('${bin.path}/'));
      expect(File(executable).existsSync(), isTrue);
    }
    final installer = setup.installerScript(
      home: root.path,
      user: 'fixture',
      version: fixtureVersion,
      build: fixtureBuild,
      xcodes: xcodes ?? '${bin.path}/xcodes',
      tools: tools,
      interactive: interactive,
    );
    return Process.run(
      '/bin/bash',
      ['--noprofile', '--norc', '-c', installer],
      includeParentEnvironment: false,
      environment: {
        'CALLS': calls.path,
        'FIXTURE_APPS': apps.path,
        'SPARE': '${root.path}/Spare.app',
        ...env,
      },
    );
  }

  group('Xcode setup', () {
    test(
      'downloads without sudo, then initializes only the release build',
      () async {
        xcode('Xcode.app', version: '26.0');
        final result = await runInstaller();
        expect(result.exitCode, 0, reason: '${result.stderr}');
        expect(calls.readAsLinesSync(), [
          'download-without-sudo',
          'sudo-without-cache',
          'setup',
          'checked',
        ]);
        expect(result.stdout, contains('Setup complete'));
        expect(result.stdout, contains('Xcode-27.0.0.app'));
        expect(
          File('${apps.path}/Xcode.app/Contents/Info.plist').readAsStringSync(),
          '26.0',
        );
      },
    );

    test('same-version build conflict gives a safe manual recovery', () async {
      xcode('Xcode-27.0.0-Beta.1.app', build: '27A5001a');
      final result = await runInstaller();
      expect(result.exitCode, isNot(0));
      expect(calls.existsSync(), isFalse);
      expect(result.stderr, contains('another build of the same version'));
      expect(result.stderr, contains('Xcode-27.0-27A266a.app'));
      expect(result.stderr, contains('left untouched'));
      expect(
        File('${apps.path}/Xcode-27.0.0-Beta.1.app/Contents/version.plist')
            .readAsStringSync(),
        '27A5001a',
      );

      // Follow the proposed recovery without uninstalling the older build.
      xcode('Xcode-27.0-27A266a.app');
      final recovered = await runInstaller();
      expect(recovered.exitCode, 0, reason: '${recovered.stderr}');
      expect(calls.readAsLinesSync(), [
        'sudo-without-cache',
        'setup',
        'checked',
      ]);
    });

    test(
      'skips a sorting-first beta and reuses a manually installed release',
      () async {
        xcode('Xcode-27.0-Beta.app', build: '27A5001a');
        xcode("Xcode-27.0 user's.app");
        File('${bin.path}/xcodes').deleteSync();
        final result = await runInstaller();
        expect(result.exitCode, 0, reason: '${result.stderr}');
        expect(calls.readAsLinesSync(), [
          'sudo-without-cache',
          'setup',
          'checked',
        ]);
        expect(result.stdout, contains("Xcode-27.0 user's.app"));
      },
    );

    test('download failure never reaches sudo', () async {
      final result = await runInstaller(env: {'DOWNLOAD_EXIT': '42'});
      expect(result.exitCode, 42);
      expect(calls.readAsLinesSync(), ['download-without-sudo']);
      expect(result.stdout, isNot(contains('Setup complete')));
    });

    test(
      'rejects xcodes without no-superuser support before downloading',
      () async {
        final result = await runInstaller(env: {'HELP_FLAG': 'old version'});
        expect(result.exitCode, isNot(0));
        expect(calls.existsSync(), isFalse);
      },
    );

    test('explains xcodes shim failure without forwarding build env', () async {
      final result = await runInstaller(env: {'HELP_EXIT': '44'});
      expect(result.exitCode, isNot(0));
      expect(calls.existsSync(), isFalse);
      expect(result.stderr, contains('HOME with a clean setup environment'));
      expect(result.stderr, contains('globally configured xcodes'));
    });

    for (final env in [
      {'REPORTED_VERSION': '26.0'},
      {'REPORTED_BUILD': '27A5001a'},
    ]) {
      test(
        'rejects mismatched executable metadata: ${env.keys.single}',
        () async {
          xcode('Xcode-27.0.app');
          final result = await runInstaller(env: env);
          expect(result.exitCode, isNot(0));
          expect(calls.existsSync(), isFalse);
        },
      );
    }

    test('setup failure does not claim success', () async {
      xcode('Xcode-27.0.app');
      final result = await runInstaller(env: {'SETUP_EXIT': '43'});
      expect(result.exitCode, 43);
      expect(calls.readAsLinesSync(), ['sudo-without-cache', 'setup']);
      expect(result.stdout, isNot(contains('Setup complete')));
    });

    test('rejects a root session before downloading', () async {
      final result = await runInstaller(env: {'FIXTURE_UID': '0'});
      expect(result.exitCode, isNot(0));
      expect(calls.existsSync(), isFalse);
    });

    test('interactive setup rejects a pipe before downloading', () async {
      final result = await runInstaller(interactive: true);
      expect(result.exitCode, isNot(0));
      expect(calls.existsSync(), isFalse);
    });

    test(
      'resolves nonstandard PATH installations before cleaning the environment',
      () async {
        final directory = Directory("${root.path}/Mint user's/bin")
          ..createSync(recursive: true);
        final executable = '${directory.path}/xcodes';
        File('${bin.path}/xcodes').copySync(executable);
        final resolved = setup.findXcodes('.:${directory.path}:/missing');
        expect(resolved, executable);
        expect(setup.findXcodes('.::relative'), isNull);
        final result = await runInstaller(xcodes: resolved);
        expect(result.exitCode, 0, reason: '${result.stderr}');
        expect(calls.readAsLinesSync().first, 'download-without-sudo');
      },
    );

    test(
      'preserves symlink shim dispatch name and its PATH directory',
      () async {
        final backend = '${root.path}/mise backend/mise';
        final shims = Directory('${root.path}/mise shims')..createSync();
        script(backend, r'''
test "${0##*/}" = xcodes
test "$(command -v xcodes)" = "$0"
exec "$FIXTURE_XCODES" "$@"
''');
        final executable = '${shims.path}/xcodes';
        Link(executable).createSync(backend);
        final found = setup.findXcodes('${shims.path}:/usr/bin:/bin');
        expect(found, executable);
        final result = await runInstaller(
          xcodes: found,
          env: {'FIXTURE_XCODES': '${bin.path}/xcodes'},
        );
        expect(result.exitCode, 0, reason: '${result.stderr}');
        expect(calls.readAsLinesSync().first, 'download-without-sudo');
      },
    );

    test(
      'missing xcodes explains caller PATH instead of assuming Homebrew',
      () async {
        final result = await runInstaller(xcodes: '/missing/xcodes');
        expect(result.exitCode, isNot(0));
        expect(result.stderr, contains('PATH when setup was launched'));
        expect(calls.existsSync(), isFalse);
      },
    );

    for (final shell in ['/bin/bash', '/bin/tcsh']) {
      test(
        'short launcher works with $shell and removes the build environment',
        () async {
          final temporary = Directory('/tmp')
              .createTempSync('stack-xcode-setup-');
          addTearDown(() => temporary.delete(recursive: true));
          final installer = File('${temporary.path}/setup.sh')
            ..writeAsStringSync('/usr/bin/env\n');
          final command = setup.terminalCommand(installer.path);
          expect(command, isNot(contains('\n')));
          final result = await Process.run(
            shell,
            ['-f', '-c', command],
            includeParentEnvironment: false,
            environment: {
              'BUILD_ONLY': 'fixture',
              'XCODES_PASSWORD': 'fixture',
              'DEVELOPER_DIR': '/wrong/Xcode.app',
              'SUDO_ASKPASS': '/wrong/helper',
            },
          );
          expect(result.exitCode, 0, reason: '${result.stderr}');
          final output = result.stdout as String;
          for (final name in [
            'BUILD_ONLY',
            'XCODES_PASSWORD',
            'DEVELOPER_DIR',
            'SUDO_ASKPASS',
          ]) {
            expect(output, isNot(contains('$name=')));
          }
        },
        skip: !File(shell).existsSync() ? '$shell is not installed' : false,
      );
    }

    test('launcher rejects a path that a login shell could reinterpret', () {
      expect(
        () => setup.terminalCommand('/tmp/user name/setup.sh'),
        throwsArgumentError,
      );
      expect(
        () => setup.terminalCommand(
          '/tmp/stack-xcode-setup-abc/setup.sh;touch evil',
        ),
        throwsArgumentError,
      );
    });

    test('the Terminal AppleScript compiles without executing it', () async {
      final command = setup.terminalCommand(
        '/tmp/stack-xcode-setup-fixture/setup.sh',
      );
      final appleScript = setup.terminalAppleScript(command);
      // Compile only: no Terminal window or privileged command runs.
      final output = '${root.path}/setup.scpt';
      final result = await Process.run('/usr/bin/osacompile', [
        '-o',
        output,
        '-e',
        appleScript,
      ]);
      expect(result.exitCode, 0, reason: '${result.stderr}');
    }, skip: !Platform.isMacOS ? 'Requires macOS osacompile' : false);

    test(
      'completion waits for acknowledgement on a real terminal',
      () async {
        // Use a fixture pseudo-terminal, never Terminal.app or native tools.
        final probe = File('${root.path}/finish.sh')
          ..writeAsStringSync(
            setup.installerScript(
              home: root.path,
              user: 'fixture',
              version: fixtureVersion,
              build: fixtureBuild,
              tools: tools,
              interactive: true,
            ),
          );
        xcode('Xcode-27.0.app');
        final process = await Process.start(
          '/usr/bin/script',
          ['-q', '/dev/null', '/bin/bash', probe.path],
          includeParentEnvironment: false,
          environment: {'CALLS': calls.path, 'FIXTURE_APPS': apps.path},
        );
        final text = StringBuffer();
        var sawPrompt = false;
        final subscription = process.stdout.listen((chunk) {
          text.write(String.fromCharCodes(chunk));
          if (!sawPrompt && text.toString().contains('Press Return to close')) {
            sawPrompt = true;
            process.stdin.writeln();
          }
        });
        final errors = process.stderr.drain<void>();
        try {
          expect(
            await process.exitCode.timeout(const Duration(seconds: 10)),
            0,
          );
          await subscription.cancel();
          await errors;
          expect(sawPrompt, isTrue);
          expect(text.toString(), contains('Setup complete'));
        } finally {
          process.kill(ProcessSignal.sigkill);
          await process.stdin.close();
        }
      },
      skip: !Platform.isMacOS ? 'Requires macOS script pseudo-terminal' : false,
    );
  }, skip: Platform.isWindows ? 'Requires POSIX bash' : false);
}
