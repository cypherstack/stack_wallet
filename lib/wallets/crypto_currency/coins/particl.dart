import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/derive_path_type_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/bip39_hd_currency.dart';

class Particl extends Bip39HDCurrency {
  Particl(super.network) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        coin = Coin.particl;
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  // See https://github.com/cypherstack/stack_wallet/blob/d08b5c9b22b58db800ad07b2ceeb44c6d05f9cf3/lib/services/coins/particl/particl_wallet.dart#L57
  int get minConfirms => 1;

  @override
  // See https://github.com/cypherstack/stack_wallet/blob/d08b5c9b22b58db800ad07b2ceeb44c6d05f9cf3/lib/services/coins/particl/particl_wallet.dart#L68
  String constructDerivePath(
      {required DerivePathType derivePathType,
      int account = 0,
      required int chain,
      required int index}) {
    String coinType;
    switch (networkParams.wifPrefix) {
      case 0x6c: // PART mainnet wif.
        coinType = "44"; // PART mainnet.
        break;
      // TODO: [prio=low] Add testnet.
      default:
        throw Exception("Invalid Particl network wif used!");
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
          host: "particl.stackwallet.com",
          port: 58002,
          name: DefaultNodes.defaultName,
          id: DefaultNodes.buildId(Coin.particl),
          useSSL: true,
          enabled: true,
          coinName: Coin.particl.name,
          isFailover: true,
          isDown: false,
        );
      // case CryptoCurrencyNetwork.test:
      // TODO: [prio=low] Add testnet.
      default:
        throw UnimplementedError();
    }
  }

  @override
  // See https://github.com/cypherstack/stack_wallet/blob/d08b5c9b22b58db800ad07b2ceeb44c6d05f9cf3/lib/services/coins/particl/particl_wallet.dart#L58
  Amount get dustLimit => Amount(
        rawValue: BigInt.from(294),
        fractionDigits: Coin.particl.decimals,
      );

  @override
  // See https://github.com/cypherstack/stack_wallet/blob/d08b5c9b22b58db800ad07b2ceeb44c6d05f9cf3/lib/services/coins/particl/particl_wallet.dart#L63
  String get genesisHash {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return "0000ee0784c195317ac95623e22fddb8c7b8825dc3998e0bb924d66866eccf4c";
      case CryptoCurrencyNetwork.test:
        return "0000594ada5310b367443ee0afd4fa3d0bbd5850ea4e33cdc7d6a904a7ec7c90";
      default:
        throw Exception("Unsupported network: $network");
    }
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
  // See https://github.com/cypherstack/stack_wallet/blob/d08b5c9b22b58db800ad07b2ceeb44c6d05f9cf3/lib/services/coins/particl/particl_wallet.dart#L3532
  coinlib.NetworkParams get networkParams {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return const coinlib.NetworkParams(
          wifPrefix: 0x6c,
          p2pkhPrefix: 0x38,
          p2shPrefix: 0x3c,
          privHDPrefix: 0x8f1daeb8,
          pubHDPrefix: 0x696e82d1,
          bech32Hrp: "pw",
          messagePrefix: '\x18Bitcoin Signed Message:\n',
        );
      // case CryptoCurrencyNetwork.test:
      // TODO: [prio=low] Add testnet.
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  List<DerivePathType> get supportedDerivationPathTypes => [
        DerivePathType.bip44,
        DerivePathType.bip84,
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
}
