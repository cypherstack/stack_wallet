import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

abstract class Util {
  static Directory? libraryPath;
  static double? screenWidth;

  static bool get isDesktop {
    // special check for running on linux based phones
    if (Platform.isLinux && screenWidth != null && screenWidth! < 800) {
      return false;
    }

    // special check for running under ipad mode in macos
    if (Platform.isIOS &&
        libraryPath != null &&
        !libraryPath!.path.contains("/var/mobile/")) {
      return true;
    }

    return Platform.isLinux || Platform.isMacOS || Platform.isWindows;
  }

  static Future<bool> get isIPad async {
    final deviceInfo = (await DeviceInfoPlugin().deviceInfo);
    if (deviceInfo is IosDeviceInfo) {
      return (deviceInfo).name?.toLowerCase().contains("ipad") == true;
    }
    return false;
  }

  static MaterialColor createMaterialColor(Color color) {
    List<double> strengths = <double>[.05];
    final swatch = <int, Color>{};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }

  static void printJson(dynamic json) {
    if (json is Map || json is List) {
      final spaces = ' ' * 4;
      final encoder = JsonEncoder.withIndent(spaces);
      final pretty = encoder.convert(json);
      log(pretty);
    } else {
      log(dynamic.toString());
    }
  }
}
