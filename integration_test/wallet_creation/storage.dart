import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';

const mobileStore = FlutterSecureStorage(
  aOptions: AndroidOptions(resetOnError: false, migrateWithBackup: true),
);

class TestStorage {
  TestStorage(this.root, this.mobile);

  final Directory root;
  final bool mobile;
  File get manifest => File(p.join(root.path, 'wallets.json'));
  File get marker => File(p.join(root.path, '.wallet-creation-test'));

  Future<void> clearMobileTestKeys() async {
    if (!mobile) return;
    // prepare() required an empty store and an explicitly disposable mobile
    // install before onboarding. Only a successful create/reopen pair reaches
    // this cleanup. Failed mobile runs require an explicit reset by the caller.
    expect(await marker.readAsString(), 'wallet-creation-test-v1');
    expect(await manifest.exists(), isTrue);
    for (final key in (await mobileStore.readAll()).keys) {
      await mobileStore.delete(key: key);
    }
    expect((await mobileStore.readAll()).isEmpty, isTrue);
  }

  static Future<TestStorage> prepare({required bool reopen}) async {
    final mobile = Platform.isAndroid || Platform.isIOS;
    final String path;
    if (mobile) {
      expect(
        const bool.fromEnvironment('WALLET_TEST_DISPOSABLE_DEVICE'),
        isTrue,
        reason: 'Mobile runs require a dedicated disposable device/app install',
      );
      const runId = String.fromEnvironment('WALLET_TEST_RUN_ID');
      expect(
        RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(runId),
        isTrue,
        reason: 'A safe, nonempty WALLET_TEST_RUN_ID is required on mobile',
      );
      final support = await PathProviderPlatform.instance
          .getApplicationSupportPath();
      expect(support, isNotNull);
      path = p.join(support!, 'wallet_creation_tests', runId);
      // Fail before writing any app state if this install already has keys.
      // In particular, an iOS reinstall may retain Keychain items.
      if (!reopen) {
        expect(
          (await mobileStore.readAll()).isEmpty,
          isTrue,
          reason:
              'Mobile secure storage is not empty; use a clean test install',
        );
      }
    } else {
      path = const String.fromEnvironment('WALLET_TEST_ROOT');
      expect(
        path.isNotEmpty && p.isAbsolute(path),
        isTrue,
        reason: 'Pass an absolute disposable WALLET_TEST_ROOT (use the runner)',
      );
    }

    final root = Directory(path);
    final storage = TestStorage(root, mobile);
    if (reopen) {
      expect(
        await storage.marker.exists(),
        isTrue,
        reason: 'Refusing to reopen storage not owned by this test',
      );
      expect(await storage.marker.readAsString(), 'wallet-creation-test-v1');
      expect(
        await storage.manifest.exists(),
        isTrue,
        reason: 'No successful creation manifest exists',
      );
    } else {
      expect(
        !await root.exists() || await root.list().isEmpty,
        isTrue,
        reason: 'Fresh install requires an empty test directory',
      );
      await root.create(recursive: true);
      await storage.marker.writeAsString(
        'wallet-creation-test-v1',
        flush: true,
      );
    }

    PathProviderPlatform.instance = _TestPaths(root.path);
    if (!mobile) {
      StackFileSystem.setDesktopOverrideDir(p.join(root.path, 'data'));
    }
    await Directory(p.join(root.path, 'recovery')).create(recursive: true);
    return storage;
  }
}

class _TestPaths extends PathProviderPlatform {
  _TestPaths(this.root);
  final String root;

  Future<String> _directory(String name) async =>
      (await Directory(p.join(root, name)).create(recursive: true)).path;

  @override
  Future<String?> getTemporaryPath() => _directory('temp');
  @override
  Future<String?> getApplicationSupportPath() => _directory('support');
  @override
  Future<String?> getLibraryPath() => _directory('library');
  @override
  Future<String?> getApplicationDocumentsPath() => _directory('documents');
  @override
  Future<String?> getApplicationCachePath() => _directory('cache');
  @override
  Future<String?> getDownloadsPath() => _directory('downloads');
}
