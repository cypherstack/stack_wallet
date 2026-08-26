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
      await File(
        path.join(result.path, FlatpakDataDirectory.migrationMarker),
      ).exists(),
      isTrue,
    );
  });

  test("copies and verifies legacy data before switching roots", () async {
    final env = environment();
    final legacy = Directory(path.join(env["HOME"]!, ".stackwallet"));
    await Directory(path.join(legacy.path, "hive")).create(recursive: true);
    await File(
      path.join(legacy.path, "hive", "wallet.hive"),
    ).writeAsString("wallet data");

    final result = await FlatpakDataDirectory.resolve(
      environment: env,
      appDirectoryName: "stackwallet",
    );

    expect(result!.path, path.join(env["XDG_DATA_HOME"]!, "stackwallet"));
    expect(
      await File(path.join(result.path, "hive", "wallet.hive")).readAsString(),
      "wallet data",
    );
    expect(await legacy.exists(), isTrue);
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
      copyDirectory: (_, _) async => throw const FileSystemException("copy"),
      onError: (error) => reportedError = error,
    );

    expect(result!.path, legacy.path);
    expect(reportedError, isA<FileSystemException>());
    expect(
      await Directory(
        "${env["XDG_DATA_HOME"]!}/stackwallet.migrating",
      ).exists(),
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
    await File(
      path.join(legacy.path, "hive", "wallet.hive"),
    ).writeAsString("wallet data");
    Object? reportedError;

    final result = await FlatpakDataDirectory.resolve(
      environment: env,
      appDirectoryName: "stackwallet",
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
