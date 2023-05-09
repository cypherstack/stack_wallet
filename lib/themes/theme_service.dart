import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';

final pThemeService = Provider<ThemeService>((ref) {
  return ThemeService.instance;
});

class ThemeService {
  ThemeService._();
  static ThemeService? _instance;
  static ThemeService get instance => _instance ??= ThemeService._();

  MainDB? _db;
  MainDB get db => _db!;

  void init(MainDB db) => _db ??= db;

  Future<void> install({required ByteData themeArchive}) async {
    final themesDir = await StackFileSystem.applicationThemesDirectory();

    final byteStream = InputStream(themeArchive);
    final archive = ZipDecoder().decodeBuffer(byteStream);

    final themeJsonFiles = archive.files.where((e) => e.name == "theme.json");

    if (themeJsonFiles.length != 1) {
      throw Exception("Invalid theme archive: Missing theme.json");
    }

    final OutputStream os = OutputStream();
    themeJsonFiles.first.decompress(os);
    final String jsonString = utf8.decode(os.getBytes());
    final json = jsonDecode(jsonString) as Map;

    final theme = StackTheme.fromJson(
      json: Map<String, dynamic>.from(json),
      applicationThemesDirectoryPath: themesDir.path,
    );

    final String assetsPath = "${themesDir.path}/${theme.themeId}";

    for (final file in archive.files) {
      if (file.isFile) {
        // TODO more sanitation?
        if (file.name.contains("..")) {
          Logging.instance.log(
            "Bad theme asset file path: ${file.name}",
            level: LogLevel.Error,
          );
        } else {
          final os = OutputFileStream("$assetsPath/${file.name}");
          file.writeContent(os);
          await os.close();
        }
      }
    }

    await db.isar.writeTxn(() async {
      await db.isar.stackThemes.put(theme);
    });
  }

  Future<void> remove({required String themeId}) async {
    final themesDir = await StackFileSystem.applicationThemesDirectory();
    final isarId = await db.isar.stackThemes
        .where()
        .themeIdEqualTo(themeId)
        .idProperty()
        .findFirst();
    if (isarId != null) {
      await db.isar.writeTxn(() async {
        await db.isar.stackThemes.delete(isarId);
      });
      await Directory("${themesDir.path}/$themeId").delete(recursive: true);
    } else {
      Logging.instance.log(
        "Failed to delete theme $themeId",
        level: LogLevel.Warning,
      );
    }
  }

  Future<List<Map<String, dynamic>>> fetchThemeList() async {
    // todo fetch actual themes from server
    throw UnimplementedError();
  }

  Future<ByteData> fetchTheme({required String themeId}) async {
    // todo fetch theme archive from server
    throw UnimplementedError();
  }

  StackTheme? getTheme({required String themeId}) =>
      db.isar.stackThemes.where().themeIdEqualTo(themeId).findFirstSync();

  List<StackTheme> get installedThemes =>
      db.isar.stackThemes.where().findAllSync();
}
