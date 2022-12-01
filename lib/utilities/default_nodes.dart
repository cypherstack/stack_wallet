import 'dart:convert';

import 'package:epicmobile/models/node_model.dart';
import 'package:epicmobile/utilities/enums/coin_enum.dart';

abstract class DefaultNodes {
  static String _nodeId(Coin coin) => "default_${coin.name}";
  static const String defaultName = "Stack Default";

  static List<NodeModel> get all => [
        bitcoin,
        litecoin,
        dogecoin,
        epicCash,
        bitcoincash,
        namecoin,
        bitcoinTestnet,
        litecoinTestNet,
        bitcoincashTestnet,
        dogecoinTestnet,
      ];

  static NodeModel get bitcoin => NodeModel(
        host: "bitcoin.epicmobile.com",
        port: 50002,
        name: defaultName,
        id: _nodeId(Coin.bitcoin),
        useSSL: true,
        enabled: true,
        coinName: Coin.bitcoin.name,
        isFailover: true,
        isDown: false,
      );

  static NodeModel get litecoin => NodeModel(
        host: "litecoin.epicmobile.com",
        port: 20063,
        name: defaultName,
        id: _nodeId(Coin.litecoin),
        useSSL: true,
        enabled: true,
        coinName: Coin.litecoin.name,
        isFailover: true,
        isDown: false,
      );

  static NodeModel get litecoinTestNet => NodeModel(
        host: "litecoin.epicmobile.com",
        port: 51002,
        name: defaultName,
        id: _nodeId(Coin.litecoinTestNet),
        useSSL: true,
        enabled: true,
        coinName: Coin.litecoinTestNet.name,
        isFailover: true,
        isDown: false,
      );

  static NodeModel get bitcoincash => NodeModel(
        host: "bitcoincash.epicmobile.com",
        port: 50002,
        name: defaultName,
        id: _nodeId(Coin.bitcoincash),
        useSSL: true,
        enabled: true,
        coinName: Coin.bitcoincash.name,
        isFailover: true,
        isDown: false,
      );

  static NodeModel get dogecoin => NodeModel(
        host: "dogecoin.epicmobile.com",
        port: 50022,
        name: defaultName,
        id: _nodeId(Coin.dogecoin),
        useSSL: true,
        enabled: true,
        coinName: Coin.dogecoin.name,
        isFailover: true,
        isDown: false,
      );

  static NodeModel get epicCash => NodeModel(
        host: "http://epiccash.epicmobile.com",
        port: 3413,
        name: defaultName,
        id: _nodeId(Coin.epicCash),
        useSSL: false,
        enabled: true,
        coinName: Coin.epicCash.name,
        isFailover: true,
        isDown: false,
      );

  static NodeModel get namecoin => NodeModel(
        host: "namecoin.epicmobile.com",
        port: 57002,
        name: defaultName,
        id: _nodeId(Coin.namecoin),
        useSSL: true,
        enabled: true,
        coinName: Coin.namecoin.name,
        isFailover: true,
        isDown: false,
      );

  static NodeModel get bitcoinTestnet => NodeModel(
        host: "electrumx-testnet.cypherstack.com",
        port: 51002,
        name: defaultName,
        id: _nodeId(Coin.bitcoinTestNet),
        useSSL: true,
        enabled: true,
        coinName: Coin.bitcoinTestNet.name,
        isFailover: true,
        isDown: false,
      );

  static NodeModel get dogecoinTestnet => NodeModel(
        host: "dogecoin-testnet.epicmobile.com",
        port: 50022,
        name: defaultName,
        id: _nodeId(Coin.dogecoinTestNet),
        useSSL: true,
        enabled: true,
        coinName: Coin.dogecoinTestNet.name,
        isFailover: true,
        isDown: false,
      );

  static NodeModel get bitcoincashTestnet => NodeModel(
        host: "bitcoincash-testnet.epicmobile.com",
        port: 60002,
        name: defaultName,
        id: _nodeId(Coin.bitcoincashTestnet),
        useSSL: true,
        enabled: true,
        coinName: Coin.bitcoincashTestnet.name,
        isFailover: true,
        isDown: false,
      );

  static NodeModel getNodeFor(Coin coin) {
    switch (coin) {
      case Coin.bitcoin:
        return bitcoin;

      case Coin.litecoin:
        return litecoin;

      case Coin.bitcoincash:
        return bitcoincash;

      case Coin.dogecoin:
        return dogecoin;

      case Coin.epicCash:
        return epicCash;

      case Coin.namecoin:
        return namecoin;

      case Coin.bitcoinTestNet:
        return bitcoinTestnet;

      case Coin.litecoinTestNet:
        return litecoinTestNet;

      case Coin.bitcoincashTestnet:
        return bitcoincashTestnet;

      case Coin.dogecoinTestNet:
        return dogecoinTestnet;
    }
  }

  static final String defaultEpicBoxConfig = jsonEncode({
    "domain": "209.127.179.199",
    "port": 13420,
  });
}
