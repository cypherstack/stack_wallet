import 'package:stackwallet/models/node_model.dart';
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
  // TODO: implement defaultNode
  NodeModel get defaultNode => throw UnimplementedError();

  @override
  // TODO: implement genesisHash
  String get genesisHash => throw UnimplementedError();

  @override
  // TODO: implement minConfirms
  int get minConfirms => throw UnimplementedError();

  @override
  bool validateAddress(String address) {
    // TODO: implement validateAddress
    throw UnimplementedError();
  }
}
