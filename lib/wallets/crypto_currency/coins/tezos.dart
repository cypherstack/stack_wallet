import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/bip39_currency.dart';

class Tezos extends Bip39Currency {
  Tezos(super.network) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        coin = Coin.tezos;
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  String get genesisHash => throw UnimplementedError(
        "Not used in tezos at the moment",
      );

  @override
  int get minConfirms => 1;

  @override
  bool validateAddress(String address) {
    return RegExp(r"^tz[1-9A-HJ-NP-Za-km-z]{34}$").hasMatch(address);
  }

  @override
  NodeModel get defaultNode {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return NodeModel(
          host: "https://mainnet.api.tez.ie",
          port: 443,
          name: DefaultNodes.defaultName,
          id: DefaultNodes.buildId(Coin.tezos),
          useSSL: true,
          enabled: true,
          coinName: Coin.tezos.name,
          isFailover: true,
          isDown: false,
        );

      default:
        throw UnimplementedError();
    }
  }
}
