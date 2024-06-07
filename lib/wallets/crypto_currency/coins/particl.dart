import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;

import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/node_model.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/default_nodes.dart';
import '../../../utilities/enums/derive_path_type_enum.dart';
import '../crypto_currency.dart';
import '../interfaces/electrumx_currency_interface.dart';
import '../intermediate/bip39_hd_currency.dart';

class Particl extends Bip39HDCurrency with ElectrumXCurrencyInterface {
  Particl(super.network) {
    _idMain = "particl";
    _uriScheme = "particl";
    switch (network) {
      case CryptoCurrencyNetwork.main:
        _id = _idMain;
        _name = "Particl";
        _ticker = "PART";
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  late final String _id;
  @override
  String get identifier => _id;

  late final String _idMain;
  @override
  String get mainNetId => _idMain;

  late final String _name;
  @override
  String get prettyName => _name;

  late final String _uriScheme;
  @override
  String get uriScheme => _uriScheme;

  late final String _ticker;
  @override
  String get ticker => _ticker;

  @override
  // See https://github.com/cypherstack/stack_wallet/blob/d08b5c9b22b58db800ad07b2ceeb44c6d05f9cf3/lib/services/coins/particl/particl_wallet.dart#L57
  int get minConfirms => 1;

  @override
  bool get torSupport => true;

  @override
  // See https://github.com/cypherstack/stack_wallet/blob/d08b5c9b22b58db800ad07b2ceeb44c6d05f9cf3/lib/services/coins/particl/particl_wallet.dart#L68
  String constructDerivePath({
    required DerivePathType derivePathType,
    int account = 0,
    required int chain,
    required int index,
  }) {
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
          id: DefaultNodes.buildId(this),
          useSSL: true,
          enabled: true,
          coinName: identifier,
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
        fractionDigits: fractionDigits,
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
  coinlib.Network get networkParams {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return coinlib.Network(
          wifPrefix: 0x6c,
          p2pkhPrefix: 0x38,
          p2shPrefix: 0x3c,
          privHDPrefix: 0x8f1daeb8,
          pubHDPrefix: 0x696e82d1,
          bech32Hrp: "pw",
          messagePrefix: '\x18Bitcoin Signed Message:\n',
          minFee: BigInt.from(1), // Not used in stack wallet currently
          minOutput: dustLimit.raw, // Not used in stack wallet currently
          feePerKb: BigInt.from(1), // Not used in stack wallet currently
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

  @override
  int get defaultSeedPhraseLength => 12;

  @override
  int get fractionDigits => 8;

  @override
  bool get hasBuySupport => false;

  @override
  bool get hasMnemonicPassphraseSupport => true;

  @override
  List<int> get possibleMnemonicLengths => [defaultSeedPhraseLength, 24];

  @override
  AddressType get primaryAddressType => AddressType.p2wpkh;

  @override
  BigInt get satsPerCoin => BigInt.from(100000000);

  @override
  int get targetBlockTimeSeconds => 600;

  @override
  DerivePathType get primaryDerivePathType => DerivePathType.bip84;

  @override
  Uri defaultBlockExplorer(String txid) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return Uri.parse("https://chainz.cryptoid.info/part/tx.dws?$txid.htm");
      default:
        throw Exception(
          "Unsupported network for defaultBlockExplorer(): $network",
        );
    }
  }

  @override
  int get transactionVersion => 1;

  @override
  BigInt get defaultFeeRate => BigInt.from(20000);
}
