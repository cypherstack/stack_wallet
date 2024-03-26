import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/derive_path_type_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/bip39_hd_currency.dart';

class Litecoin extends Bip39HDCurrency {
  Litecoin(super.network) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        coin = Coin.litecoin;
      case CryptoCurrencyNetwork.test:
        coin = Coin.litecoinTestNet;
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  // change this to change the number of confirms a tx needs in order to show as confirmed
  int get minConfirms => 1;

  @override
  List<DerivePathType> get supportedDerivationPathTypes => [
        DerivePathType.bip44,
        DerivePathType.bip49,
        DerivePathType.bip84,
      ];

  @override
  String get genesisHash {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return "12a765e31ffd4059bada1e25190f6e98c99d9714d334efa41a195a7e7e04bfe2";
      case CryptoCurrencyNetwork.test:
        return "4966625a4b2851d9fdee139e56211a0d88575f59ed816ff5e6a63deb4e3e29a0";
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  Amount get dustLimit => Amount(
        rawValue: BigInt.from(294),
        fractionDigits: fractionDigits,
      );

  Amount get dustLimitP2PKH => Amount(
        rawValue: BigInt.from(546),
        fractionDigits: fractionDigits,
      );

  @override
  coinlib.Network get networkParams {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return coinlib.Network(
          wifPrefix: 0xb0,
          p2pkhPrefix: 0x30,
          p2shPrefix: 0x32,
          privHDPrefix: 0x0488ade4,
          pubHDPrefix: 0x0488b21e,
          bech32Hrp: "ltc",
          messagePrefix: '\x19Litecoin Signed Message:\n',
          minFee: BigInt.from(1), // TODO [prio=high].
          minOutput: BigInt.from(1), // TODO.
          feePerKb: BigInt.from(1), // TODO.
        );
      case CryptoCurrencyNetwork.test:
        return coinlib.Network(
          wifPrefix: 0xef,
          p2pkhPrefix: 0x6f,
          p2shPrefix: 0x3a,
          privHDPrefix: 0x04358394,
          pubHDPrefix: 0x043587cf,
          bech32Hrp: "tltc",
          messagePrefix: "\x19Litecoin Signed Message:\n",
          minFee: BigInt.from(1), // TODO [prio=high].
          minOutput: BigInt.from(1), // TODO.
          feePerKb: BigInt.from(1), // TODO.
        );
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  String constructDerivePath({
    required DerivePathType derivePathType,
    int account = 0,
    required int chain,
    required int index,
  }) {
    String coinType;

    switch (networkParams.wifPrefix) {
      case 0xb0: // ltc mainnet wif
        coinType = "2"; // ltc mainnet
        break;
      case 0xef: // ltc testnet wif
        coinType = "1"; // ltc testnet
        break;
      default:
        throw Exception("Invalid Bitcoin network wif used!");
    }

    final int purpose;
    switch (derivePathType) {
      case DerivePathType.bip44:
        purpose = 44;
        break;
      case DerivePathType.bip49:
        purpose = 49;
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
  ({coinlib.Address address, AddressType addressType}) getAddressForPublicKey({
    required coinlib.ECPublicKey publicKey,
    required DerivePathType derivePathType,
  }) {
    switch (derivePathType) {
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
  bool validateAddress(String address) {
    try {
      coinlib.Address.fromString(address, networkParams);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  NodeModel get defaultNode {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return NodeModel(
          host: "litecoin.stackwallet.com",
          port: 20063,
          name: DefaultNodes.defaultName,
          id: DefaultNodes.buildId(Coin.litecoin),
          useSSL: true,
          enabled: true,
          coinName: Coin.litecoin.name,
          isFailover: true,
          isDown: false,
        );

      case CryptoCurrencyNetwork.test:
        return NodeModel(
          host: "litecoin.stackwallet.com",
          port: 51002,
          name: DefaultNodes.defaultName,
          id: DefaultNodes.buildId(Coin.litecoinTestNet),
          useSSL: true,
          enabled: true,
          coinName: Coin.litecoinTestNet.name,
          isFailover: true,
          isDown: false,
        );

      default:
        throw UnimplementedError();
    }
  }
}
