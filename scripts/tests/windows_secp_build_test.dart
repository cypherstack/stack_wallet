// Run with: dart scripts/tests/windows_secp_build_test.dart
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

import '../windows/build_secp256k1.dart';

void main() {
  late Directory root;
  late String visualStudio;
  late String programFiles;
  late String sdkRoot;
  late List<({String executable, List<String> args, String? cwd})> calls;
  late String cmakeVersion;
  late Map<String, String> compilerFlags;
  String? failAt;
  bool missingDll = false;

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
    compilerFlags = {};
    failAt = null;
    missingDll = false;
    for (final entry in {
      'scripts/windows/build_secp256k1.dart': 'fixture recipe',
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
    environment: {'ProgramFiles(x86)': programFiles, ...compilerFlags},
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
      if (executable == 'certutil.exe' || executable == 'sha256sum') {
        final file = File(args[executable == 'certutil.exe' ? 1 : 0]);
        return result('${sha256.convert(file.readAsBytesSync())}\n');
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
        if (operation == 'clone') {
          Directory(args.last).createSync(recursive: true);
        } else if (operation != 'checkout') {
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
    expect(operation('clone'), isEmpty);
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
    expect(operation('clone'), isEmpty);
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
      expect(
        File('${root.path}/build/secp256k1.dll.json').existsSync(),
        isTrue,
      );
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
  });

  test('matching receipt avoids cloning and recompiling', () async {
    await builder().build();
    calls.clear();
    await builder().build();
    expect(operation('clone'), isEmpty);
    expect(operation('--build'), isEmpty);
  });

  test('modified DLL invalidates the cache', () async {
    await builder().build();
    File('${root.path}/build/secp256k1.dll').writeAsStringSync('corrupted');
    calls.clear();
    await builder().build();
    expect(operation('clone'), hasLength(1));
    expect(
      File('${root.path}/build/secp256k1.dll').readAsStringSync(),
      'fixture Windows library',
    );
  });

  test('changed compiler host or recipe invalidates the cache', () async {
    await builder().build();
    calls.clear();
    await builder(nativeWindows: false).build();
    expect(operation('clone'), hasLength(1));
    File('${root.path}/scripts/windows/build_secp256k1.dart')
        .writeAsStringSync('changed recipe');
    calls.clear();
    await builder(nativeWindows: false).build();
    expect(operation('clone'), hasLength(1));
  });

  test('changed CMake identity invalidates the cache', () async {
    await builder().build();
    cmakeVersion = 'cmake version 4.1.0';
    calls.clear();
    await builder().build();
    expect(operation('clone'), hasLength(1));
  });

  test('new SDK version invalidates cache and is selected for CMake', () async {
    await builder().build();
    installSdk('10.0.26100.0');
    calls.clear();
    await builder().build();
    expect(operation('clone'), hasLength(1));
    expect(
      operation('-S').single.args,
      contains('-DCMAKE_SYSTEM_VERSION=10.0.26100.0'),
    );
  });

  test('changed explicit compiler flags invalidate the cache', () async {
    await builder().build();
    compilerFlags = {'CL': '/O1', 'LDFLAGS': '-s'};
    calls.clear();
    await builder().build();
    expect(operation('clone'), hasLength(1));
  });

  for (final operation in ['clone', 'checkout', '-S', '--build']) {
    test(
      '$operation failure propagates without publishing a receipt',
      () async {
        failAt = operation;
        await expectLater(
          builder().build(),
          throwsA(isA<SecpBuildException>()),
        );
        expect(
          File('${root.path}/build/secp256k1.dll.json').existsSync(),
          isFalse,
        );
        expect(File('${root.path}/build/secp256k1.dll').existsSync(), isFalse);
      },
    );
  }

  test('a successful CMake exit without the DLL is rejected', () async {
    missingDll = true;
    await expectLater(builder().build(), throwsA(isA<SecpBuildException>()));
    expect(File('${root.path}/build/secp256k1.dll.json').existsSync(), isFalse);
  });
}
