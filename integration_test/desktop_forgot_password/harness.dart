// Desktop forgot-password integration tests. With Flutter 3.49 or later:
//
//   flutter test integration_test/desktop_forgot_password -d macos
//
// With older Flutter versions, use the temporary runner:
//
//   bash scripts/test_desktop_forgot_password.sh macos
//
// (or -d linux / -d windows). Linux needs a desktop session, because
// notifications use D-Bus, and a screen at least 800 px wide, otherwise the
// app uses its mobile UI.
//
// Each test launches the real app against a throwaway folder. App data goes
// into it, as with the app's -d <dir> flag, and path_provider points into it
// too, so logs never reach the real documents folder. exit() is intercepted:
// the test records the exit code and the files on disk when the app quits.
//
// One test per file: a reset ends by quitting and the app keeps process-wide
// state, so every scenario needs its own launch.

import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar_community/isar.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:stackwallet/app_config.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/main.dart' as app;
import 'package:stackwallet/utilities/desktop_password_service.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';

const _password = 'correct horse battery staple';
const _secretKey = 'test_wallet_mnemonic';
const _secret = 'test words';

const _walletFiles = [
  'wallets/monero/test_wallet/test_wallet',
  'wallets/monero/test_wallet/test_wallet.keys',
  'epiccash/test_wallet/wallet_data/wallet.seed',
];

/// Seeded files a reset must delete.
const seededData = {
  'hive/desktopdata.hive', // the password
  'isar/desktopStore.isar', // wallet keys
  ..._walletFiles,
};

/// Seeded files a reset must keep.
const seededKeep = {'wallets/backup.swb', 'tor/state'};

/// Plain files the test writes. Each holds its own path.
const seededFiles = [..._walletFiles, ...seededKeep];

typedef AppExit = ({int code, Set<String> files, List<String> openDatabases});

void desktopTest(String description, Future<void> Function(ResetTest t) body) {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    description,
    (tester) async {
      final temp = await Directory.systemTemp.createTemp('stack_reset_test_');
      debugPrint('Test folder: ${temp.path}');
      await body(ResetTest._(tester, temp.path));
      // Only reached when the test passed, so failed runs keep the folder.
      // On Windows the still running app holds some of it open.
      try {
        await temp.delete(recursive: true);
      } on FileSystemException catch (_) {}
    },
    skip: !(Platform.isLinux || Platform.isMacOS || Platform.isWindows),
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

class ResetTest {
  ResetTest._(this.tester, this.temp);

  final WidgetTester tester;
  final String temp;
  late final String root;
  late final _io = _TestIO(this);
  AppExit? _exit;
  final _errors = <String>[];

  /// Set once the app calls exit().
  AppExit? get exited => _exit;

  /// Seeds the data folder, then starts the app.
  Future<void> launch({bool unfinishedReset = false}) async {
    PathProviderPlatform.instance = _TestPaths(temp);
    StackFileSystem.setDesktopOverrideDir(p.join(temp, 'data'));
    root = (await StackFileSystem.applicationRootDirectory()).path;

    DB.instance.hive.init(
      (await StackFileSystem.applicationHiveDirectory()).path,
    );
    final password = DPS();
    await password.initFromNew(_password);
    final keys = DesktopSecureStore(password.handler);
    await keys.init();
    await keys.write(key: _secretKey, value: _secret);
    await keys.close();

    for (final file in seededFiles) {
      await File(path(file)).create(recursive: true);
      await File(path(file)).writeAsString(file);
    }
    // Creating links on Windows needs extra privileges.
    if (!Platform.isWindows) {
      await File(p.join(temp, 'outside', 'file')).create(recursive: true);
      await Link(path('wallets/outside')).create(p.join(temp, 'outside'));
    }
    if (unfinishedReset) {
      await File(path('.reset-pending')).writeAsString('reset');
    }
    expect(files(), containsAll({...seededData, ...seededKeep}));

    // Lay out at the largest window main() picks. Smaller windows overflow the
    // login screen in debug builds, which fails the test.
    await tester.binding.setSurfaceSize(const Size(1220, 900));
    // Never restored: the app runs until this test file's process ends.
    IOOverrides.global = _io;
    runZonedGuarded(() => app.main(const []), _onAppError);
  }

  /// Absolute path of a file in the data folder.
  String path(String file) => p.joinAll([root, ...file.split('/')]);

  /// Everything in the data folder, as paths relative to it.
  Set<String> files() {
    final all = Directory(root).listSync(recursive: true, followLinks: false);
    return {
      for (final entity in all)
        p.split(p.relative(entity.path, from: root)).join('/'),
    };
  }

  List<String> openDatabases() => [
    ...Isar.instanceNames,
    for (final box in [DB.boxNameDBInfo, DB.boxNamePrefs])
      if (DB.instance.hive.isBoxOpen(box)) box,
  ];

  /// Makes deleting this file fail, like a file another program has open.
  void blockDelete(String file) => _io.undeletable = path(file);

  /// Checks seeded files still hold what the test wrote.
  void expectUnchanged(Iterable<String> files) {
    for (final file in files) {
      expect(File(path(file)).readAsStringSync(), file, reason: file);
    }
  }

  /// Checks the password still unlocks the seeded wallet key.
  Future<void> expectPasswordKept() async {
    final password = DPS();
    await password.initFromExisting(_password);
    final keys = DesktopSecureStore(password.handler);
    await keys.init();
    expect(await keys.read(key: _secretKey), _secret);
    await keys.close();
  }

  void expectLinkTargetKept() {
    if (Platform.isWindows) return;
    expect(File(p.join(temp, 'outside', 'file')).existsSync(), isTrue);
  }

  void expectLogsInTestFolder() => expect(
    Directory(p.join(temp, 'documents', '${AppConfig.prefix}_Logs'))
        .existsSync(),
    isTrue,
  );

  Future<void> tapText(String text) => tap(find.text(text, findRichText: true));

  Future<void> tap(Finder finder) async {
    // Exactly one, so a route that is still animating out is not tapped.
    await _waitUntil(
      () => finder.hitTestable().evaluate().length == 1,
      'Timed out waiting for one $finder',
    );
    // Buttons can end in exit(), which throws _AppExited from the callback.
    await runZonedGuarded(() async {
      try {
        await tester.tap(finder.hitTestable());
      } catch (error, stack) {
        _onAppError(error, stack);
      }
    }, _onAppError);
    await _pump();
  }

  Future<void> waitFor(Finder finder) => _waitUntil(
    () => finder.hitTestable().evaluate().isNotEmpty,
    'Timed out waiting for $finder',
  );

  Future<AppExit> waitForExit() async {
    await _waitUntil(() => _exit != null, 'The app did not quit');
    return _exit!;
  }

  Future<void> _waitUntil(bool Function() done, String reason) async {
    final deadline = DateTime.now().add(const Duration(minutes: 1));
    while (true) {
      await _pump();
      if (done()) return;
      if (DateTime.now().isAfter(deadline)) fail(reason);
    }
  }

  Future<void> _pump() async {
    await tester.pump(const Duration(milliseconds: 100));
    final Object? error = tester.takeException();
    if (error != null) _onAppError(error, StackTrace.current);
    if (_errors.isNotEmpty) {
      fail('The app reported an error:\n${_errors.first}');
    }
  }

  void _onAppError(Object error, StackTrace stack) {
    if (error is! _AppExited) _errors.add('$error\n$stack');
  }
}

class _AppExited {
  const _AppExited();
}

final class _TestIO extends IOOverrides {
  _TestIO(this.test);

  final ResetTest test;
  String? undeletable;

  @override
  Never exit(int code) {
    test._exit ??= (
      code: code,
      files: test.files(),
      openDatabases: test.openDatabases(),
    );
    throw const _AppExited();
  }

  // Works because the reset deletes each file through a new File(path).
  @override
  File createFile(String path) {
    final file = super.createFile(path);
    final blocked = undeletable;
    return blocked != null && p.equals(path, blocked)
        ? _UndeletableFile(file)
        : file;
  }
}

class _UndeletableFile extends Fake implements File {
  _UndeletableFile(this._file);

  final File _file;

  @override
  String get path => _file.path;

  @override
  Future<File> delete({bool recursive = false}) async =>
      throw FileSystemException('Blocked by the test', path);
}

class _TestPaths extends PathProviderPlatform {
  _TestPaths(this.temp);

  final String temp;

  Future<String> _directory(String name) async =>
      (await Directory(p.join(temp, name)).create(recursive: true)).path;

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
