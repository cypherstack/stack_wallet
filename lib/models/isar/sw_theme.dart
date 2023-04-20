import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/extensions/impl/gradient.dart';
import 'package:stackwallet/utilities/extensions/impl/string.dart';
import 'package:stackwallet/utilities/theme/color_theme.dart';
import 'package:uuid/uuid.dart';

@Collection(inheritance: false)
class StackTheme {
  final String assetBundleUrl;

  /// should be a uuid
  @Index(unique: true, replace: true)
  final String internalId;

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

  @ignore
  Color get background => _background ??= Color(backgroundInt);
  @ignore
  Color? _background;
  final int backgroundInt;

  // ==== backgroundAppBar =====================================================
  @ignore
  Color get backgroundAppBar =>
      _backgroundAppBar ??= Color(backgroundAppBarInt);
  @ignore
  Color? _backgroundAppBar;
  final int backgroundAppBarInt;
  // ===========================================================================

  @ignore
  Gradient get gradientBackground =>
      _gradientBackground ??= GradientExt.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(gradientBackgroundString) as Map,
        ),
      );
  @ignore
  Gradient? _gradientBackground;
  final String gradientBackgroundString;

  // ===========================================================================

  @ignore
  Map<Coin, Color> get coinColors =>
      _coinColors ??= parseCoinColors(coinColorsJsonString);
  @ignore
  Map<Coin, Color>? _coinColors;
  final String coinColorsJsonString;

  // ===========================================================================

  // ===========================================================================
  // ===========================================================================

  final ThemeAssets assets;

  // ===========================================================================
  // ===========================================================================

  StackTheme({
    required this.internalId,
    required this.assetBundleUrl,
    required this.name,
    required this.brightnessString,
    required this.backgroundInt,
    required this.backgroundAppBarInt,
    required this.gradientBackgroundString,
    required this.coinColorsJsonString,
    required this.assets,
  });

  factory StackTheme.fromJson({
    required Map<String, dynamic> json,
    required String applicationThemesDirectoryPath,
  }) {
    final _id = const Uuid().v1();
    return StackTheme(
      internalId: _id,
      name: json["name"] as String,
      assetBundleUrl: json["assetBundleUrl"] as String,
      brightnessString: json["brightness"] as String,
      backgroundInt: parseColor(json["colors"]["background"] as String),
      backgroundAppBarInt:
          parseColor(json["colors"]["backgroundAppBar"] as String),
      gradientBackgroundString:
          jsonEncode(json["gradients"]["gradientBackground"] as Map),
      coinColorsJsonString: jsonEncode(json["coinColors"] as Map),
      assets: ThemeAssets.fromJson(
        json: json,
        applicationThemesDirectoryPath: applicationThemesDirectoryPath,
        internalThemeUuid: _id,
      ),
    );
  }

  /// Grab the int value of the hex color string.
  /// 8 char string value expected where the first 2 are opacity
  static int parseColor(String colorHex) {
    try {
      final int colorValue = colorHex.toBigIntFromHex.toInt();
      if (colorValue >= 0 && colorValue <= 0xFFFFFFFF) {
        return colorValue;
      } else {
        throw ArgumentError(
          '"$colorHex" and corresponding int '
          'value "$colorValue" is not a valid color.',
        );
      }
    } catch (_) {
      throw ArgumentError(
        '"$colorHex" is not a valid hex number',
      );
    }
  }

  /// parse coin colors json and fetch color or use default
  static Map<Coin, Color> parseCoinColors(String jsonString) {
    final json = jsonDecode(jsonString) as Map;
    final map = Map<String, dynamic>.from(json);

    final Map<Coin, Color> result = {};

    for (final coin in Coin.values) {
      if (map[coin.name] is String) {
        result[coin] = Color(
          (map[coin.name] as String).toBigIntFromHex.toInt(),
        );
      } else {
        result[coin] = kCoinThemeColorDefaults.forCoin(coin);
      }
    }

    return result;
  }
}

@Embedded(inheritance: false)
class ThemeAssets {
  final String plus;

  // todo: add all assets expected in json

  ThemeAssets({
    required this.plus,
  });

  factory ThemeAssets.fromJson({
    required Map<String, dynamic> json,
    required String applicationThemesDirectoryPath,
    required String internalThemeUuid,
  }) {
    return ThemeAssets(
      plus:
          "$applicationThemesDirectoryPath/$internalThemeUuid/${json["assets"]["svg"]["plus.svg"] as String}",
    );
  }
}
