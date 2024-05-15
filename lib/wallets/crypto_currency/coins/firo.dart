import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/derive_path_type_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/interfaces/electrumx_currency_interface.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/bip39_hd_currency.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/spark_interface.dart';

class Firo extends Bip39HDCurrency with ElectrumXCurrencyInterface {
  Firo(super.network) {
    _idMain = "firo";
    _uriScheme = "firo";
    switch (network) {
      case CryptoCurrencyNetwork.main:
        _id = _idMain;
        _name = "Firo";
        _ticker = "FIRO";
      case CryptoCurrencyNetwork.test:
        _id = "firoTestNet";
        _name = "tFiro";
        _ticker = "tFIRO";
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
  int get minConfirms => 1;

  @override
  bool get torSupport => true;

  @override
  List<DerivePathType> get supportedDerivationPathTypes => [
        DerivePathType.bip44,
      ];

  @override
  String get genesisHash {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return "4381deb85b1b2c9843c222944b616d997516dcbd6a964e1eaf0def0830695233";
      case CryptoCurrencyNetwork.test:
        return "aa22adcc12becaf436027ffe62a8fb21b234c58c23865291e5dc52cf53f64fca";
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  Amount get dustLimit => Amount(
        rawValue: BigInt.from(1000),
        fractionDigits: fractionDigits,
      );

  @override
  coinlib.Network get networkParams {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return coinlib.Network(
          wifPrefix: 0xd2,
          p2pkhPrefix: 0x52,
          p2shPrefix: 0x07,
          privHDPrefix: 0x0488ade4,
          pubHDPrefix: 0x0488b21e,
          bech32Hrp: "bc",
          messagePrefix: '\x18Zcoin Signed Message:\n',
          minFee: BigInt.from(1), // TODO [prio=high].
          minOutput: dustLimit.raw, // TODO.
          feePerKb: BigInt.from(1), // TODO.
        );
      case CryptoCurrencyNetwork.test:
        return coinlib.Network(
          wifPrefix: 0xb9,
          p2pkhPrefix: 0x41,
          p2shPrefix: 0xb2,
          privHDPrefix: 0x04358394,
          pubHDPrefix: 0x043587cf,
          bech32Hrp: "tb",
          messagePrefix: "\x18Zcoin Signed Message:\n",
          minFee: BigInt.from(1), // TODO [prio=high].
          minOutput: dustLimit.raw, // TODO.
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
      case 0xd2: // firo mainnet wif
        coinType = "136"; // firo mainnet
        break;
      case 0xb9: // firo testnet wif
        coinType = "1"; // firo testnet
        break;
      default:
        throw Exception("Invalid Firo network wif used!");
    }

    final int purpose;
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
      return validateSparkAddress(address);
    }
  }

  bool validateSparkAddress(String address) {
    return SparkInterface.validateSparkAddress(
      address: address,
      isTestNet: network == CryptoCurrencyNetwork.test,
    );
  }

  @override
  NodeModel get defaultNode {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return NodeModel(
          host: "firo.stackwallet.com",
          port: 50002,
          name: DefaultNodes.defaultName,
          id: DefaultNodes.buildId(this),
          useSSL: true,
          enabled: true,
          coinName: identifier,
          isFailover: true,
          isDown: false,
        );

      case CryptoCurrencyNetwork.test:
        // NodeModel(
        //       host: "firo-testnet.stackwallet.com",
        //       port: 50002,
        //       name: DefaultNodes.defaultName,
        //       id: _nodeId(Coin.firoTestNet),
        //       useSSL: true,
        //       enabled: true,
        //       coinName: Coin.firoTestNet.name,
        //       isFailover: true,
        //       isDown: false,
        //     );

        // TODO revert to above eventually
        return NodeModel(
          host: "95.179.164.13",
          port: 51002,
          name: DefaultNodes.defaultName,
          id: DefaultNodes.buildId(this),
          useSSL: true,
          enabled: true,
          coinName: identifier,
          isFailover: true,
          isDown: false,
        );

      default:
        throw UnimplementedError();
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
  AddressType get primaryAddressType => AddressType.p2pkh;

  @override
  BigInt get satsPerCoin => BigInt.from(100000000);

  @override
  int get targetBlockTimeSeconds => 150;

  @override
  DerivePathType get primaryDerivePathType => DerivePathType.bip44;

  @override
  Uri defaultBlockExplorer(String txid) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return Uri.parse("https://explorer.firo.org/tx/$txid");
      case CryptoCurrencyNetwork.test:
        return Uri.parse("https://testexplorer.firo.org/tx/$txid");
      default:
        throw Exception(
          "Unsupported network for defaultBlockExplorer(): $network",
        );
    }
  }
}
