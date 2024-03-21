import 'package:solana/solana.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/bip39_currency.dart';
import 'package:stackwallet/utilities/default_nodes.dart';

class Solana extends Bip39Currency {
  Solana(super.network) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        coin = Coin.solana;
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  NodeModel get defaultNode {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return NodeModel(
          host: "https://api.mainnet-beta.solana.com/", // TODO: Change this to stack wallet one
          port: 443,
          name: DefaultNodes.defaultName,
          id: DefaultNodes.buildId(Coin.solana),
          useSSL: true,
          enabled: true,
          coinName: Coin.solana.name,
          isFailover: true,
          isDown: false,
        );
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  int get minConfirms => 21;

  @override
  bool validateAddress(String address) {
    return isPointOnEd25519Curve(Ed25519HDPublicKey.fromBase58(address).toByteArray());
  }

  @override
  String get genesisHash => throw UnimplementedError();
}