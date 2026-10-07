import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:stackwallet/utilities/flatpak_data_directory.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';

// The -d override is process wide and can only be set once, so this file
// sets it before any root is resolved.
void main() {
  late Directory temporaryRoot;
  late Directory override;
  late Map<String, String> environment;

  setUpAll(() async {
    temporaryRoot = await Directory.systemTemp.createTemp("sfs-override-");
    override = Directory(path.join(temporaryRoot.path, "override"));
    environment = {
      "FLATPAK_ID": "com.cypherstack.stackwallet",
      "HOME": path.join(temporaryRoot.path, "home"),
      "XDG_DATA_HOME": path.join(temporaryRoot.path, "xdg"),
    };
    StackFileSystem.setDesktopOverrideDir(override.path);
  });

  tearDownAll(() async {
    await temporaryRoot.delete(recursive: true);
  });

  test("-d wins over the Flatpak root and skips the migration", () async {
    final legacyFile = File(
      path.join(environment["HOME"]!, ".stackwallet", "hive", "wallet.hive"),
    );
    await legacyFile.parent.create(recursive: true);
    await legacyFile.writeAsString("wallet data");

    final root = await StackFileSystem.linuxRootDirectory(environment);

    expect(root.path, override.path);
    expect(await legacyFile.readAsString(), "wallet data");
    expect(
      await File(
        path.join(
          legacyFile.parent.parent.path,
          FlatpakDataDirectory.legacyRemovalMarker,
        ),
      ).exists(),
      isFalse,
    );
    expect(await Directory(environment["XDG_DATA_HOME"]!).exists(), isFalse);
  });

  test("-d wins over the default root", () async {
    final root = await StackFileSystem.applicationRootDirectory();

    expect(root.path, override.path);
  }, skip: Platform.isLinux ? false : "Linux only");

  test("-d cannot be changed once set", () {
    expect(
      () => StackFileSystem.setDesktopOverrideDir(temporaryRoot.path),
      throwsException,
    );
  });
}
