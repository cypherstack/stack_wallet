import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/extensions/impl/string.dart';

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
  "gradients": {
    "background": {
      "type": "linear",
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
  }
};

extension GradientExt on Gradient {
  static Gradient fromJson(Map<String, dynamic> json) {
    switch (json["type"]) {
      case "linear":
        final colorStrings =
            List<String>.from(json["background"]["colors"] as List);
        return LinearGradient(
          begin: Alignment(
            json["background"]["begin"]["x"] as double,
            json["background"]["begin"]["y"] as double,
          ),
          end: Alignment(
            json["background"]["end"]["x"] as double,
            json["background"]["end"]["y"] as double,
          ),
          colors: colorStrings
              .map(
                (e) => Color(
                  e.toBigIntFromHex.toInt(),
                ),
              )
              .toList(),
        );

      default:
        throw ArgumentError("Invalid json gradient: $json");
    }
  }
}
