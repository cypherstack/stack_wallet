import 'package:nanodart/nanodart.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/nano_currency.dart';

class Nano extends NanoCurrency {
  Nano(super.network) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        coin = Coin.nano;
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  int get minConfirms => 1;

  @override
  String get defaultRepresentative =>
      "nano_38713x95zyjsqzx6nm1dsom1jmm668owkeb9913ax6nfgj15az3nu8xkx579";

  @override
  int get nanoAccountType => NanoAccountType.NANO;

  @override
  NodeModel get defaultNode {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return NodeModel(
          host: "https://rainstorm.city/api",
          port: 443,
          name: DefaultNodes.defaultName,
          id: DefaultNodes.buildId(Coin.nano),
          useSSL: true,
          enabled: true,
          coinName: Coin.nano.name,
          isFailover: true,
          isDown: false,
        );

      default:
        throw UnimplementedError();
    }
  }

  @override
  bool operator ==(Object other) {
    return other is Nano && other.network == network;
  }

  @override
  int get hashCode => Object.hash(Nano, network);
}
