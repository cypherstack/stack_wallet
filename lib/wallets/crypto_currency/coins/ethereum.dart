import 'package:ethereum_addresses/ethereum_addresses.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/bip39_currency.dart';

class Ethereum extends Bip39Currency {
  Ethereum(super.network) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        coin = Coin.ethereum;
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  int get gasLimit => 21000;

  @override
  bool get hasTokenSupport => true;

  @override
  NodeModel get defaultNode => DefaultNodes.ethereum;

  @override
  // Not used for eth
  String get genesisHash => throw UnimplementedError();

  @override
  int get minConfirms => 3;

  @override
  bool validateAddress(String address) {
    return isValidEthereumAddress(address);
  }
}
