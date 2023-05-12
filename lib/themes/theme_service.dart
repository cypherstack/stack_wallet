import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
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

  static const String baseServerUrl = "https://themes.stackwallet.com";

  MainDB? _db;
  MainDB get db => _db!;

  void init(MainDB db) => _db ??= db;

  Future<void> install({required Uint8List themeArchiveData}) async {
    final themesDir = await StackFileSystem.applicationThemesDirectory();

    final archive = ZipDecoder().decodeBytes(themeArchiveData);

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

  // TODO more thorough check/verification of theme
  Future<bool> verifyInstalled({required String themeId}) async {
    final dbHasTheme =
        await db.isar.stackThemes.where().themeIdEqualTo(themeId).count() > 0;
    if (dbHasTheme) {
      final themesDir = await StackFileSystem.applicationThemesDirectory();
      final jsonFileExists =
          await File("${themesDir.path}/$themeId/theme.json").exists();
      final assetsDirExists =
          await Directory("${themesDir.path}/$themeId/assets").exists();

      if (!jsonFileExists || !assetsDirExists) {
        Logging.instance.log(
          "Theme $themeId found in DB but is missing files",
          level: LogLevel.Warning,
        );
      }

      return jsonFileExists && assetsDirExists;
    } else {
      return false;
    }
  }

  Future<List<StackThemeMetaData>> fetchThemes() async {
    try {
      final response = await get(Uri.parse("$baseServerUrl/themes"));

      final jsonList = jsonDecode(response.body) as List;

      final result = List<Map<String, dynamic>>.from(jsonList)
          .map((e) => StackThemeMetaData.fromMap(e))
          .where((e) => e.id != "light" && e.id != "dark")
          .toList();

      return result;
    } catch (e, s) {
      Logging.instance.log(
        "Failed to fetch themes list: $e\n$s",
        level: LogLevel.Warning,
      );
      rethrow;
    }
  }

  Future<Uint8List> fetchTheme({
    required StackThemeMetaData themeMetaData,
  }) async {
    try {
      final response =
          await get(Uri.parse("$baseServerUrl/theme/${themeMetaData.id}"));

      final bytes = response.bodyBytes;

      // verify hash
      final digest = sha256.convert(bytes);
      if (digest.toString() == themeMetaData.sha256) {
        return bytes;
      } else {
        throw Exception(
          "Fetched theme archive sha256 hash ($digest) does not"
          " match requested $themeMetaData",
        );
      }
    } catch (e, s) {
      Logging.instance.log(
        "Failed to fetch themes list: $e\n$s",
        level: LogLevel.Warning,
      );
      rethrow;
    }
  }

  StackTheme? getTheme({required String themeId}) =>
      db.isar.stackThemes.where().themeIdEqualTo(themeId).findFirstSync();

  List<StackTheme> get installedThemes =>
      db.isar.stackThemes.where().findAllSync();
}

class StackThemeMetaData {
  final String name;
  final String id;
  final String sha256;
  final String size;
  final String previewImageUrl;

  StackThemeMetaData({
    required this.name,
    required this.id,
    required this.sha256,
    required this.size,
    required this.previewImageUrl,
  });

  static StackThemeMetaData fromMap(Map<String, dynamic> map) {
    try {
      return StackThemeMetaData(
        name: map["name"] as String,
        id: map["id"] as String,
        sha256: map["sha256"] as String,
        size: map["size"] as String,
        previewImageUrl: map["previewImageUrl"] as String,
      );
    } catch (e, s) {
      Logging.instance.log(
        "Failed to create instance of StackThemeMetaData using $map: \n$e\n$s",
        level: LogLevel.Fatal,
      );
      rethrow;
    }
  }

  @override
  String toString() {
    return "$runtimeType("
        "name: $name, "
        "id: $id, "
        "sha256: $sha256, "
        "size: $size, "
        "previewImageUrl: $previewImageUrl"
        ")";
  }
}
