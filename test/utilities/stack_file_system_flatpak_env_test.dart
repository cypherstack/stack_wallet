import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:stackwallet/utilities/stack_file_system.dart';

// Process level tests for the Linux data root under a Flatpak environment.
// StackFileSystem reads Platform.environment directly, so these can only run
// in a test process launched with a simulated Flatpak environment:
//
//   T=$(mktemp -d)
//   FLATPAK_ID=com.cypherstack.stackwallet HOME=$T/home XDG_DATA_HOME=$T/xdg \
//     PUB_CACHE=$HOME/.pub-cache \
//     flutter test test/utilities/stack_file_system_flatpak_env_test.dart
//
// (PUB_CACHE expands before HOME is overridden.) Without that environment the
// file skips itself so it stays harmless in the normal suite.

void main() {
  final env = Platform.environment;
  final enabled =
      Platform.isLinux &&
      (env["FLATPAK_ID"] ?? "").isNotEmpty &&
      (env["XDG_DATA_HOME"] ?? "").isNotEmpty &&
      (env["HOME"] ?? "").isNotEmpty;
  if (!enabled) {
    test("skipped: not launched with a simulated Flatpak environment", () {
      markTestSkipped("set FLATPAK_ID/XDG_DATA_HOME/HOME to a scratch tree");
    });
    return;
  }

  final home = env["HOME"]!;
  final xdg = Directory(env["XDG_DATA_HOME"]!);
  final legacy = Directory(path.join(home, ".stackwallet"));
  final destination = Directory(path.join(xdg.path, "stackwallet"));
  final lockFile = File(path.join(legacy.path, "hive", "dbinfo.lock"));

  setUpAll(() async {
    await Directory(path.join(legacy.path, "hive")).create(recursive: true);
    await File(
      path.join(legacy.path, "hive", "wallet.hive"),
    ).writeAsString("wallet data");
    await lockFile.writeAsString("{}");
  });

  tearDownAll(() async {
    await Process.run("chmod", ["-R", "u+rwx", xdg.parent.path]);
  });

  /// Runs a separate process that tries to take the Hive lock, the way a
  /// second app instance would.
  Future<String> otherInstanceLock() async {
    final script = File(path.join(xdg.parent.path, "try_lock.dart"));
    await script.writeAsString('''
import 'dart:io';
Future<void> main(List<String> a) async {
  final h = await File(a[0]).open(mode: FileMode.append);
  try { await h.lock(FileLock.exclusive); print('ACQUIRED'); await h.unlock(); }
  catch (_) { print('REFUSED'); } finally { await h.close(); }
}
''');
    final result = await Process.run("dart", [
      "run",
      script.path,
      lockFile.path,
    ]);
    return result.stdout.toString().trim();
  }

  test(
    "the root does not change between calls after a migration failure",
    () async {
      // First resolution (main(): applicationHiveDirectory) fails because
      // XDG_DATA_HOME is not writable, so the app continues on legacy data.
      await xdg.create(recursive: true);
      await Process.run("chmod", ["0500", xdg.path]);
      final first = await StackFileSystem.applicationRootDirectory();
      expect(first.path, legacy.path);
      expect(await destination.exists(), false);

      // The failure clears; a later call (applicationTorDirectory(), a wallet
      // path lookup, ...) must not switch roots with Hive and Isar already
      // open on legacy.
      await Process.run("chmod", ["0700", xdg.path]);
      final second = await StackFileSystem.applicationRootDirectory();
      expect(second.path, first.path);
    },
  );

  test(
    "a Hive lock held by this process survives later root lookups",
    () async {
      await Process.run("chmod", ["-R", "u+rwx", xdg.path]);
      if (await destination.exists()) {
        await destination.delete(recursive: true);
      }
      await Process.run("chmod", ["0500", xdg.path]);

      // main() opens Hive, which locks dbinfo.lock, after the first
      // applicationRootDirectory() call.
      final hiveLock = await lockFile.open(mode: FileMode.write);
      await hiveLock.lock();
      try {
        expect(await otherInstanceLock(), "REFUSED");

        final root = await StackFileSystem.applicationRootDirectory();
        expect(root.path, legacy.path);

        // A second app instance must still be refused.
        expect(await otherInstanceLock(), "REFUSED");
      } finally {
        await hiveLock.close();
      }
    },
  );

  test("-d remains authoritative over the Flatpak environment", () async {
    final override = Directory(path.join(xdg.parent.path, "override"));
    StackFileSystem.setDesktopOverrideDir(override.path);

    final result = await StackFileSystem.applicationRootDirectory();

    expect(result.path, override.path);
  });
}
