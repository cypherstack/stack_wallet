import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/bip39_currency.dart';

class Stellar extends Bip39Currency {
  Stellar(super.network) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        coin = Coin.stellar;
      case CryptoCurrencyNetwork.test:
        coin = Coin.stellarTestnet;
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  int get minConfirms => 1;

  @override
  String get genesisHash => throw UnimplementedError(
        "Not used for stellar",
      );

  @override
  NodeModel get defaultNode {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return DefaultNodes.stellar;
      case CryptoCurrencyNetwork.test:
        return DefaultNodes.stellarTestnet;
      default:
        throw Exception("Unsupported network");
    }
  }

  @override
  bool validateAddress(String address) =>
      RegExp(r"^[G][A-Z0-9]{55}$").hasMatch(address);

  @override
  bool operator ==(Object other) {
    return other is Stellar && other.network == network;
  }

  @override
  int get hashCode => Object.hash(Stellar, network);
}
