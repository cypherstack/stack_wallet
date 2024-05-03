import 'package:nanodart/nanodart.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/nano_currency.dart';

class Banano extends NanoCurrency {
  Banano(super.network) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        coin = Coin.banano;
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  int get minConfirms => 1;

  @override
  String get defaultRepresentative =>
      "ban_1ka1ium4pfue3uxtntqsrib8mumxgazsjf58gidh1xeo5te3whsq8z476goo";

  @override
  int get nanoAccountType => NanoAccountType.BANANO;

  @override
  NodeModel get defaultNode {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return NodeModel(
          host: "https://kaliumapi.appditto.com/api",
          port: 443,
          name: DefaultNodes.defaultName,
          id: DefaultNodes.buildId(Coin.banano),
          useSSL: true,
          enabled: true,
          coinName: Coin.banano.name,
          isFailover: true,
          isDown: false,
        );

      default:
        throw UnimplementedError();
    }
  }

  @override
  bool operator ==(Object other) {
    return other is Banano && other.network == network;
  }

  @override
  int get hashCode => Object.hash(Banano, network);
}
