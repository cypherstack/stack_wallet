import 'package:monero/wownero.dart' as wownero;
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/cryptonote_currency.dart';

class Wownero extends CryptonoteCurrency {
  Wownero(super.network) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        coin = Coin.wownero;
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  int get minConfirms => 15;

  @override
  bool validateAddress(String address) {
    return wownero.Wallet_addressValid(address, 0);
  }

  @override
  NodeModel get defaultNode {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return NodeModel(
          host: "https://wownero.stackwallet.com",
          port: 34568,
          name: DefaultNodes.defaultName,
          id: DefaultNodes.buildId(Coin.wownero),
          useSSL: true,
          enabled: true,
          coinName: Coin.wownero.name,
          isFailover: true,
          isDown: false,
          trusted: true,
        );

      default:
        throw UnimplementedError();
    }
  }
}
