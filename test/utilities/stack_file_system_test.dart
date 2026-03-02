import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';

void main() {
  const appImagePath = "/media/secure/StackWallet.AppImage";

  group("AppImage portable data directory", () {
    test("is opt in", () {
      final result = StackFileSystem.desktopDataDirectoryOverride(
        arguments: const [],
        appImagePath: appImagePath,
        appDataDirectoryName: "stackwallet",
        portableMarkerExists: false,
      );

      expect(result, isNull);
    });

    test("supports the portable flag", () {
      final result = StackFileSystem.desktopDataDirectoryOverride(
        arguments: const ["--portable"],
        appImagePath: appImagePath,
        appDataDirectoryName: "stackwallet",
        portableMarkerExists: false,
      );

      expect(result, (path: "/media/secure/.stackwallet", portable: true));
    });

    test("supports a marker beside the AppImage", () {
      final result = StackFileSystem.desktopDataDirectoryOverride(
        arguments: const [],
        appImagePath: appImagePath,
        appDataDirectoryName: "stackwallet",
        portableMarkerExists: true,
      );

      expect(result, (path: "/media/secure/.stackwallet", portable: true));
    });

    test("keeps the explicit data directory authoritative", () {
      final result = StackFileSystem.desktopDataDirectoryOverride(
        arguments: const ["-d", "/custom/data"],
        appImagePath: appImagePath,
        appDataDirectoryName: "stackwallet",
        portableMarkerExists: true,
      );

      expect(result, (path: "/custom/data", portable: false));
    });

    test("keeps the explicit data directory authoritative after other "
        "arguments", () {
      final result = StackFileSystem.desktopDataDirectoryOverride(
        arguments: const ["--portable", "-d", "/custom/data"],
        appImagePath: appImagePath,
        appDataDirectoryName: "stackwallet",
        portableMarkerExists: true,
      );

      expect(result, (path: "/custom/data", portable: false));
    });

    test("keeps the explicit data directory authoritative before other "
        "arguments", () {
      final result = StackFileSystem.desktopDataDirectoryOverride(
        arguments: const ["-d", "/custom/data", "--portable"],
        appImagePath: appImagePath,
        appDataDirectoryName: "stackwallet",
        portableMarkerExists: true,
      );

      expect(result, (path: "/custom/data", portable: false));
    });

    test("keeps the explicit data directory authoritative alongside an "
        "unrelated argument", () {
      final result = StackFileSystem.desktopDataDirectoryOverride(
        arguments: const ["-d", "/custom/data", "--verbose"],
        appImagePath: appImagePath,
        appDataDirectoryName: "stackwallet",
        portableMarkerExists: true,
      );

      expect(result, (path: "/custom/data", portable: false));
    });

    test("rejects an explicit data directory without a path", () {
      for (final arguments in const [
        ["-d"],
        ["-d", "--portable"],
        ["-d", ""],
      ]) {
        expect(
          () => StackFileSystem.desktopDataDirectoryOverride(
            arguments: arguments,
            appImagePath: appImagePath,
            appDataDirectoryName: "stackwallet",
            portableMarkerExists: false,
          ),
          throwsArgumentError,
          reason: "$arguments",
        );
      }
    });

    test("does not enable portable mode outside an AppImage", () {
      final result = StackFileSystem.desktopDataDirectoryOverride(
        arguments: const ["--portable"],
        appImagePath: null,
        appDataDirectoryName: "stackwallet",
        portableMarkerExists: false,
      );

      expect(result, isNull);
    });
  });

  test("creates data and log directories inside the portable root", () async {
    final temporaryDirectory = Directory.systemTemp.createTempSync(
      "stack-wallet-portable-test-",
    );
    addTearDown(() => temporaryDirectory.deleteSync(recursive: true));
    final portableRoot = path.join(temporaryDirectory.path, ".stackwallet");

    StackFileSystem.setPortableDesktopDataDirectory(portableRoot);

    final dataDirectory = await StackFileSystem.applicationRootDirectory();
    final logsDirectory = await StackFileSystem.applicationLogsDirectory(
      Prefs.instance,
    );

    expect(StackFileSystem.isPortableMode, isTrue);
    expect(dataDirectory.path, portableRoot);
    expect(dataDirectory.existsSync(), isTrue);
    expect(logsDirectory.path, path.join(portableRoot, "logs"));
    expect(logsDirectory.existsSync(), isTrue);
  });
}
