import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

@Collection(inheritance: false)
class SWTheme {
  /// should be a uuid
  @Index(unique: true, replace: true)
  final String id;

  /// the theme name that will be displayed in app
  final String name;

  // system brightness
  final String brightnessString;

  /// convenience enum conversion for stored [brightnessString]
  @ignore
  Brightness get brightness {
    switch (brightnessString) {
      case "light":
        return Brightness.light;
      case "dark":
        return Brightness.dark;
      default:
        // just return light instead of a possible crash causing error
        return Brightness.light;
    }
  }
}
