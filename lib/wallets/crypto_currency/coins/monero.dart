import 'package:cw_monero/api/wallet.dart' as monero_wallet;
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/cryptonote_currency.dart';
import 'package:monero/monero.dart' as monero;

class Monero extends CryptonoteCurrency {
  Monero(super.network) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        coin = Coin.monero;
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  int get minConfirms => 10;

  @override
  bool validateAddress(String address) {
    return monero.Wallet_addressValid(address, 0);
  }

  @override
  NodeModel get defaultNode {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return NodeModel(
          host: "https://monero.stackwallet.com",
          port: 18081,
          name: DefaultNodes.defaultName,
          id: DefaultNodes.buildId(Coin.monero),
          useSSL: true,
          enabled: true,
          coinName: Coin.monero.name,
          isFailover: true,
          isDown: false,
          trusted: true,
        );

      default:
        throw UnimplementedError();
    }
  }
}
