// Run with: dart scripts/tests/windows_secp_build_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;
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
  Encoding? vswhereEncoding;

  test('secp pin matches the resolved coinlib Windows recipe', () async {
    // Resolve the dependency selected by pub, not a copied pin or cache path.
    // Updating coinlib must review this contract too.
    final library = await Isolate.resolvePackageUri(
      Uri.parse('package:coinlib/coinlib.dart'),
    );
    expect(library, isNotNull, reason: 'Run flutter pub get before this test.');
    final native = File.fromUri(library!.resolve('../bin/build_windows.dart'))
        .readAsStringSync();
    final nativePin = RegExp(
      r'''["']checkout["']\s*,\s*["']([0-9a-f]{40})["']''',
    ).firstMatch(native)?.group(1);
    expect(
      nativePin,
      secpRevision,
      reason: 'Review the resolved coinlib native Windows secp revision.',
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
    vswhereEncoding = null;
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

  WindowsSecpBuilder builder() => WindowsSecpBuilder(
    root: root,
    environment: {'ProgramFiles(x86)': programFiles},
    cleanup: (directory) {
      if (cleanupLocked) {
        throw FileSystemException('fixture locked directory', directory.path);
      }
      directory.deleteSync(recursive: true);
    },
    run: (executable, args, {workingDirectory, stdoutEncoding}) async {
      calls.add((executable: executable, args: args, cwd: workingDirectory));
      ProcessResult result([String out = '', int status = 0]) =>
          ProcessResult(0, status, out, status == 0 ? '' : 'fixture failure');
      if (executable.endsWith('vswhere.exe')) {
        vswhereEncoding = stdoutEncoding;
        return result(visualStudio);
      }
      if (executable == 'reg.exe') {
        // A standalone SDK registered only in the 32-bit registry view.
        return args.contains('/reg:64')
            ? result('', 1)
            : result('    KitsRoot10    REG_SZ    $sdkRoot\n');
      }
      if (args.length == 1 && args.single == '--version') {
        if (executable == 'cmake') {
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
              '${args[1]}/src/RelWithDebInfo/libsecp256k1-2.dll',
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
    expect(
      calls.singleWhere((c) => c.executable.endsWith('vswhere.exe')).args,
      contains('-utf8'),
    );
    expect(vswhereEncoding, utf8);
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

  test('rejects unsupported CMake', () async {
    cmakeVersion = 'cmake version 3.20.6';
    await expectLater(builder().check(), throwsA(isA<SecpBuildException>()));
    expect(Directory('${root.path}/build').existsSync(), isFalse);
  });

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
      final checkout = operation('checkout').single.cwd!;
      expect(
        p.isWithin('${root.path}/build', checkout),
        isTrue,
        reason: checkout,
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
}
