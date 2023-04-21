import 'package:flutter/material.dart';

// todo: delete this map (example)
final map = {
  "name": "Dark",
  "coinColors": {
    "bitcoin": "0xFF267352",
  },
  "assets": {
    "circleLock": "svg/somerandomnamecreatedbythemecreator.svg",
  },
  "colors": {
    "background": "0xFF848383",
  },
  "gradientBackground": {
    "gradientType": "linear",
    "begin": {
      "x": 0.0,
      "y": 1.0,
    },
    "end": {
      "x": -1.0,
      "y": 1.0,
    },
    "colors": [
      "0xFF638227",
      "0xFF632827",
    ]
  }
};

extension BoxShadowExt on BoxShadow {
  static BoxShadow fromJson(Map<String, dynamic> json) {
    switch (json["boxShadowType"] as String) {
      case "standard":
        final colorStrings = (json["colors"]);
        return BoxShadow(
          color: Color(
            colorStrings as int,
          ),
          spreadRadius: json["spread_radius"] as double,
          blurRadius: json["blur_radius"] as double,
        );
      case "home_view_button_bar":
        final colorStrings = (json["colors"]);
        return BoxShadow(
          color: Color(
            colorStrings as int,
          ),
          spreadRadius: json["spread_radius"] as double,
          blurRadius: json["blur_radius"] as double,
        );
      default:
        throw ArgumentError("Invalid json box shadow: $json");
    }
  }
}
