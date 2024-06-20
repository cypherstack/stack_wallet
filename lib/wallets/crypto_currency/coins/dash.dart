import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;

import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/node_model.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/enums/derive_path_type_enum.dart';
import '../crypto_currency.dart';
import '../interfaces/electrumx_currency_interface.dart';
import '../intermediate/bip39_hd_currency.dart';

class Dash extends Bip39HDCurrency with ElectrumXCurrencyInterface {
  Dash(super.network) {
    _idMain = "dash";
    _uriScheme = "dash";
    switch (network) {
      case CryptoCurrencyNetwork.main:
        _id = _idMain;
        _name = "Dash";
        _ticker = "DASH";
      case CryptoCurrencyNetwork.test:
        _id = "dashTestNet";
        _name = "tDash";
        _ticker = "tDASH";
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
  bool get torSupport => true;

  @override
  List<DerivePathType> get supportedDerivationPathTypes => [
        DerivePathType.bip44,
      ];

  @override
  String constructDerivePath({
    required DerivePathType derivePathType,
    int account = 0,
    required int chain,
    required int index,
  }) {
    String coinType;

    switch (networkParams.wifPrefix) {
      case 204: // dash mainnet wif
        coinType = "5"; // dash mainnet
        break;
      case 239: // dash testnet wif
        coinType = "1"; // dash testnet
        break;
      default:
        throw Exception("Invalid Dash network wif used!");
    }

    int purpose;
    switch (derivePathType) {
      case DerivePathType.bip44:
        purpose = 44;
        break;

      default:
        throw Exception("DerivePathType $derivePathType not supported");
    }

    return "m/$purpose'/$coinType'/$account'/$chain/$index";
  }

  @override
  Amount get dustLimit => Amount(
        rawValue: BigInt.from(1000000),
        fractionDigits: fractionDigits,
      );

  @override
  String get genesisHash {
    switch (network) {
      // TODO
      // case CryptoCurrencyNetwork.main:
      //   return " ";
      // case CryptoCurrencyNetwork.test:
      //   return " ";
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  ({
    coinlib.Address address,
    AddressType addressType,
  }) getAddressForPublicKey({
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

      default:
        throw Exception("DerivePathType $derivePathType not supported");
    }
  }

  @override
  int get minConfirms => 1;

  @override
  coinlib.Network get networkParams {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return coinlib.Network(
          p2pkhPrefix: 76,
          p2shPrefix: 16,
          wifPrefix: 204,
          pubHDPrefix: 0x0488B21E,
          privHDPrefix: 0x0488ADE4,
          bech32Hrp: "dash", // TODO ?????
          messagePrefix: '\x18Dash Signed Message:\n', // TODO ?????
          minFee: BigInt.from(1), // Not used in stack wallet currently
          minOutput: dustLimit.raw, // Not used in stack wallet currently
          feePerKb: BigInt.from(1), // Not used in stack wallet currently
        );
      case CryptoCurrencyNetwork.test:
        return coinlib.Network(
          p2pkhPrefix: 140,
          p2shPrefix: 19,
          wifPrefix: 239,
          pubHDPrefix: 0x043587CF,
          privHDPrefix: 0x04358394,
          bech32Hrp: "tdash", // TODO ?????
          messagePrefix: '\x18Dash Signed Message:\n', // TODO ?????
          minFee: BigInt.from(1), // Not used in stack wallet currently
          minOutput: dustLimit.raw, // Not used in stack wallet currently
          feePerKb: BigInt.from(1), // Not used in stack wallet currently
        );
      default:
        throw Exception("Unsupported network: $network");
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
      // case CryptoCurrencyNetwork.main:
      //   return NodeModel(
      //     host: "dash.stackwallet.com",
      //     port: 50022,
      //     name: DefaultNodes.defaultName,
      //     id: DefaultNodes.buildId(this),
      //     useSSL: true,
      //     enabled: true,
      //     coinName: identifier,
      //     isFailover: true,
      //     isDown: false,
      //   );
      //
      // case CryptoCurrencyNetwork.test:
      //   return NodeModel(
      //     host: "dash-testnet.stackwallet.com",
      //     port: 50022,
      //     name: DefaultNodes.defaultName,
      //     id: DefaultNodes.buildId(this),
      //     useSSL: true,
      //     enabled: true,
      //     coinName: identifier,
      //     isFailover: true,
      //     isDown: false,
      //   );

      default:
        throw UnimplementedError();
    }
  }

  @override
  int get defaultSeedPhraseLength => 12;

  @override
  int get fractionDigits => 8;

  @override
  bool get hasBuySupport => true;

  @override
  bool get hasMnemonicPassphraseSupport => true;

  @override
  List<int> get possibleMnemonicLengths => [defaultSeedPhraseLength, 24];

  @override
  AddressType get defaultAddressType => defaultDerivePathType.getAddressType();

  @override
  BigInt get satsPerCoin => BigInt.from(100000000);

  @override
  int get targetBlockTimeSeconds => 60;

  @override
  DerivePathType get defaultDerivePathType => DerivePathType.bip44;

  @override
  Uri defaultBlockExplorer(String txid) {
    switch (network) {
      // TODO
      // case CryptoCurrencyNetwork.main:
      // case CryptoCurrencyNetwork.test:
      default:
        throw Exception(
          "Unsupported network for defaultBlockExplorer(): $network",
        );
    }
  }

  @override
  int get transactionVersion => 1;

  @override
  BigInt get defaultFeeRate => BigInt.from(1000); // TODO check for dash?
}
