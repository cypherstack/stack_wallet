// Run with: dart scripts/tests/windows_secp_build_test.dart
import 'dart:io';
import 'dart:isolate';

import 'package:test/test.dart';

import '../windows/build_secp256k1.dart';

void main() {
  late Directory root;
  late String visualStudio;
  late String programFiles;
  late String sdkRoot;
  late List<({String executable, List<String> args, String? cwd})> calls;
  late String cmakeVersion;
  String? failAt;
  bool missingDll = false;
  bool cleanupLocked = false;

  test('secp pin matches resolved coinlib Windows recipes', () async {
    // Resolve the dependency selected by pub, not a copied pin or cache path.
    // Updating coinlib must review this contract too.
    final library = await Isolate.resolvePackageUri(
      Uri.parse('package:coinlib/coinlib.dart'),
    );
    expect(library, isNotNull, reason: 'Run flutter pub get before this test.');
    final native = File.fromUri(library!.resolve('../bin/build_windows.dart'))
        .readAsStringSync();
    final cross = File.fromUri(
      library.resolve('../bin/build_windows_crosscompile.dart'),
    ).readAsStringSync();
    final nativePin = RegExp(
      r'''["']checkout["']\s*,\s*["']([0-9a-f]{40})["']''',
    ).firstMatch(native)?.group(1);
    final crossPin = RegExp(r'git\s+checkout\s+([0-9a-f]{40})\b')
        .firstMatch(cross)
        ?.group(1);
    expect(
      nativePin,
      secpRevision,
      reason: 'Review the resolved coinlib native Windows secp revision.',
    );
    expect(
      crossPin,
      secpRevision,
      reason: 'Review the resolved coinlib cross-build secp revision.',
    );
  });

  void installSdk(String version) {
    for (final relative in [
      'Include/$version/um/Windows.h',
      'Include/$version/shared/sdkddkver.h',
      'Include/$version/ucrt/stdlib.h',
      'Lib/$version/um/x64/kernel32.lib',
      'Lib/$version/ucrt/x64/ucrt.lib',
      'bin/$version/x64/rc.exe',
      'bin/$version/x64/mt.exe',
    ]) {
      final file = File('$sdkRoot/$relative');
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('SDK fixture');
    }
  }

  setUp(() {
    root = Directory.systemTemp.createTempSync(
      'windows secp path with spaces ',
    );
    programFiles = '${root.path}/Program Files (x86)';
    visualStudio = '${root.path}/Visual Studio';
    sdkRoot = '${root.path}/Standalone SDK';
    installSdk('10.0.22621.0');
    calls = [];
    cmakeVersion = 'cmake version 3.31.6';
    failAt = null;
    missingDll = false;
    cleanupLocked = false;
    for (final entry in {
      'Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe':
          'fixture',
      'Visual Studio/VC/Auxiliary/Build/Microsoft.VCToolsVersion.default.txt':
          '14.44.1',
      'Visual Studio/Common7/IDE/CommonExtensions/Microsoft/CMake/CMake/bin/cmake.exe':
          'fixture',
    }.entries) {
      final file = File('${root.path}/${entry.key}');
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(entry.value);
    }
  });
  tearDown(() => root.delete(recursive: true));

  WindowsSecpBuilder builder({bool nativeWindows = true}) => WindowsSecpBuilder(
    root: root,
    nativeWindows: nativeWindows,
    environment: {'ProgramFiles(x86)': programFiles},
    cleanup: (directory) {
      if (cleanupLocked) {
        throw FileSystemException('fixture locked directory', directory.path);
      }
      directory.deleteSync(recursive: true);
    },
    run: (executable, args, {workingDirectory}) async {
      calls.add((executable: executable, args: args, cwd: workingDirectory));
      ProcessResult result([String out = '', int status = 0]) =>
          ProcessResult(0, status, out, status == 0 ? '' : 'fixture failure');
      if (executable.endsWith('vswhere.exe')) return result(visualStudio);
      if (executable == 'reg.exe') {
        // A standalone SDK registered only in the 32-bit registry view.
        return args.contains('/reg:64')
            ? result('', 1)
            : result('    KitsRoot10    REG_SZ    $sdkRoot\n');
      }
      if (args.length == 1 && args.single == '--version') {
        if (executable == 'cmake' && nativeWindows) {
          return result('cmake version 3.12.0');
        }
        return result(
          executable.contains('cmake') ? cmakeVersion : 'tool version',
        );
      }
      final operation = args.first;
      if (operation == failAt) return result('', 42);
      if (executable == 'git') {
        if (operation == 'init') {
          Directory(args.last).createSync(recursive: true);
        } else if (operation != 'checkout' && operation != 'fetch') {
          fail('Unexpected git invocation: $args');
        }
        return result();
      }
      if (executable.contains('cmake')) {
        if (operation == '-S') return result();
        if (operation == '--build') {
          if (!missingDll) {
            final file = File(
              '${args[1]}/src/${nativeWindows ? 'RelWithDebInfo/' : ''}libsecp256k1-2.dll',
            );
            file.parent.createSync(recursive: true);
            file.writeAsStringSync('fixture Windows library');
          }
          return result();
        }
      }
      fail('Unexpected command: $executable $args');
    },
  );

  List<({String executable, List<String> args, String? cwd})> operation(
    String arg,
  ) => calls.where((c) => c.args.isNotEmpty && c.args.first == arg).toList();

  test('preflight discovers VS CMake without creating build outputs', () async {
    await builder().check();
    expect(Directory('${root.path}/build').existsSync(), isFalse);
    expect(operation('fetch'), isEmpty);
    expect(calls.any((c) => c.executable == 'cmake'), isFalse);
    expect(
      calls.any(
        (c) =>
            c.executable ==
            '$visualStudio/Common7/IDE/CommonExtensions/Microsoft/CMake/CMake/bin/cmake.exe',
      ),
      isTrue,
    );
  });

  test('missing Windows SDK fails preflight before creating outputs', () async {
    Directory(sdkRoot).deleteSync(recursive: true);
    await expectLater(builder().check(), throwsA(isA<SecpBuildException>()));
    expect(Directory('${root.path}/build').existsSync(), isFalse);
    expect(operation('fetch'), isEmpty);
  });

  test('incomplete x64 SDK is rejected', () async {
    File('$sdkRoot/Lib/10.0.22621.0/um/x64/kernel32.lib').deleteSync();
    await expectLater(builder().check(), throwsA(isA<SecpBuildException>()));
    expect(Directory('${root.path}/build').existsSync(), isFalse);
  });

  for (final native in [true, false]) {
    test(
      'rejects unsupported CMake on ${native ? 'Windows' : 'Linux'}',
      () async {
        cmakeVersion = native ? 'cmake version 3.20.6' : 'cmake version 3.12.4';
        await expectLater(
          builder(nativeWindows: native).check(),
          throwsA(isA<SecpBuildException>()),
        );
        expect(Directory('${root.path}/build').existsSync(), isFalse);
      },
    );
  }

  test(
    'native build pins v0.5.0 and writes DLL relative to repository',
    () async {
      await builder().build();
      expect(operation('checkout').single.args, [
        'checkout',
        '--detach',
        secpRevision,
      ]);
      expect(operation('fetch').single.args, [
        'fetch',
        '--depth',
        '1',
        '--no-tags',
        'https://github.com/bitcoin-core/secp256k1.git',
        secpRevision,
      ]);
      expect(
        operation('checkout').single.cwd,
        startsWith('${root.path}/build/'),
      );
      final configure = operation('-S').single.args;
      expect(
        configure,
        containsAll([
          'Visual Studio 17 2022',
          '-A',
          'x64',
          '-DSECP256K1_ENABLE_MODULE_RECOVERY=ON',
          '-DCMAKE_SYSTEM_VERSION=10.0.22621.0',
        ]),
      );
      expect(
        File('${root.path}/build/secp256k1.dll').readAsStringSync(),
        'fixture Windows library',
      );
      expect(Directory('${root.path}/build').listSync(), hasLength(1));
    },
  );

  test('WSL uses the same revision, with its MinGW toolchain', () async {
    await builder(nativeWindows: false).build();
    expect(operation('checkout').single.args.last, secpRevision);
    expect(operation('-S').single.args, contains('Unix Makefiles'));
    expect(
      operation('-S').single.args
          .any((a) => a.endsWith('/cmake/x86_64-w64-mingw32.toolchain.cmake')),
      isTrue,
    );
    expect(File('${root.path}/build/secp256k1.dll').existsSync(), isTrue);
    expect(calls.any((c) => c.executable.contains('mingw32-g++')), isFalse);
  });

  test('an existing DLL is rebuilt on every invocation', () async {
    await builder().build();
    calls.clear();
    await builder().build();
    expect(operation('fetch'), hasLength(1));
    expect(operation('--build'), hasLength(1));
    expect(
      File('${root.path}/build/secp256k1.dll').readAsStringSync(),
      'fixture Windows library',
    );
  });

  test('the newest complete SDK is selected for CMake', () async {
    installSdk('10.0.26100.0');
    await builder().build();
    expect(
      operation('-S').single.args,
      contains('-DCMAKE_SYSTEM_VERSION=10.0.26100.0'),
    );
  });

  for (final operation in ['init', 'fetch', 'checkout', '-S', '--build']) {
    test('$operation failure propagates without publishing a DLL', () async {
      failAt = operation;
      await expectLater(builder().build(), throwsA(isA<SecpBuildException>()));
      expect(File('${root.path}/build/secp256k1.dll').existsSync(), isFalse);
    });
  }

  test(
    'a missing built DLL is rejected and preserves the previous DLL',
    () async {
      final output = File('${root.path}/build/secp256k1.dll');
      output.parent.createSync(recursive: true);
      output.writeAsStringSync('previous Windows library');
      missingDll = true;
      await expectLater(builder().build(), throwsA(isA<SecpBuildException>()));
      expect(output.readAsStringSync(), 'previous Windows library');
    },
  );

  test('locked cleanup leaves a successfully published DLL usable', () async {
    cleanupLocked = true;
    await builder().build();
    expect(File('${root.path}/build/secp256k1.dll').existsSync(), isTrue);
  });

  test('locked cleanup never masks the original build failure', () async {
    cleanupLocked = true;
    failAt = '--build';
    await expectLater(
      builder().build(),
      throwsA(
        isA<SecpBuildException>().having(
          (e) => e.message,
          'message',
          contains('--build'),
        ),
      ),
    );
    expect(File('${root.path}/build/secp256k1.dll').existsSync(), isFalse);
  });

  group('WSL entry point', () {
    late Directory bin;
    late File shim;
    late File recorded;
    setUp(() {
      bin = Directory('${root.path}/bin')..createSync();
      final repository = File.fromUri(Platform.script).parent.parent.parent;
      shim = File('${root.path}/build_secp256k1_wsl.sh');
      File('${repository.path}/scripts/windows/build_secp256k1_wsl.sh')
          .copySync(shim.path);
      recorded = File('${root.path}/dart-arguments');
      final fakeDart = File('${bin.path}/dart')
        ..writeAsStringSync(r'''#!/bin/sh
if [ "$1" = --version ]; then
  printf 'Dart SDK version: fixture on "%s"\n' "$FIXTURE_DART_HOST" >&2
  exit 0
fi
printf '%s\n' "$@" > "$FIXTURE_ARGUMENTS"
exit 37
''');
      expect(Process.runSync('chmod', ['+x', fakeDart.path]).exitCode, 0);
    });
    Future<ProcessResult> invoke(String host) => Process.run(
      '/bin/bash',
      [shim.path, '--check'],
      environment: {
        'PATH': '${bin.path}:/usr/bin:/bin',
        'FIXTURE_DART_HOST': host,
        'FIXTURE_ARGUMENTS': recorded.path,
      },
    );

    test('Linux SDK runs the helper and propagates its status', () async {
      final result = await invoke('linux_x64');
      expect(result.exitCode, 37);
      expect(recorded.readAsLinesSync(), [
        '${root.path}/build_secp256k1.dart',
        '--check',
      ]);
    });

    test(
      'Windows Flutter on WSL PATH fails before invoking the helper',
      () async {
        final result = await invoke('windows_x64');
        expect(result.exitCode, 1);
        expect(result.stderr, contains("Linux SDK's bin directory"));
        expect(recorded.existsSync(), isFalse);
      },
    );
  }, skip: Platform.isWindows ? 'Requires POSIX bash' : false);
}
