// Run with: dart scripts/tests/native_build_config_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../../tool/configure_native_assets.dart';

void main() {
  final repository = File.fromUri(Platform.script).parent.parent.parent;
  const packages = {
    'stack_wallet': {
      'frostdart',
      'tor_ffi_plugin',
      'flutter_libepiccash',
      'flutter_libmwc',
    },
    'stack_duo': {'frostdart', 'tor_ffi_plugin'},
    'campfire': {'tor_ffi_plugin'},
  };
  final allPackages = packages['stack_wallet']!;
  late Directory root;
  late Directory bin;

  void copyFile(String relative) {
    final destination = File(p.join(root.path, relative));
    destination.parent.createSync(recursive: true);
    File(p.join(repository.path, relative)).copySync(destination.path);
  }

  void copyDirectory(String relative) {
    for (final file in Directory(
      p.join(repository.path, relative),
    ).listSync(recursive: true).whereType<File>()) {
      copyFile(p.relative(file.path, from: repository.path));
    }
  }

  void script(String relative, String body) {
    final file = File(p.join(root.path, relative));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('#!/bin/sh\nset -eu\n$body\n');
    final result = Process.runSync('chmod', ['+x', file.path]);
    expect(result.exitCode, 0, reason: '${result.stderr}');
  }

  setUp(() {
    root = Directory.systemTemp.createTempSync('dnix build inputs ');
    bin = Directory(p.join(root.path, 'bin'))..createSync();
    for (final directory in ['linux', 'assets/windows', 'lib/wl_gen']) {
      Directory(p.join(root.path, directory)).createSync(recursive: true);
    }
    for (final file in [
      'scripts/build_app.sh',
      'scripts/env.sh',
      'scripts/app_config/shared/update_version.sh',
      'tool/process_pubspec_deps.dart',
      'tool/configure_native_assets.dart',
      'tool/gen_interfaces.dart',
      for (final app in packages.keys) 'scripts/app_config/configure_$app.sh',
    ]) {
      copyFile(file);
    }
    copyDirectory('scripts/app_config/templates');
    copyDirectory('tool/wl_templates');
    for (final app in packages.keys) {
      final icon = File(
        p.join(
          root.path,
          'asset_sources/other/playstore_icon',
          app,
          'app_icon-playstore.png',
        ),
      );
      icon.parent.createSync(recursive: true);
      icon.writeAsStringSync('fixture icon');
    }
    // Keep the real app/template renderers. Stub only assets and native tools,
    // so this test never downloads a library or requires Nix, Xcode or Go.
    script('scripts/app_config/shared/link_assets.sh', ':');
    script('scripts/app_config/shared/asset_generators.sh', r'''
cp "$APP_PROJECT_ROOT_DIR/pubspec.yaml" "$APP_PROJECT_ROOT_DIR/before-assets.yaml"
''');
    for (final platform in ['macos', 'windows', 'linux']) {
      script('scripts/app_config/platforms/$platform/platform_config.sh', ':');
    }
    for (final dependency in ['secure_storage_deps', 'secp256k1']) {
      script('scripts/linux/build_$dependency.sh', '''
printf '%s\\n' '$dependency' >> "\$APP_PROJECT_ROOT_DIR/linux-deps"
pwd > "\$APP_PROJECT_ROOT_DIR/native-cwd"
''');
    }
    script('bin/git', r'''
test "$1" = log
printf '0000000000000000000000000000000000000000\n'
''');
    // Invoke this SDK directly: Flutter's dart launcher also calls git/uname,
    // which are simulated below to exercise the Windows dispatch on POSIX.
    final dart = Platform.resolvedExecutable.replaceAll("'", "'\\''");
    script('bin/dart', "exec '$dart' \"\$@\"");
    script('bin/uname', r'''
if [ -n "${DNIX_TEST_HOST:-}" ]; then
  printf '%s\n' "$DNIX_TEST_HOST"
else
  exec /usr/bin/uname "$@"
fi
''');
    script('bin/sha256sum', "printf 'fixture-hash  mwebd.exe\\n'");
    // The real preflight/helper have separate tests with injected native tools.
    // These fixtures exercise their position in the configuration flow and cwd.
    File(p.join(root.path, 'tool/check_build_environment.dart'))
        .writeAsStringSync('''
import 'dart:convert';
import 'dart:io';
void main(List<String> args) {
  final root = File.fromUri(Platform.script).parent.parent;
  File('\${root.path}/preflight-args').writeAsStringSync(jsonEncode(args));
  if (Platform.environment['DNIX_TEST_PREFLIGHT_FAIL'] == '1') exit(21);
}
''');
    final windowsHelper = File(
      p.join(root.path, 'scripts/windows/build_secp256k1.dart'),
    );
    windowsHelper.parent.createSync(recursive: true);
    windowsHelper.writeAsStringSync('''
import 'dart:io';
void main(List<String> args) {
  final root = File.fromUri(Platform.script).parent.parent.parent;
  if (args.contains('--check')) {
    if (Platform.environment['DNIX_TEST_SECP_PREFLIGHT_FAIL'] == '1') exit(22);
    return;
  }
  File('\${root.path}/native-cwd').writeAsStringSync(Directory.current.resolveSymbolicLinksSync());
  final output = File('\${root.path}/build/secp256k1.dll');
  output.parent.createSync(recursive: true);
  output.writeAsStringSync('fixture DLL');
}
''');
    File(p.join(root.path, 'tool/build_standalone_mwebd_windows.dart'))
        .writeAsStringSync('''
import 'dart:io';
void main(List<String> args) {
  final root = File.fromUri(Platform.script).parent.parent;
  File('\${root.path}/assets/windows/mwebd.exe').writeAsBytesSync([0]);
}
''');
  });
  tearDown(() => root.delete(recursive: true));

  Future<void> configure(
    String app, {
    bool prebuilt = false,
    bool skipNative = true,
    String platform = 'macos',
    String? host,
    String? distribution,
    bool fromScripts = false,
    Map<String, String> environment = const {},
    int expectedExit = 0,
  }) async {
    final process = await Process.start(
      'bash',
      [
        fromScripts ? 'build_app.sh' : 'scripts/build_app.sh',
        '-a',
        app,
        '-p',
        platform,
        '-v',
        '1.2.3',
        '-b',
        '123',
        if (prebuilt) '-d',
        if (skipNative) '-i',
        if (distribution != null) ...['-w', distribution],
      ],
      workingDirectory: fromScripts ? p.join(root.path, 'scripts') : root.path,
      environment: {
        'PATH': '${bin.path}:${Platform.environment['PATH']}',
        'DNIX_WSL_DISTRIBUTION': '',
        if (host != null) 'DNIX_TEST_HOST': host,
        ...environment,
      },
    );
    final output = process.stdout.transform(utf8.decoder).join();
    final errors = process.stderr.transform(utf8.decoder).join();
    process.stdin.writeln('yes');
    await process.stdin.close();
    final code = await process.exitCode;
    expect(code, expectedExit, reason: '${await output}\n${await errors}');
  }

  void expectMode(
    String app,
    String mode, {
    String? distribution,
    bool linux = false,
  }) {
    final text = File(p.join(root.path, 'pubspec.yaml')).readAsStringSync();
    final pubspec = loadYaml(text) as YamlMap;
    final dependencies = pubspec['dependencies'] as YamlMap;
    final defines = (pubspec['hooks'] as YamlMap)['user_defines'] as YamlMap;
    expect(
      dependencies.keys.where(allPackages.contains).toSet(),
      packages[app],
    );
    expect(defines.keys.toSet(), packages[app]);
    for (final package in packages[app]!) {
      expect(defines[package], {
        'build': mode,
        if (distribution != null) 'wsl_distribution': distribution,
      });
    }
    expect(text, isNot(contains('PLACEHOLDER_DNIX_BUILD_MODE')));
    expect(text, isNot(contains('native_build:')));
    expect(text, isNot(contains('prebuilt_manifest_')));
    expect(text, isNot(contains('PLACEHOLDER_DNIX_WSL_DISTRIBUTION')));
    final assets = File(p.join(root.path, 'before-assets.yaml'));
    if (linux) {
      expect(assets.existsSync(), isFalse);
    } else {
      // Asset tools see the final spec, though their own dependency closures
      // contain no application native hooks.
      expect(assets.readAsStringSync(), text);
    }
  }

  group('dnix configuration', () {
    for (final app in packages.keys) {
      test(
        '$app switches source -> prebuilt -> source without stale settings',
        () async {
          for (final prebuilt in [false, true, false]) {
            await configure(app, prebuilt: prebuilt);
            expectMode(app, prebuilt ? 'prebuilt' : 'source');
          }
        },
      );
    }

    for (final host in ['MINGW64_NT', 'Linux']) {
      for (final prebuilt in [false, true]) {
        test(
          'Windows config builds secp in project root on $host, -d=$prebuilt',
          () async {
            await configure(
              'stack_wallet',
              platform: 'windows',
              host: host,
              skipNative: false,
              prebuilt: prebuilt,
              fromScripts: true,
            );
            expectMode('stack_wallet', prebuilt ? 'prebuilt' : 'source');
            expect(
              File(p.join(root.path, 'native-cwd')).readAsStringSync(),
              root.resolveSymbolicLinksSync(),
            );
            expect(
              File(p.join(root.path, 'build/secp256k1.dll')).existsSync(),
              isTrue,
            );
          },
        );
      }
    }

    for (final prebuilt in [false, true]) {
      test('Linux config builds both external deps, -d=$prebuilt', () async {
        await configure(
          'stack_wallet',
          platform: 'linux',
          skipNative: false,
          prebuilt: prebuilt,
        );
        expectMode(
          'stack_wallet',
          prebuilt ? 'prebuilt' : 'source',
          linux: true,
        );
        expect(File(p.join(root.path, 'linux-deps')).readAsLinesSync(), [
          'secure_storage_deps',
          'secp256k1',
        ]);
        expect(
          File(p.join(root.path, 'native-cwd')).readAsStringSync().trim(),
          Directory(p.join(root.path, 'scripts/linux'))
              .resolveSymbolicLinksSync(),
        );
      });
    }

    for (final platform in ['windows', 'linux']) {
      test('-i skips external deps for $platform in either mode', () async {
        for (final prebuilt in [false, true]) {
          await configure(
            'stack_wallet',
            platform: platform,
            prebuilt: prebuilt,
          );
          expect(File(p.join(root.path, 'native-cwd')).existsSync(), isFalse);
          expect(
            File(p.join(root.path, 'build/secp256k1.dll')).existsSync(),
            isFalse,
          );
          expect(File(p.join(root.path, 'linux-deps')).existsSync(), isFalse);
        }
      });
    }

    test(
      'WSL environment survives regeneration, flag overrides, unset clears',
      () async {
        const distro = 'Ubuntu "dev" & %20';
        for (final prebuilt in [false, true]) {
          await configure(
            'stack_wallet',
            prebuilt: prebuilt,
            environment: {'DNIX_WSL_DISTRIBUTION': distro},
          );
          expectMode(
            'stack_wallet',
            prebuilt ? 'prebuilt' : 'source',
            distribution: distro,
          );
          expect(
            jsonDecode(
              File(p.join(root.path, 'preflight-args')).readAsStringSync(),
            ),
            ['macos', 'stack_wallet', prebuilt ? 'prebuilt' : 'source', distro],
          );
        }
        await configure(
          'stack_wallet',
          distribution: 'Ubuntu-24.04',
          environment: {'DNIX_WSL_DISTRIBUTION': distro},
        );
        expectMode('stack_wallet', 'source', distribution: 'Ubuntu-24.04');
        await configure('stack_wallet');
        expectMode('stack_wallet', 'source');
      },
    );

    for (final failure in [
      (variable: 'DNIX_TEST_PREFLIGHT_FAIL', code: 21),
      (variable: 'DNIX_TEST_SECP_PREFLIGHT_FAIL', code: 22),
    ]) {
      test(
        '${failure.variable} leaves existing configuration untouched',
        () async {
          final spec = File(p.join(root.path, 'pubspec.yaml'))
            ..writeAsStringSync('unchanged');
          await configure(
            'stack_wallet',
            platform: 'windows',
            skipNative: false,
            environment: {failure.variable: '1'},
            expectedExit: failure.code,
          );
          expect(spec.readAsStringSync(), 'unchanged');
          expect(
            File(p.join(root.path, 'lib/app_config.g.dart')).existsSync(),
            isFalse,
          );
        },
      );
    }

    test('renderer rejects invalid modes and WSL names', () {
      expect(
        () => configureNativeAssets('', 'typo', null),
        throwsArgumentError,
      );
      for (final distribution in [
        '',
        ' ',
        '-option',
        'line\nbreak',
        'nul\u0000',
      ]) {
        expect(
          () => configureNativeAssets('', 'source', distribution),
          throwsArgumentError,
        );
      }
    });
  }, skip: Platform.isWindows ? 'Requires POSIX bash' : false);
}
