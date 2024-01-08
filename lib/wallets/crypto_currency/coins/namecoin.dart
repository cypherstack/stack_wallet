import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/derive_path_type_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/bip39_hd_currency.dart';

class Namecoin extends Bip39HDCurrency {
  Namecoin(super.network) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        coin = Coin.namecoin;
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  // TODO: implement minConfirms
  int get minConfirms => throw UnimplementedError();

  @override
  String constructDerivePath({
    required DerivePathType derivePathType,
    int account = 0,
    required int chain,
    required int index,
  }) {
    // TODO: implement constructDerivePath
    throw UnimplementedError();
  }

  @override
  NodeModel get defaultNode {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return NodeModel(
          host: "namecoin.stackwallet.com",
          port: 57002,
          name: DefaultNodes.defaultName,
          id: DefaultNodes.buildId(Coin.namecoin),
          useSSL: true,
          enabled: true,
          coinName: Coin.namecoin.name,
          isFailover: true,
          isDown: false,
        );

      default:
        throw UnimplementedError();
    }
  }

  @override
  // TODO: implement dustLimit
  Amount get dustLimit => throw UnimplementedError();

  @override
  // TODO: implement genesisHash
  String get genesisHash => throw UnimplementedError();

  @override
  ({coinlib.Address address, AddressType addressType}) getAddressForPublicKey(
      {required coinlib.ECPublicKey publicKey,
      required DerivePathType derivePathType}) {
    // TODO: implement getAddressForPublicKey
    throw UnimplementedError();
  }

  @override
  // TODO: implement networkParams
  coinlib.NetworkParams get networkParams => throw UnimplementedError();

  @override
  // TODO: implement supportedDerivationPathTypes
  List<DerivePathType> get supportedDerivationPathTypes =>
      throw UnimplementedError();

  @override
  bool validateAddress(String address) {
    // TODO: implement validateAddress
    throw UnimplementedError();
  }
}
