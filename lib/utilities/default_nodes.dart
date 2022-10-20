import 'dart:convert';

import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

abstract class DefaultNodes {
  static String _nodeId(Coin coin) => "default_${coin.name}";
  static const String defaultName = "Stack Default";

  static List<NodeModel> get all => [
        bitcoin,
        dogecoin,
        firo,
        monero,
        moneroTestNet,
        moneroStageNet,
        wownero,
        epicCash,
        bitcoincash,
        namecoin,
        bitcoinTestnet,
        bitcoincashTestnet,
        dogecoinTestnet,
        firoTestnet,
      ];

  static NodeModel get bitcoin => NodeModel(
        host: "bitcoin.stackwallet.com",
        port: 50002,
        name: defaultName,
        id: _nodeId(Coin.bitcoin),
        useSSL: true,
        enabled: true,
        coinName: Coin.bitcoin.name,
        isFailover: true,
        isDown: false,
      );

  static NodeModel get bitcoincash => NodeModel(
        host: "bitcoincash.stackwallet.com",
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
        host: "dogecoin.stackwallet.com",
        port: 50022,
        name: defaultName,
        id: _nodeId(Coin.dogecoin),
        useSSL: true,
        enabled: true,
        coinName: Coin.dogecoin.name,
        isFailover: true,
        isDown: false,
      );

  static NodeModel get firo => NodeModel(
        host: "firo.stackwallet.com",
        port: 50002,
        name: defaultName,
        id: _nodeId(Coin.firo),
        useSSL: true,
        enabled: true,
        coinName: Coin.firo.name,
        isFailover: true,
        isDown: false,
      );

  static NodeModel get monero => NodeModel(
        host: "https://monero.stackwallet.com",
        port: 18081,
        name: defaultName,
        id: _nodeId(Coin.monero),
        useSSL: true,
        enabled: true,
        coinName: Coin.monero.name,
        isFailover: true,
        isDown: false,
      );

  // TODO: eventually enable ssl and set scheme to https
  // currently get certificate failure
  static NodeModel get moneroTestNet => NodeModel(
        host:
            "http://monero-testnet.stackwallet.com", // can use http://node.sethforprivacy.com:28089 for development purposes until testnet node set up
        port: 28081,
        name: defaultName,
        id: _nodeId(Coin.moneroTestNet),
        useSSL: false,
        enabled: true,
        coinName: Coin.moneroTestNet.name,
        isFailover: true,
        isDown: false,
      );

  // TODO: eventually enable ssl and set scheme to https
  // currently get certificate failure
  static NodeModel get moneroStageNet => NodeModel(
        host:
            "http://monero-stagenet.stackwallet.com", // can use http://node.sethforprivacy.com:38089 for development purposes until stagenet node set up
        port: 38081,
        name: defaultName,
        id: _nodeId(Coin.moneroStageNet),
        useSSL: false,
        enabled: true,
        coinName: Coin.moneroStageNet.name,
        isFailover: true,
        isDown: false,
      );

  // TODO: eventually enable ssl and set scheme to https
  // currently get certificate failure


  static NodeModel get wownero => NodeModel(
        host: "https://wownero.stackwallet.com",
        port: 34568,
        name: defaultName,
        id: _nodeId(Coin.wownero),
        useSSL: true,
        enabled: true,
        coinName: Coin.wownero.name,
        isFailover: true,
        isDown: false,
      );

  static NodeModel get epicCash => NodeModel(
        host: "http://epiccash.stackwallet.com",
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
        host: "namecoin.stackwallet.com",
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

  static NodeModel get firoTestnet => NodeModel(
        host: "firo-testnet.stackwallet.com",
        port: 50002,
        name: defaultName,
        id: _nodeId(Coin.firoTestNet),
        useSSL: true,
        enabled: true,
        coinName: Coin.firoTestNet.name,
        isFailover: true,
        isDown: false,
      );

  static NodeModel get dogecoinTestnet => NodeModel(
        host: "dogecoin-testnet.stackwallet.com",
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
        host: "bitcoincash-testnet.stackwallet.com",
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

      case Coin.bitcoincash:
        return bitcoincash;

      case Coin.dogecoin:
        return dogecoin;

      case Coin.epicCash:
        return epicCash;

      case Coin.firo:
        return firo;

      case Coin.monero:
        return monero;

      case Coin.moneroTestNet:
        return moneroTestNet;

      case Coin.moneroStageNet:
        return moneroStageNet;

      case Coin.wownero:
        return wownero;

      case Coin.namecoin:
        return namecoin;

      case Coin.bitcoinTestNet:
        return bitcoinTestnet;

      case Coin.bitcoincashTestnet:
        return bitcoincashTestnet;

      case Coin.firoTestNet:
        return firoTestnet;

      case Coin.dogecoinTestNet:
        return dogecoinTestnet;
    }
  }

  static final String defaultEpicBoxConfig = jsonEncode({
    "domain": "209.127.179.199",
    "port": 13420,
  });
}
