import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:isar_community/isar.dart';

/// Point Isar at the core binary bundled in `isar_community_flutter_libs` so
/// tests can open a real Isar instance anywhere, including CI.
///
/// Without this, `Isar.open` only looks for `libisar.so` on the system loader
/// path or in the working directory; neither exists on a fresh checkout, and
/// the alternative (`download: true`) would make the test suite hit the
/// network. Call once from `setUpAll` before opening Isar. Repeat calls and
/// calls from other test files are no-ops.
Future<void> initializeIsarCoreForTests() async {
  final String? relativeLibPath = switch (Abi.current()) {
    Abi.linuxX64 || Abi.linuxArm64 => "linux/libisar.so",
    Abi.macosX64 || Abi.macosArm64 => "macos/libisar.dylib",
    Abi.windowsX64 || Abi.windowsArm64 => "windows/libisar.dll",
    _ => null,
  };
  if (relativeLibPath == null) {
    throw UnsupportedError(
      "isar_community_flutter_libs bundles no Isar core for ${Abi.current()}",
    );
  }

  await Isar.initializeIsarCore(
    libraries: {
      Abi.current(): _packageRoot(
        "isar_community_flutter_libs",
      ).resolve(relativeLibPath).toFilePath(),
    },
  );
}

Uri _packageRoot(String packageName) {
  final configFile = File(".dart_tool/package_config.json");
  if (!configFile.existsSync()) {
    throw StateError(
      "${configFile.path} not found; run `flutter pub get` before the tests",
    );
  }

  final config =
      jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
  final package = (config["packages"] as List)
      .cast<Map<String, dynamic>>()
      .firstWhere(
        (p) => p["name"] == packageName,
        orElse: () => throw StateError("package $packageName not resolved"),
      );

  // rootUri may be relative to .dart_tool/ and carries no trailing slash;
  // without one, resolve() would replace its last segment.
  final rootUri = package["rootUri"] as String;
  return configFile.absolute.parent.uri.resolve(
    rootUri.endsWith("/") ? rootUri : "$rootUri/",
  );
}
