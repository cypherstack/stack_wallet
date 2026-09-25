import 'dart:convert';
import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:isar_community/isar.dart';

Future<void> initializeTestIsar() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    final configFile = File('.dart_tool/package_config.json').absolute;
    final config =
        jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
    final package = (config['packages'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .singleWhere((entry) => entry['name'] == 'isar_community_flutter_libs');
    final rootUri = package['rootUri'] as String;
    final packageRoot = configFile.uri.resolve(
      rootUri.endsWith('/') ? rootUri : '$rootUri/',
    );
    final binary = Platform.isWindows
        ? 'windows/libisar.dll'
        : Platform.isMacOS
        ? 'macos/libisar.dylib'
        : 'linux/libisar.so';
    await Isar.initializeIsarCore(
      libraries: {Abi.current(): packageRoot.resolve(binary).toFilePath()},
    );
  }
}
