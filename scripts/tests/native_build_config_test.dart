// Run with: dart scripts/tests/native_build_config_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

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
cp "$APP_PROJECT_ROOT_DIR/pubspec.yaml" "$APP_PROJECT_ROOT_DIR/before-hooks.yaml"
''');
    for (final platform in ['macos', 'windows']) {
      script('scripts/app_config/platforms/$platform/platform_config.sh', ':');
    }
    script('scripts/windows/build_secp256k1_wsl.sh', r'''
printf 'wsl\n' > "$APP_PROJECT_ROOT_DIR/secp-host"
''');
    script('bin/cmd.exe', r'''
printf '%s\n' "$@" > "$APP_PROJECT_ROOT_DIR/windows-command"
''');
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
  }) async {
    final process = await Process.start(
      'bash',
      [
        'scripts/build_app.sh',
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
      ],
      workingDirectory: root.path,
      environment: {
        'PATH': '${bin.path}:${Platform.environment['PATH']}',
        if (host != null) 'DNIX_TEST_HOST': host,
      },
    );
    final output = process.stdout.transform(utf8.decoder).join();
    final errors = process.stderr.transform(utf8.decoder).join();
    process.stdin.writeln('yes');
    await process.stdin.close();
    final code = await process.exitCode;
    expect(code, 0, reason: '${await output}\n${await errors}');
  }

  void expectMode(String app, String mode) {
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
      expect(defines[package], {'build': mode});
    }
    expect(text, isNot(contains('PLACEHOLDER_DNIX_BUILD_MODE')));
    expect(text, isNot(contains('native_build:')));
    expect(text, isNot(contains('prebuilt_manifest_')));
    // Asset generators use dart run, which can execute native build hooks.
    expect(
      File(p.join(root.path, 'before-hooks.yaml')).readAsStringSync(),
      text,
    );
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

    test(
      'native Windows uses coinlib instead of the WSL cross compiler',
      () async {
        await configure(
          'stack_wallet',
          platform: 'windows',
          host: 'MINGW64_NT',
          skipNative: false,
        );
        expectMode('stack_wallet', 'source');
        expect(File(p.join(root.path, 'windows-command')).readAsLinesSync(), [
          '/c',
          'dart',
          'run',
          'coinlib:build_windows',
        ]);
        expect(File(p.join(root.path, 'secp-host')).existsSync(), isFalse);
      },
    );

    test('Linux/WSL keeps the secp256k1 cross-build path', () async {
      await configure(
        'stack_wallet',
        platform: 'windows',
        host: 'Linux',
        skipNative: false,
      );
      expect(File(p.join(root.path, 'secp-host')).readAsStringSync(), 'wsl\n');
      expect(File(p.join(root.path, 'windows-command')).existsSync(), isFalse);
    });

    test(
      '-d leaves the separate Windows secp256k1 build to the caller',
      () async {
        await configure(
          'stack_wallet',
          platform: 'windows',
          host: 'MINGW64_NT',
          skipNative: false,
          prebuilt: true,
        );
        expectMode('stack_wallet', 'prebuilt');
        expect(File(p.join(root.path, 'secp-host')).existsSync(), isFalse);
        expect(
          File(p.join(root.path, 'windows-command')).existsSync(),
          isFalse,
        );
      },
    );
  }, skip: Platform.isWindows ? 'Requires POSIX bash' : false);
}
