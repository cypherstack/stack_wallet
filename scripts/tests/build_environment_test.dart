// Run with: dart scripts/tests/build_environment_test.dart
import 'dart:io';

import 'package:test/test.dart';

import '../../tool/check_build_environment.dart';
import '../../tool/native_dependency_contract.dart';

const fixtureXcode = XcodeRequirement(
  version: '27.0',
  build: '27A266a',
  upstreamBuildPinned: false,
);

class HostFixture {
  String os = 'macos';
  String architecture = 'arm64';
  bool rustupOnPath = true;
  bool rustupInHome = false;
  bool nix = true;
  int wslExit = 0;
  String selected = '/Applications/Xcode.app/Contents/Developer';
  final applications = <String>['/Applications/Xcode.app'];
  final versions = <String, String>{
    '/Applications/Xcode.app/Contents/Developer':
        'Xcode ${fixtureXcode.version}\nBuild version ${fixtureXcode.build}\n',
  };
  final calls =
      <
        ({String executable, List<String> arguments, Map<String, String> env})
      >[];

  BuildEnvironment get host => BuildEnvironment(
    os: os,
    architecture: architecture,
    variables: {
      'HOME': '/Users/test',
      'USERPROFILE': r'C:\Users\test',
      'DEVELOPER_DIR': '/Applications/Caller-selected.app/Contents/Developer',
    },
    listXcodes: () async => applications.toList(),
    run: (executable, arguments, environment) async {
      calls.add((
        executable: executable,
        arguments: arguments.toList(),
        env: Map.of(environment),
      ));
      if (executable == 'rustup') {
        if (!rustupOnPath) throw ProcessException(executable, arguments);
        return ProcessResult(0, 0, 'rustup fixture', '');
      }
      if (executable.endsWith('rustup')) {
        if (!rustupInHome) throw ProcessException(executable, arguments);
        return ProcessResult(0, 0, 'rustup fixture', '');
      }
      if (executable == 'nix') {
        if (!nix) throw ProcessException(executable, arguments);
        return ProcessResult(0, 0, 'nix fixture', '');
      }
      if (executable == 'wsl.exe') {
        return ProcessResult(0, wslExit, 'nix fixture', '');
      }
      if (executable == '/usr/bin/xcode-select') {
        return ProcessResult(0, selected.isEmpty ? 1 : 0, selected, '');
      }
      if (executable == '/usr/bin/xcodebuild') {
        final version = versions[environment['DEVELOPER_DIR']];
        return ProcessResult(0, version == null ? 1 : 0, version ?? '', '');
      }
      throw StateError('Unexpected subprocess: $executable $arguments');
    },
  );

  Future<List<String>> check({
    String mode = 'source',
    String platform = 'macos',
    String app = 'stack_wallet',
    String? distribution,
    XcodeRequirement requirement = fixtureXcode,
  }) => checkBuildEnvironment(
    host: host,
    platform: platform,
    app: app,
    mode: mode,
    wslDistribution: distribution,
    xcodeRequirement: mode == 'source' && {'ios', 'macos'}.contains(platform)
        ? requirement
        : null,
  );
}

void main() {
  late HostFixture fixture;
  setUp(() => fixture = HostFixture());

  for (final app in ['stack_wallet', 'stack_duo', 'campfire']) {
    test('$app needs Rustup even with verified prebuilts', () async {
      fixture.rustupOnPath = false;
      final errors = await fixture.check(app: app, mode: 'prebuilt');
      expect(errors.single, contains('Every app needs Rust 1.90.0'));
      expect(errors.single, contains('including with -d'));
      expect(
        fixture.calls.every((call) => call.executable.endsWith('rustup')),
        isTrue,
      );
    });
  }

  test('prebuilt mode skips dnix tools on an Intel Mac', () async {
    fixture.architecture = 'x64';
    fixture.nix = false;
    fixture.applications.clear();
    expect(await fixture.check(mode: 'prebuilt'), isEmpty);
    expect(fixture.calls.single.executable, 'rustup');
  });

  test(
    'finds Rustup in the normal home fallback without installing tools',
    () async {
      fixture.rustupOnPath = false;
      fixture.rustupInHome = true;
      expect(await fixture.check(mode: 'prebuilt'), isEmpty);
      expect(fixture.calls.last.executable, '/Users/test/.cargo/bin/rustup');
      expect(
        fixture.calls.every((call) => call.arguments.join() == '--version'),
        isTrue,
      );
    },
  );

  test('missing Nix fails early with the application -d alternative', () async {
    fixture.nix = false;
    final errors = await fixture.check();
    expect(errors.single, contains('Nix on PATH'));
    expect(errors.single, contains('build_app.sh with -d'));
  });

  test('source mode rejects Intel Macs with an actionable message', () async {
    fixture.architecture = 'x64';
    expect((await fixture.check()).single, contains('Apple Silicon'));
    expect(
      fixture.calls.any((call) => call.executable.contains('xcode')),
      isFalse,
    );
  });

  test('ARM Linux source mode cannot use the Android NDK', () async {
    fixture.os = 'linux';
    expect(
      (await fixture.check(platform: 'android')).single,
      contains('x86_64 Linux'),
    );
    expect(await fixture.check(platform: 'linux'), isEmpty);
  });

  test(
    'WSL distribution is a separate argument; probe only checks Nix',
    () async {
      fixture.os = 'windows';
      const distribution = 'Ubuntu dev; echo "fixture"';
      expect(
        await fixture.check(platform: 'windows', distribution: distribution),
        isEmpty,
      );
      final call = fixture.calls.last;
      expect(call.executable, 'wsl.exe');
      expect(call.arguments.take(2), ['--distribution', distribution]);
      expect(
        call.arguments,
        containsAllInOrder(['--cd', '/', '--exec', '/bin/sh', '-c']),
      );
      expect(call.arguments, contains(wslNixProbe));
      expect(call.arguments.last, 'windows');
      expect(call.env['WSL_UTF8'], '1');
      expect(wslNixProbe, contains(r'"$HOME/.nix-profile/bin"'));
      expect(wslNixProbe, contains('/nix/var/nix/profiles/default/bin'));
      expect(wslNixProbe, contains('/run/current-system/sw/bin'));
      expect(wslNixProbe, contains('nix --version'));
    },
  );

  test(
    'failed WSL probe identifies the distribution and prebuilt alternative',
    () async {
      fixture.os = 'windows';
      fixture.wslExit = 127;
      final errors = await fixture.check(
        platform: 'windows',
        distribution: 'Ubuntu-24.04',
      );
      expect(errors.single, contains('distribution "Ubuntu-24.04"'));
      expect(errors.single, contains('with -d'));
    },
  );

  test('Android cannot build from source in an ARM WSL distribution', () async {
    fixture.os = 'windows';
    fixture.wslExit = 78;
    expect(
      (await fixture.check(platform: 'android')).single,
      contains('x86_64 WSL distribution'),
    );
  });

  for (final os in ['linux', 'windows']) {
    test('Apple targets on a $os host are rejected in both modes', () async {
      fixture.os = os;
      for (final platform in ['ios', 'macos']) {
        for (final mode in ['source', 'prebuilt']) {
          expect(await fixture.check(platform: platform, mode: mode), [
            'Apple targets require a macOS build host.',
          ]);
        }
      }
      expect(fixture.calls, isEmpty);
    });
  }

  for (final os in ['linux', 'macos']) {
    test('Windows configuration on a $os host is rejected', () async {
      fixture.os = os;
      for (final mode in ['source', 'prebuilt']) {
        expect(await fixture.check(platform: 'windows', mode: mode), [
          'Configure Windows builds from Git Bash on Windows.',
        ]);
      }
      expect(fixture.calls, isEmpty);
    });
  }

  test('global GA Xcode wins over an alphabetically earlier beta', () async {
    fixture.applications.insert(0, '/Applications/Xcode-27.0-Beta.app');
    fixture.versions['/Applications/Xcode-27.0-Beta.app/Contents/Developer'] =
        'Xcode 27.0\nBuild version 27A111b\n';
    expect(await fixture.check(), isEmpty);
    final select = fixture.calls.singleWhere(
      (call) => call.executable.endsWith('xcode-select'),
    );
    expect(select.env, isNot(contains('DEVELOPER_DIR')));
    final version = fixture.calls.singleWhere(
      (call) => call.executable.endsWith('xcodebuild'),
    );
    expect(version.env['DEVELOPER_DIR'], fixture.selected);
  });

  test(
    'global beta is rejected even when caller exported GA and GA is installed',
    () async {
      fixture.selected = '/Applications/Xcode-beta.app/Contents/Developer';
      fixture.versions[fixture.selected] =
          'Xcode 27.0\nBuild version 27A111b\n';
      final errors = await fixture.check();
      expect(errors.single, contains('27A111b'));
      expect(errors.single, contains('DEVELOPER_DIR is not forwarded'));
      expect(errors.single, contains('Use -d'));
    },
  );

  test(
    'dnix scan chooses the first matching version, not a later GA',
    () async {
      fixture.selected = '/Library/Developer/CommandLineTools';
      fixture.applications.insert(0, '/Applications/Xcode-27.0-Beta.app');
      fixture.versions['/Applications/Xcode-27.0-Beta.app/Contents/Developer'] =
          'Xcode 27.0\nBuild version 27A111b\n';
      final errors = await fixture.check();
      expect(errors.single, contains('/Applications/Xcode-27.0-Beta.app'));
    },
  );

  test('dnix finds GA when the global selection is another version', () async {
    fixture.selected = '/Applications/Xcode26.app/Contents/Developer';
    fixture.versions[fixture.selected] = 'Xcode 26.0\nBuild version 26A1\n';
    expect(await fixture.check(), isEmpty);
  });

  test('Xcode version comes from the native dependency requirement', () async {
    const futureXcode = XcodeRequirement(
      version: '28.0',
      build: '28A123',
      upstreamBuildPinned: true,
    );
    fixture.applications.add('/Applications/Xcode28.app');
    fixture.versions['/Applications/Xcode28.app/Contents/Developer'] =
        'Xcode 28.0\nBuild version 28A123\n';
    expect(await fixture.check(requirement: futureXcode), isEmpty);
    expect(
      fixture.calls.last.env['DEVELOPER_DIR'],
      '/Applications/Xcode28.app/Contents/Developer',
    );
  });

  test(
    'dnix build pin skips a beta and selects the matching release',
    () async {
      fixture.selected = '/Applications/Xcode-beta.app/Contents/Developer';
      fixture.versions[fixture.selected] =
          'Xcode 27.0\nBuild version 27A111b\n';
      expect(
        await fixture.check(
          requirement: const XcodeRequirement(
            version: '27.0',
            build: '27A266a',
            upstreamBuildPinned: true,
          ),
        ),
        isEmpty,
      );
      expect(
        fixture.calls.last.env['DEVELOPER_DIR'],
        '/Applications/Xcode.app/Contents/Developer',
      );
    },
  );

  test('Apple source builds require metadata before any subprocess', () async {
    await expectLater(
      checkBuildEnvironment(
        host: fixture.host,
        platform: 'macos',
        app: 'stack_wallet',
        mode: 'source',
      ),
      throwsArgumentError,
    );
    expect(fixture.calls, isEmpty);
  });

  test('missing Xcode explains the setup helper', () async {
    fixture.versions.clear();
    expect(
      (await fixture.check()).single,
      contains('dart tool/setup_xcode.dart'),
    );
  });

  for (final distribution in [
    '',
    '-Ubuntu',
    'Ubuntu\nInjected',
    'Ubuntu\x00',
    'Ubuntu\tDev',
    'Ubuntu\x1b',
    'Ubuntu\x7f',
  ]) {
    test(
      'rejects WSL name before subprocesses: ${distribution.codeUnits}',
      () async {
        await expectLater(
          fixture.check(distribution: distribution),
          throwsArgumentError,
        );
        expect(fixture.calls, isEmpty);
      },
    );
  }
}
