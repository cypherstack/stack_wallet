import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:stackwallet/utilities/flatpak_data_directory.dart';

Future<void> _copyTree(Directory source, Directory destination) async {
  await destination.create(recursive: true);
  await for (final entity in source.list(followLinks: false)) {
    final target = path.join(destination.path, path.basename(entity.path));
    if (entity is Directory) {
      await _copyTree(entity, Directory(target));
    } else if (entity is File) {
      await entity.copy(target);
    }
  }
}

// What a rename from the legacy bind mount fails with inside Flatpak.
Future<void> _crossDeviceRename(Directory source, String destination) async {
  if (source.path.endsWith(".migrating")) {
    await source.rename(destination);
    return;
  }
  throw FileSystemException(
    "Rename failed",
    source.path,
    const OSError("Invalid cross-device link", 18),
  );
}

void main() {
  late Directory temporaryRoot;

  setUp(() async {
    temporaryRoot = await Directory.systemTemp.createTemp("flatpak-data-test-");
  });

  tearDown(() async {
    await temporaryRoot.delete(recursive: true);
  });

  Map<String, String> environment() => {
    "FLATPAK_ID": "com.cypherstack.stackwallet",
    "HOME": path.join(temporaryRoot.path, "home"),
    "XDG_DATA_HOME": path.join(temporaryRoot.path, "xdg"),
  };

  test("ignores non-Flatpak environments", () async {
    final result = await FlatpakDataDirectory.resolve(
      environment: const {},
      appDirectoryName: "stackwallet",
    );

    expect(result, isNull);
  });

  test("falls back when Flatpak does not provide an XDG data root", () async {
    final result = await FlatpakDataDirectory.resolve(
      environment: const {"FLATPAK_ID": "com.cypherstack.stackwallet"},
      appDirectoryName: "stackwallet",
    );

    expect(result, isNull);
  });

  test("initializes an app-private root for a fresh install", () async {
    final result = await FlatpakDataDirectory.resolve(
      environment: environment(),
      appDirectoryName: "stackwallet",
    );

    expect(result!.path, path.join(temporaryRoot.path, "xdg", "stackwallet"));
    expect(
      await File(path.join(result.path, FlatpakDataDirectory.migrationMarker))
          .exists(),
      isTrue,
    );
  });

  test("moves legacy data by renaming it on the same filesystem", () async {
    final env = environment();
    final legacy = Directory(path.join(env["HOME"]!, ".stackwallet"));
    await Directory(path.join(legacy.path, "hive")).create(recursive: true);
    await File(path.join(legacy.path, "hive", "wallet.hive"))
        .writeAsString("wallet data");

    final result = await FlatpakDataDirectory.resolve(
      environment: env,
      appDirectoryName: "stackwallet",
      copyDirectory: (_, _) async => fail("should not copy"),
    );

    expect(result!.path, path.join(env["XDG_DATA_HOME"]!, "stackwallet"));
    expect(
      await File(path.join(result.path, "hive", "wallet.hive")).readAsString(),
      "wallet data",
    );
    expect(
      await File(path.join(result.path, FlatpakDataDirectory.migrationMarker))
          .exists(),
      isTrue,
    );
    expect(await legacy.exists(), isFalse);
  });

  test("copies, verifies and removes legacy data across filesystems", () async {
    final env = environment();
    final legacy = Directory(path.join(env["HOME"]!, ".stackwallet"));
    await Directory(path.join(legacy.path, "hive")).create(recursive: true);
    await Directory(path.join(legacy.path, "isar")).create(recursive: true);
    await File(path.join(legacy.path, "hive", "desktopdata.hive"))
        .writeAsString("password");
    await File(path.join(legacy.path, "hive", "dbinfo.lock")).writeAsString("");
    await File(path.join(legacy.path, "isar", "desktopStore.isar"))
        .writeAsString("keys");
    Object? reportedError;

    final result = await FlatpakDataDirectory.resolve(
      environment: env,
      appDirectoryName: "stackwallet",
      renameDirectory: _crossDeviceRename,
      onError: (error) => reportedError = error,
    );

    expect(reportedError, isNull);
    expect(result!.path, path.join(env["XDG_DATA_HOME"]!, "stackwallet"));
    expect(
      await File(path.join(result.path, "hive", "desktopdata.hive"))
          .readAsString(),
      "password",
    );
    expect(
      await File(path.join(result.path, "isar", "desktopStore.isar"))
          .readAsString(),
      "keys",
    );
    expect(await legacy.exists(), isFalse);
    expect(await Directory("${result.path}.migrating").exists(), isFalse);
  });

  for (final published in [false, true]) {
    test("resumes interrupted publication (published: $published)", () async {
      final env = environment();
      final legacy = Directory(path.join(env["HOME"]!, ".stackwallet"));
      final wallet = File(path.join(legacy.path, "wallet"));
      await legacy.create(recursive: true);
      await wallet.writeAsString("keys");
      final destination = path.join(env["XDG_DATA_HOME"]!, "stackwallet");

      await FlatpakDataDirectory.resolve(
        environment: env,
        appDirectoryName: "stackwallet",
        renameDirectory: (source, target) async {
          if (source.path == legacy.path) {
            return _crossDeviceRename(source, target);
          }
          expect(
            await File(
              path.join(legacy.path, FlatpakDataDirectory.legacyRemovalMarker),
            ).exists(),
            isTrue,
          );
          if (published) await source.rename(target);
          throw const FileSystemException("interrupted publication");
        },
      );
      expect(await wallet.readAsString(), "keys");

      final result = await FlatpakDataDirectory.resolve(
        environment: env,
        appDirectoryName: "stackwallet",
        renameDirectory: _crossDeviceRename,
      );
      expect(result!.path, destination);
      expect(
        await File(path.join(destination, "wallet")).readAsString(),
        "keys",
      );
      expect(await legacy.exists(), isFalse);
      expect(
        await File(
          path.join(destination, FlatpakDataDirectory.legacyRemovalMarker),
        ).exists(),
        isFalse,
      );
    });
  }

  test("serializes concurrent first migrations without a Hive lock", () async {
    final env = environment();
    final legacy = Directory(path.join(env["HOME"]!, ".stackwallet"));
    await legacy.create(recursive: true);
    await File(path.join(legacy.path, "wallet")).writeAsString("keys");
    final counter = File(path.join(temporaryRoot.path, "rename-calls"));
    final script = File(path.join(temporaryRoot.path, "migrate.dart"));
    await script.writeAsString('''
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:stackwallet/utilities/flatpak_data_directory.dart';
Future<void> copyTree(Directory source, Directory destination) async {
  await destination.create(recursive: true);
  await for (final entity in source.list(followLinks: false)) {
    final target = path.join(destination.path, path.basename(entity.path));
    if (entity is Directory) {
      await copyTree(entity, Directory(target));
    } else if (entity is File) {
      await entity.copy(target);
    }
  }
}
Future<void> main(List<String> args) async {
  final legacy = Directory(args[0]);
  final env = <String, String>{
    'FLATPAK_ID': 'com.cypherstack.stackwallet',
    'HOME': Directory(legacy.path).parent.path,
    'XDG_DATA_HOME': args[1],
  };
  await FlatpakDataDirectory.resolve(
    environment: env,
    appDirectoryName: 'stackwallet',
    renameDirectory: (source, target) async {
      if (source.path == legacy.path) {
        await File(args[2]).writeAsString('x', mode: FileMode.append);
        await Future<void>.delayed(const Duration(milliseconds: 200));
        throw FileSystemException('cross-device', source.path);
      }
      await source.rename(target);
    },
    copyDirectory: copyTree,
  );
}
''');
    final args = [legacy.path, env["XDG_DATA_HOME"]!, counter.path];
    final packageConfig = path.join(
      Directory.current.path,
      ".dart_tool/package_config.json",
    );
    final processes = await Future.wait([
      Process.start("dart", [
        "--packages=$packageConfig",
        script.path,
        ...args,
      ]),
      Process.start("dart", [
        "--packages=$packageConfig",
        script.path,
        ...args,
      ]),
    ]);
    final results = await Future.wait(
      processes.map((process) async {
        final stdout = await process.stdout
            .transform(systemEncoding.decoder)
            .join();
        final stderr = await process.stderr
            .transform(systemEncoding.decoder)
            .join();
        final code = await process.exitCode;
        return (code: code, stdout: stdout, stderr: stderr);
      }),
    );

    expect(results.map((result) => result.code), everyElement(0));
    expect(await counter.readAsString(), "x");
    expect(
      await File(path.join(env["XDG_DATA_HOME"]!, "stackwallet", "wallet"))
          .readAsString(),
      "keys",
    );
    expect(await legacy.exists(), isFalse);
  });

  test("keeps legacy data when the copy does not verify", () async {
    final env = environment();
    final legacy = Directory(path.join(env["HOME"]!, ".stackwallet"));
    final legacyFile = File(path.join(legacy.path, "isar", "wallet.isar"));
    await legacyFile.parent.create(recursive: true);
    await legacyFile.writeAsString("wallet data");
    Object? reportedError;

    final result = await FlatpakDataDirectory.resolve(
      environment: env,
      appDirectoryName: "stackwallet",
      renameDirectory: _crossDeviceRename,
      copyDirectory: (source, temporary) async {
        await _copyTree(source, temporary);
        await File(path.join(temporary.path, "isar", "wallet.isar"))
            .writeAsString("corrupted");
      },
      onError: (error) => reportedError = error,
    );

    expect(result!.path, legacy.path);
    expect(reportedError, isA<FileSystemException>());
    expect(await legacyFile.readAsString(), "wallet data");
    expect(
      await Directory(path.join(env["XDG_DATA_HOME"]!, "stackwallet")).exists(),
      isFalse,
    );
  });

  test("finishes an interrupted removal of migrated legacy data", () async {
    final env = environment();
    final legacy = Directory(path.join(env["HOME"]!, ".stackwallet"));
    final destination = Directory(
      path.join(env["XDG_DATA_HOME"]!, "stackwallet"),
    );
    await destination.create(recursive: true);
    await File(
      path.join(destination.path, FlatpakDataDirectory.migrationMarker),
    ).writeAsString("complete");
    await Directory(path.join(legacy.path, "isar")).create(recursive: true);
    await File(path.join(legacy.path, FlatpakDataDirectory.legacyRemovalMarker))
        .writeAsString("removing");
    await File(path.join(legacy.path, "isar", "desktopStore.isar"))
        .writeAsString("keys");

    final result = await FlatpakDataDirectory.resolve(
      environment: env,
      appDirectoryName: "stackwallet",
    );

    expect(result!.path, destination.path);
    expect(await legacy.exists(), isFalse);
  });

  test(
    "uses a completed migration without recopying stale legacy data",
    () async {
      final env = environment();
      final legacyFile = File(
        path.join(env["HOME"]!, ".stackwallet", "wallet"),
      );
      await legacyFile.parent.create(recursive: true);
      await legacyFile.writeAsString("first");

      final first = await FlatpakDataDirectory.resolve(
        environment: env,
        appDirectoryName: "stackwallet",
      );
      // e.g. written by a non-Flatpak build after the migration
      await legacyFile.parent.create(recursive: true);
      await legacyFile.writeAsString("stale");
      final second = await FlatpakDataDirectory.resolve(
        environment: env,
        appDirectoryName: "stackwallet",
      );

      expect(second!.path, first!.path);
      expect(
        await File(path.join(second.path, "wallet")).readAsString(),
        "first",
      );
      expect(await legacyFile.readAsString(), "stale");
    },
  );

  test("falls back to legacy data when copying fails", () async {
    final env = environment();
    final legacy = Directory(path.join(env["HOME"]!, ".stackwallet"));
    await legacy.create(recursive: true);
    Object? reportedError;

    final result = await FlatpakDataDirectory.resolve(
      environment: env,
      appDirectoryName: "stackwallet",
      renameDirectory: _crossDeviceRename,
      copyDirectory: (_, _) async => throw const FileSystemException("copy"),
      onError: (error) => reportedError = error,
    );

    expect(result!.path, legacy.path);
    expect(reportedError, isA<FileSystemException>());
    expect(
      await Directory("${env["XDG_DATA_HOME"]!}/stackwallet.migrating")
          .exists(),
      isFalse,
    );
  });

  test("does not replace unverified destination data", () async {
    final env = environment();
    final legacy = Directory(path.join(env["HOME"]!, ".stackwallet"));
    final destination = Directory(
      path.join(env["XDG_DATA_HOME"]!, "stackwallet"),
    );
    await legacy.create(recursive: true);
    await destination.create(recursive: true);
    await File(path.join(destination.path, "unexpected")).writeAsString("data");
    Object? reportedError;

    final result = await FlatpakDataDirectory.resolve(
      environment: env,
      appDirectoryName: "stackwallet",
      onError: (error) => reportedError = error,
    );

    expect(result!.path, legacy.path);
    expect(reportedError, isA<StateError>());
    expect(
      await File(path.join(destination.path, "unexpected")).readAsString(),
      "data",
    );
  });

  test("adopts a migration another instance completed while copying", () async {
    final env = environment();
    final legacy = Directory(path.join(env["HOME"]!, ".stackwallet"));
    final destination = Directory(
      path.join(env["XDG_DATA_HOME"]!, "stackwallet"),
    );
    await Directory(path.join(legacy.path, "hive")).create(recursive: true);
    await File(path.join(legacy.path, "hive", "wallet.hive"))
        .writeAsString("wallet data");
    Object? reportedError;

    final result = await FlatpakDataDirectory.resolve(
      environment: env,
      appDirectoryName: "stackwallet",
      renameDirectory: _crossDeviceRename,
      copyDirectory: (source, temporary) async {
        // A second instance finishes its own verified migration while this
        // one copies, so the rename onto the destination loses the race.
        await _copyTree(source, destination);
        await File(
          path.join(destination.path, FlatpakDataDirectory.migrationMarker),
        ).writeAsString("complete", flush: true);
        await _copyTree(source, temporary);
      },
      onError: (error) => reportedError = error,
    );

    expect(result!.path, destination.path);
    expect(reportedError, isNull);
    expect(await Directory("${destination.path}.migrating").exists(), isFalse);
  });
}
