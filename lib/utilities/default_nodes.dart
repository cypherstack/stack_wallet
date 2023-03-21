import 'package:stackduo/models/node_model.dart';
import 'package:stackduo/utilities/enums/coin_enum.dart';

abstract class DefaultNodes {
  static const String defaultNodeIdPrefix = "default_";
  static String _nodeId(Coin coin) => "$defaultNodeIdPrefix${coin.name}";
  static const String defaultName = "Stack Default";

  static List<NodeModel> get all => [
        bitcoin,
        monero,
        bitcoinTestnet,
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
        trusted: true,
      );

  static NodeModel get bitcoinTestnet => NodeModel(
        host: "bitcoin-testnet.stackwallet.com",
        port: 51002,
        name: defaultName,
        id: _nodeId(Coin.bitcoinTestNet),
        useSSL: true,
        enabled: true,
        coinName: Coin.bitcoinTestNet.name,
        isFailover: true,
        isDown: false,
      );

  static NodeModel getNodeFor(Coin coin) {
    switch (coin) {
      case Coin.bitcoin:
        return bitcoin;

      case Coin.monero:
        return monero;

      case Coin.bitcoinTestNet:
        return bitcoinTestnet;
    }
  }
}
