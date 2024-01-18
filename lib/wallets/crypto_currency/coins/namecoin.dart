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
  // See https://github.com/cypherstack/stack_wallet/blob/621aff47969761014e0a6c4e699cb637d5687ab3/lib/services/coins/namecoin/namecoin_wallet.dart#L58
  int get minConfirms => 2;

  @override
  // See https://github.com/cypherstack/stack_wallet/blob/621aff47969761014e0a6c4e699cb637d5687ab3/lib/services/coins/namecoin/namecoin_wallet.dart#L80
  String constructDerivePath({
    required DerivePathType derivePathType,
    int account = 0,
    required int chain,
    required int index,
  }) {
    String coinType;
    switch (networkParams.wifPrefix) {
      case 0xb4: // NMC mainnet wif.
        coinType = "7"; // NMC mainnet.
        break;
      // TODO: [prio=low] Add testnet support.
      default:
        throw Exception("Invalid Namecoin network wif used!");
    }

    int purpose;
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
      // case CryptoCurrencyNetwork.test:
      // TODO: [prio=low] Add testnet support.
      default:
        throw UnimplementedError();
    }
  }

  @override
  // See https://github.com/cypherstack/stack_wallet/blob/621aff47969761014e0a6c4e699cb637d5687ab3/lib/services/coins/namecoin/namecoin_wallet.dart#L60
  Amount get dustLimit =>
      Amount(rawValue: BigInt.from(546), fractionDigits: Coin.particl.decimals);

  @override
  // See https://github.com/cypherstack/stack_wallet/blob/621aff47969761014e0a6c4e699cb637d5687ab3/lib/services/coins/namecoin/namecoin_wallet.dart#L6
  String get genesisHash {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return "000000000062b72c5e2ceb45fbc8587e807c155b0da735e6483dfba2f0a9c770";
      case CryptoCurrencyNetwork.test:
        return "00000007199508e34a9ff81e6ec0c477a4cccff2a4767a8eee39c11db367b008";
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

        final addr = coinlib.P2SHAddress.fromScript(
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
  // See https://github.com/cypherstack/stack_wallet/blob/621aff47969761014e0a6c4e699cb637d5687ab3/lib/services/coins/namecoin/namecoin_wallet.dart#L3474
  coinlib.NetworkParams get networkParams {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return const coinlib.NetworkParams(
          wifPrefix: 0xb4, // From 180.
          p2pkhPrefix: 0x34, // From 52.
          p2shPrefix: 0x0d, // From 13.
          privHDPrefix: 0x0488ade4,
          pubHDPrefix: 0x0488b21e,
          bech32Hrp: "nc",
          messagePrefix: '\x18Namecoin Signed Message:\n',
        );
      // case CryptoCurrencyNetwork.test:
      // TODO: [prio=low] Add testnet support.
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  List<DerivePathType> get supportedDerivationPathTypes => [
        // DerivePathType.bip16,
        DerivePathType.bip44,
        DerivePathType.bip49,
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
