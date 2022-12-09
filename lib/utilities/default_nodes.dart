import 'dart:convert';

import 'package:epicpay/models/node_model.dart';
import 'package:epicpay/utilities/enums/coin_enum.dart';

abstract class DefaultNodes {
  static String _nodeId(Coin coin) => "default_${coin.name}";
  static const String defaultName = "Default";

  static List<NodeModel> get all => [
        epicCash,
      ];

  static NodeModel get epicCash => NodeModel(
        host: "epiccash.stackwallet.com",
        port: 3413,
        name: defaultName,
        id: _nodeId(Coin.epicCash),
        useSSL: false,
        enabled: true,
        coinName: Coin.epicCash.name,
        isFailover: true,
        isDown: false,
      );

  static NodeModel getNodeFor(Coin coin) {
    switch (coin) {
      case Coin.epicCash:
        return epicCash;
    }
  }

  static final String defaultEpicBoxConfig = jsonEncode({
    "domain": "209.127.179.199",
    "port": 13420,
  });
}
