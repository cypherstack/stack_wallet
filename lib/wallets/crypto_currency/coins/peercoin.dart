import 'package:coinlib/src/network.dart';
import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/derive_path_type_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/bip39_hd_currency.dart';

class Peercoin extends Bip39HDCurrency {
  Peercoin(super.network) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        coin = Coin.peercoin;
      case CryptoCurrencyNetwork.test:
        coin = Coin.peercoinTestNet;
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  int get minConfirms => 1;

  @override
  bool get torSupport => true;

  @override
  String constructDerivePath(
      {required DerivePathType derivePathType,
      int account = 0,
      required int chain,
      required int index}) {
    String coinType;
    switch (networkParams.wifPrefix) {
      case 183: // PPC mainnet wif.
        coinType = "10"; // PPC mainnet.
        break;
      // TODO: [prio=low] Add testnet.
      default:
        throw Exception("Invalid Peercoin network wif used!");
    }

    int purpose;
    switch (derivePathType) {
      case DerivePathType.bip44:
        purpose = 44;
        break;
      case DerivePathType.bip84:
        purpose = 84;
        break;
      default:
        throw Exception("DerivePathType $derivePathType not supported");
    }

    return "m/$purpose'/$coinType'/$account'/$chain/$index";
  }

  @override
  NodeModel get defaultNode {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return NodeModel(
          host: "electrum.peercoinexplorer.net",
          port: 50004,
          name: DefaultNodes.defaultName,
          id: DefaultNodes.buildId(Coin.peercoin),
          useSSL: true,
          enabled: true,
          coinName: Coin.peercoin.name,
          isFailover: true,
          isDown: false,
        );
      case CryptoCurrencyNetwork.test:
        return NodeModel(
          host: "testnet-electrum.peercoinexplorer.net",
          port: 50009,
          name: DefaultNodes.defaultName,
          id: DefaultNodes.buildId(Coin.peercoinTestNet),
          useSSL: false, // TODO [prio=med]: Is this safe?
          enabled: true,
          coinName: Coin.peercoinTestNet.name,
          isFailover: true,
          isDown: false,
        );
      default:
        throw UnimplementedError();
    }
  }

  @override
  Amount get dustLimit => Amount(
        rawValue: BigInt.from(294),
        fractionDigits: Coin.peercoin.decimals,
      );

  @override
  String get genesisHash {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return "0000000032fe677166d54963b62a4677d8957e87c508eaa4fd7eb1c880cd27e3";
      case CryptoCurrencyNetwork.test:
        return "00000001f757bb737f6596503e17cd17b0658ce630cc727c0cca81aec47c9f06";
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  ({coinlib.Address address, AddressType addressType}) getAddressForPublicKey(
      {required coinlib.ECPublicKey publicKey,
      required DerivePathType derivePathType}) {
    switch (derivePathType) {
      // case DerivePathType.bip16:

      case DerivePathType.bip44:
        final addr = coinlib.P2PKHAddress.fromPublicKey(
          publicKey,
          version: networkParams.p2pkhPrefix,
        );

        return (address: addr, addressType: AddressType.p2pkh);

      case DerivePathType.bip49:
        final p2wpkhScript = coinlib.P2WPKHAddress.fromPublicKey(
          publicKey,
          hrp: networkParams.bech32Hrp,
        ).program.script;

        final addr = coinlib.P2SHAddress.fromRedeemScript(
          p2wpkhScript,
          version: networkParams.p2shPrefix,
        );

        return (address: addr, addressType: AddressType.p2sh);

      case DerivePathType.bip84:
        final addr = coinlib.P2WPKHAddress.fromPublicKey(
          publicKey,
          hrp: networkParams.bech32Hrp,
        );

        return (address: addr, addressType: AddressType.p2wpkh);

      default:
        throw Exception("DerivePathType $derivePathType not supported");
    }
  }

  @override
  coinlib.Network get networkParams {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return Network.mainnet;
      case CryptoCurrencyNetwork.test:
        return Network.testnet;
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  List<DerivePathType> get supportedDerivationPathTypes => [
        DerivePathType.bip44,
      ];

  @override
  bool validateAddress(String address) {
    try {
      coinlib.Address.fromString(address, networkParams);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    return other is Peercoin && other.network == network;
  }

  @override
  int get hashCode => Object.hash(Peercoin, network);
}
