import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:isar_community/isar.dart';

/// Points Isar at the core binary bundled in `isar_community_flutter_libs` so
/// tests can open a real Isar anywhere `flutter pub get` has run. Isar's own
/// initialisation only tries `dlopen("libisar.so")` and `<cwd>/libisar.so`,
/// neither of which exists on a fresh checkout or on CI.
Future<void> initializeIsarCoreForTests() async {
  final packageConfig = File(".dart_tool/package_config.json");
  final json =
      jsonDecode(await packageConfig.readAsString()) as Map<String, dynamic>;
  final packages = (json["packages"] as List).cast<Map<String, dynamic>>();
  final libs = packages.firstWhere(
    (p) => p["name"] == "isar_community_flutter_libs",
  );
  // rootUri has no trailing slash; without one, resolve() would replace the
  // last path segment instead of descending into it.
  var rootUri = libs["rootUri"] as String;
  if (!rootUri.endsWith("/")) {
    rootUri = "$rootUri/";
  }
  final root = packageConfig.absolute.parent.uri.resolve(rootUri);

  final String? relative = switch (Abi.current()) {
    Abi.linuxX64 || Abi.linuxArm64 => "linux/libisar.so",
    Abi.macosX64 || Abi.macosArm64 => "macos/libisar.dylib",
    Abi.windowsX64 || Abi.windowsArm64 => "windows/libisar.dll",
    _ => null,
  };
  if (relative == null) {
    throw UnsupportedError("No bundled Isar core for ${Abi.current()}");
  }

  await Isar.initializeIsarCore(
    libraries: {Abi.current(): root.resolve(relative).toFilePath()},
  );
}
