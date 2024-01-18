import 'package:flutter_libepiccash/lib.dart' as epic;
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/bip39_currency.dart';

class Epiccash extends Bip39Currency {
  Epiccash(super.network) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        coin = Coin.epicCash;
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  String get genesisHash {
    return "not used in epiccash";
  }

  @override
  // change this to change the number of confirms a tx needs in order to show as confirmed
  int get minConfirms => 3;

  @override
  bool validateAddress(String address) {
    // Invalid address that contains HTTP and epicbox domain
    if ((address.startsWith("http://") || address.startsWith("https://")) &&
        address.contains("@")) {
      return false;
    }
    if (address.startsWith("http://") || address.startsWith("https://")) {
      if (Uri.tryParse(address) != null) {
        return true;
      }
    }

    return epic.LibEpiccash.validateSendAddress(address: address);
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
