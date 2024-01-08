import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/derive_path_type_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/bip39_hd_currency.dart';

class Bitcoin extends Bip39HDCurrency {
  Bitcoin(super.network) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        coin = Coin.bitcoin;
      case CryptoCurrencyNetwork.test:
        coin = Coin.bitcoinTestNet;
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
        // DerivePathType.bip49,
        DerivePathType.bip84,
      ];

  @override
  String get genesisHash {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f";
      case CryptoCurrencyNetwork.test:
        return "000000000933ea01ad0ee984209779baaec3ced90fa3f408719526f8d77f4943";
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
  coinlib.NetworkParams get networkParams {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return const coinlib.NetworkParams(
          wifPrefix: 0x80,
          p2pkhPrefix: 0x00,
          p2shPrefix: 0x05,
          privHDPrefix: 0x0488ade4,
          pubHDPrefix: 0x0488b21e,
          bech32Hrp: "bc",
          messagePrefix: '\x18Bitcoin Signed Message:\n',
        );
      case CryptoCurrencyNetwork.test:
        return const coinlib.NetworkParams(
          wifPrefix: 0xef,
          p2pkhPrefix: 0x6f,
          p2shPrefix: 0xc4,
          privHDPrefix: 0x04358394,
          pubHDPrefix: 0x043587cf,
          bech32Hrp: "tb",
          messagePrefix: "\x18Bitcoin Signed Message:\n",
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
      case 0x80:
        coinType = "0"; // btc mainnet
        break;
      case 0xef:
        coinType = "1"; // btc testnet
        break;
      default:
        throw Exception("Invalid Bitcoin network wif used!");
    }

    final int purpose;
    switch (derivePathType) {
      case DerivePathType.bip44:
        purpose = 44;
        break;
      // case DerivePathType.bip49:
      //   purpose = 49;
      //   break;
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

      // case DerivePathType.bip49:
      //   // addressString = P2SH(
      //   //         data: PaymentData(
      //   //             redeem: P2WPKH(data: data, network: _network).data),
      //   //         network: _network)
      //   //     .data
      //   //     .address!;
      //
      //   // todo ?????????????????? Does not match with current BTC
      //   final adr = coinlib.P2WPKHAddress.fromPublicKey(
      //     publicKey,
      //     hrp: networkParams.bech32Hrp,
      //   );
      //   final addr = coinlib.P2SHAddress.fromHash(
      //     adr.program.pkHash,
      //     version: networkParams.p2shPrefix,
      //   );
      //
      //   // TODO ??????????????
      //   return (address: addr, addressType: AddressType.p2sh);

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
          host: "bitcoin.stackwallet.com",
          port: 50002,
          name: DefaultNodes.defaultName,
          id: DefaultNodes.buildId(Coin.bitcoin),
          useSSL: true,
          enabled: true,
          coinName: Coin.bitcoin.name,
          isFailover: true,
          isDown: false,
        );

      case CryptoCurrencyNetwork.test:
        return NodeModel(
          host: "bitcoin-testnet.stackwallet.com",
          port: 51002,
          name: DefaultNodes.defaultName,
          id: DefaultNodes.buildId(Coin.bitcoinTestNet),
          useSSL: true,
          enabled: true,
          coinName: Coin.bitcoinTestNet.name,
          isFailover: true,
          isDown: false,
        );

      default:
        throw UnimplementedError();
    }
  }
}
