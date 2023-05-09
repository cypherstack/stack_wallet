import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';

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
    // todo unzip, install, and create theme object and add to db
  }

  Future<void> remove({required String themeId}) async {
    // todo delete local files and remove from db
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
