import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:stack_wallet_branding/adapter.dart';
import 'package:test/test.dart';

void copyTree(Directory source, Directory target) {
  target.createSync(recursive: true);
  for (final entry in source.listSync(followLinks: false)) {
    final destination = p.join(target.path, p.basename(entry.path));
    if (entry is Directory) {
      copyTree(entry, Directory(destination));
    } else if (entry is File) {
      entry.copySync(destination);
    } else {
      throw StateError('Unexpected link in fixture source: ${entry.path}');
    }
  }
}

void main() {
  final repository = p.normalize(p.absolute('../..'));
  late Directory temporary;
  late Directory project;
  setUp(() {
    temporary = Directory.systemTemp.createTempSync('wallet-branding-');
    project = Directory(p.join(temporary.path, 'project'))..createSync();
    for (final directory in [
      'scripts/app_config/templates',
      'tool/wl_templates',
      'asset_sources',
    ]) {
      copyTree(
        Directory(p.join(repository, directory)),
        Directory(p.join(project.path, directory)),
      );
    }
    for (final brand in ['stack_wallet', 'stack_duo', 'campfire']) {
      for (final relative in [
        'ios/Flutter/Flavor-$brand.xcconfig',
        'macos/Runner/Configs/AppInfo-$brand.xcconfig',
      ]) {
        final destination = File(p.join(project.path, relative));
        destination.parent.createSync(recursive: true);
        File(p.join(repository, relative)).copySync(destination.path);
      }
    }
  });
  tearDown(() => temporary.deleteSync(recursive: true));

  for (final brand in ['stack_wallet', 'stack_duo', 'campfire']) {
    for (final platform in nativeFiles.keys) {
      test('$brand plans and applies $platform with consumer-owned inputs', () {
        final executable = File(
          p.join(project.path, 'assets/windows/mwebd.exe'),
        );
        // A digest-validation fixture, never executed or claimed as a native build.
        executable.parent.createSync(recursive: true);
        executable.writeAsStringSync('test fixture only');
        final digest = sha256.convert(executable.readAsBytesSync()).toString();
        final manifest = StackWalletManifest.load('brands/$brand.yaml');
        final plan = planStackWallet(
          projectRoot: project.path,
          brand: manifest,
          version: '2.4.0',
          buildNumber: '123',
          platforms: {platform},
          buildFlavor: brand,
          revision: 'a' * 40,
          windowsMwebdSha256: digest,
        );
        expect(
          Directory(p.join(project.path, '.whitelabel')).existsSync(),
          isFalse,
        );
        plan.apply();
        expect(
          File(
            p.join(project.path, 'lib/app_config.g.dart'),
          ).readAsStringSync(),
          contains(manifest.prefix),
        );
        for (final path in nativeFiles[platform]!) {
          expect(File(p.join(project.path, path)).existsSync(), isTrue);
        }
        for (final other in nativeFiles.keys.where(
          (other) => other != platform,
        )) {
          expect(
            File(p.join(project.path, nativeFiles[other]!.first)).existsSync(),
            isFalse,
          );
        }
        final repeated = planStackWallet(
          projectRoot: project.path,
          brand: manifest,
          version: '2.4.0',
          buildNumber: '123',
          platforms: {platform},
          buildFlavor: brand,
          revision: 'a' * 40,
          windowsMwebdSha256: digest,
        );
        expect(
          repeated.changes.every((change) => change.action == 'unchanged'),
          isTrue,
        );
      });
    }
  }

  test(
    'brand switching removes old assets and protects edited configuration',
    () {
      for (final brand in ['stack_wallet', 'campfire', 'stack_duo']) {
        planStackWallet(
          projectRoot: project.path,
          brand: StackWalletManifest.load('brands/$brand.yaml'),
          version: '2.4.0',
          buildNumber: '123',
          platforms: {'linux'},
          revision: 'a' * 40,
        ).apply();
        for (final directory in assetDirs) {
          final source = Directory(
            p.join(project.path, 'asset_sources', directory, brand),
          );
          final destination = Directory(
            p.join(project.path, 'assets', directory),
          );
          final expected = source
              .listSync(recursive: true)
              .whereType<File>()
              .map((file) => p.relative(file.path, from: source.path))
              .toSet();
          final actual = destination
              .listSync(recursive: true)
              .whereType<File>()
              .map((file) => p.relative(file.path, from: destination.path))
              .toSet();
          expect(actual, expected);
        }
      }
      final config = File(p.join(project.path, 'lib/app_config.g.dart'));
      config.writeAsStringSync('manual edit');
      expect(
        () => planStackWallet(
          projectRoot: project.path,
          brand: StackWalletManifest.load('brands/campfire.yaml'),
          version: '2.4.0',
          buildNumber: '123',
          platforms: {'linux'},
          revision: 'a' * 40,
        ),
        throwsStateError,
      );
      expect(config.readAsStringSync(), 'manual edit');
    },
  );
}
