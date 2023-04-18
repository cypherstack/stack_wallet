import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/extensions/impl/gradient.dart';
import 'package:stackwallet/utilities/extensions/impl/string.dart';
import 'package:stackwallet/utilities/theme/color_theme.dart';
import 'package:uuid/uuid.dart';

@Collection(inheritance: false)
class ColorTheme {
  static String themesDirPath = "/djhfgj/sdfd/themes/";

  final String assetBundleUrl;

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

  @ignore
  Color get background => _background ??= Color(
        backgroundString.toBigIntFromHex.toInt(),
      );
  @ignore
  Color? _background;
  final String backgroundString;

  // ==== backgroundAppBar =====================================================
  @ignore
  Color get backgroundAppBar => _backgroundAppBar ??= Color(
        backgroundAppBarString.toBigIntFromHex.toInt(),
      );
  @ignore
  Color? _backgroundAppBar;
  final String backgroundAppBarString;
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

  @ignore
  Map<Coin, Color> get coinColors =>
      _coinColors ??= parseCoinColors(coinColorsString);
  @ignore
  Map<Coin, Color>? _coinColors;
  final String coinColorsString;

  // ==== assets =====================================================
  final String circleLock;

  ColorTheme({
    required this.id,
    required this.assetBundleUrl,
    required this.name,
    required this.brightnessString,
    required this.backgroundString,
    required this.backgroundAppBarString,
    required this.gradientBackgroundString,
    required this.coinColorsString,
    required this.circleLock,
  });

  factory ColorTheme.fromJson(Map<String, dynamic> json) {
    final _id = const Uuid().v1();
    return ColorTheme(
      id: _id,
      name: json["name"] as String,
      assetBundleUrl: json["assetBundleUrl"] as String,
      brightnessString: json["brightness"] as String,
      backgroundString: json["colors"]["background"] as String,
      backgroundAppBarString: json["colors"]["backgroundAppBar"] as String,
      gradientBackgroundString:
          jsonEncode(json["gradients"]["gradientBackground"] as Map),
      coinColorsString: jsonEncode(json["coinColors"] as Map),
      circleLock:
          "$themesDirPath/$_id/${json["assets"]["circleLock"] as String}",
    );
  }

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
