// Run with: dart scripts/tests/xcode_setup_test.dart
import 'dart:io';

import 'package:test/test.dart';

import '../../tool/setup_xcode.dart' as setup;

void main() {
  late Directory root;
  late Directory apps;
  late Directory bin;
  late File calls;

  void script(String path, String body) {
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('#!/bin/bash\nset -eu\n$body\n');
    expect(Process.runSync('chmod', ['+x', path]).exitCode, 0);
  }

  void xcode(String name, String version) {
    final contents = '${apps.path}/$name/Contents';
    Directory(contents).createSync(recursive: true);
    File('$contents/Info.plist').writeAsStringSync(version);
    script('$contents/Developer/usr/bin/xcodebuild', r'''
case "$1" in
  -version) printf 'Xcode %s\nBuild version fixture\n' "${REPORTED_VERSION:-27.0}" ;;
  -runFirstLaunch) echo setup >> "$CALLS"; exit "${SETUP_EXIT:-0}" ;;
  -checkFirstLaunchStatus) echo checked >> "$CALLS" ;;
  *) exit 99 ;;
esac
''');
  }

  setUp(() {
    // Quoting must survive both the shell and AppleScript layers.
    root = Directory.systemTemp.createTempSync("xcode setup ' quotes ");
    apps = Directory('${root.path}/Applications')..createSync();
    bin = Directory('${root.path}/bin')..createSync();
    calls = File('${root.path}/calls');
    script('${bin.path}/id', 'echo "\${FIXTURE_UID:-1000}"');
    script('${bin.path}/uname', 'echo arm64');
    script('${bin.path}/PlistBuddy', r'cat "$3"');
    script('${bin.path}/sudo', r'''
# Exercise the real command sequence without invoking sudo or a real Xcode.
test "$#" = 3
test "$1" = -k
test "$3" = -runFirstLaunch
echo sudo-without-cache >> "$CALLS"
shift
"$@"
''');
    script('${bin.path}/xcodes', r'''
if [ "$*" = 'install --help' ]; then
  echo "${HELP_FLAG:---no-superuser}"
  exit 0
fi
test "$1" = install
test "$2" = 27.0
test "$3" = --directory
test "$5" = --no-superuser
test "$6" = --update
echo download-without-sudo >> "$CALLS"
if [ "${DOWNLOAD_EXIT:-0}" != 0 ]; then exit "$DOWNLOAD_EXIT"; fi
cp -R "$SPARE" "$4/Xcode-27.0.0.app"
''');
    xcode('Spare.app', '27.0');
    Directory('${apps.path}/Spare.app').renameSync('${root.path}/Spare.app');
  });
  tearDown(() => root.delete(recursive: true));

  Future<ProcessResult> runInstaller([Map<String, String> env = const {}]) {
    // Redirect ONLY native/system operations into the fixture. No real sudo,
    // xcodes, Xcode, downloads, or Terminal windows are used by these tests.
    var installer = setup.installerScript
        .replaceAll(
          '/Applications/Xcode*.app',
          '${setup.shellQuote(apps.path)}/Xcode*.app',
        )
        .replaceAll(
          '--directory /Applications',
          '--directory ${setup.shellQuote(apps.path)}',
        )
        .replaceAll('[ ! -t 0 ]', '[ "\${FIXTURE_TTY:-1}" != 1 ]');
    for (final entry in {
      '/usr/bin/id': 'id',
      '/usr/bin/uname': 'uname',
      '/usr/bin/sudo': 'sudo',
      '/usr/libexec/PlistBuddy': 'PlistBuddy',
    }.entries) {
      installer = installer.replaceAll(
        entry.key,
        setup.shellQuote('${bin.path}/${entry.value}'),
      );
    }
    return Process.run(
      '/bin/bash',
      ['--noprofile', '--norc', '-c', installer],
      includeParentEnvironment: false,
      environment: {
        'HOME': root.path,
        'PATH': '${bin.path}:/usr/bin:/bin',
        'CALLS': calls.path,
        'SPARE': '${root.path}/Spare.app',
        ...env,
      },
    );
  }

  group('Xcode setup', () {
    test('downloads with no sudo, then initializes only Xcode 27.0', () async {
      xcode('Xcode.app', '26.0');
      final result = await runInstaller();
      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(calls.readAsLinesSync(), [
        'download-without-sudo',
        'sudo-without-cache',
        'setup',
        'checked',
      ]);
      expect(result.stdout, contains('Setup complete'));
      expect(
        File('${apps.path}/Xcode.app/Contents/Info.plist').readAsStringSync(),
        '26.0',
      );
    });

    test('reuses a manual installation and retries unfinished setup', () async {
      xcode("Xcode-27.0 user's.app", '27.0');
      File('${bin.path}/xcodes').deleteSync();
      final result = await runInstaller();
      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(calls.readAsLinesSync(), [
        'sudo-without-cache',
        'setup',
        'checked',
      ]);
    });

    test('download failure never reaches sudo', () async {
      final result = await runInstaller({'DOWNLOAD_EXIT': '42'});
      expect(result.exitCode, 42);
      expect(calls.readAsLinesSync(), ['download-without-sudo']);
      expect(result.stdout, isNot(contains('Setup complete')));
    });

    test(
      'rejects xcodes without no-superuser support before downloading',
      () async {
        final result = await runInstaller({'HELP_FLAG': 'old version'});
        expect(result.exitCode, isNot(0));
        expect(calls.existsSync(), isFalse);
      },
    );

    test('rejects a mismatched executable before sudo', () async {
      xcode('Xcode-27.0.app', '27.0');
      final result = await runInstaller({'REPORTED_VERSION': '26.0'});
      expect(result.exitCode, isNot(0));
      expect(calls.existsSync(), isFalse);
    });

    test('setup failure does not claim success', () async {
      xcode('Xcode-27.0.app', '27.0');
      final result = await runInstaller({'SETUP_EXIT': '43'});
      expect(result.exitCode, 43);
      expect(calls.readAsLinesSync(), ['sudo-without-cache', 'setup']);
      expect(result.stdout, isNot(contains('Setup complete')));
    });

    for (final env in [
      {'FIXTURE_UID': '0'},
      {'FIXTURE_TTY': '0'},
    ]) {
      test('rejects an unsafe session: ${env.keys.single}', () async {
        final result = await runInstaller(env);
        expect(result.exitCode, isNot(0));
        expect(calls.existsSync(), isFalse);
      });
    }

    test(
      'launcher drops build environment and safely quotes account data',
      () async {
        final home = "${root.path}/\$(touch injected)";
        final command = setup
            .terminalCommand(home: home, user: "user's name")
            .replaceFirst(
              setup.shellQuote(setup.installerScript),
              setup.shellQuote('/usr/bin/env'),
            );
        final result = await Process.run(
          '/bin/sh',
          ['-c', command],
          workingDirectory: root.path,
          includeParentEnvironment: false,
          environment: {
            'BUILD_ONLY': 'fixture',
            'XCODES_PASSWORD': 'fixture',
            'DEVELOPER_DIR': '/wrong/Xcode.app',
            'SUDO_ASKPASS': '/wrong/helper',
            'BASH_ENV': '/wrong/startup',
          },
        );
        expect(result.exitCode, 0, reason: '${result.stderr}');
        final output = result.stdout as String;
        expect(output, contains('HOME=$home\n'));
        expect(output, contains("USER=user's name\n"));
        for (final name in [
          'BUILD_ONLY',
          'XCODES_PASSWORD',
          'DEVELOPER_DIR',
          'SUDO_ASKPASS',
          'BASH_ENV',
        ]) {
          expect(output, isNot(contains('$name=')));
        }
        expect(File('${root.path}/injected').existsSync(), isFalse);
      },
    );

    test('AppleScript round-trips the command without executing it', () async {
      final command = setup.terminalCommand(
        home: '/Users/a "quoted" \\ name\nnext line',
        user: "user's name",
      );
      final appleScript = setup.terminalAppleScript(command);
      final literal = appleScript
          .split('\n')[2]
          .substring('  do script '.length);
      final result = await Process.run('/usr/bin/osascript', [
        '-e',
        'return $literal',
      ]);
      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(result.stdout, '$command\n');
    }, skip: !Platform.isMacOS);
  }, skip: Platform.isWindows ? 'Requires POSIX bash' : false);
}
