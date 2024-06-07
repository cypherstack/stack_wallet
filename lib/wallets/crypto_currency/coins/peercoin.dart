import 'package:coinlib/src/network.dart';
import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;

import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/node_model.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/default_nodes.dart';
import '../../../utilities/enums/derive_path_type_enum.dart';
import '../crypto_currency.dart';
import '../interfaces/electrumx_currency_interface.dart';
import '../intermediate/bip39_hd_currency.dart';

class Peercoin extends Bip39HDCurrency with ElectrumXCurrencyInterface {
  Peercoin(super.network) {
    _idMain = "peercoin";
    _uriScheme = "peercoin";
    switch (network) {
      case CryptoCurrencyNetwork.main:
        _id = "peercoin";
        _name = "Peercoin";
        _ticker = "PPC";
      case CryptoCurrencyNetwork.test:
        _id = "peercoinTestNet";
        _name = "tPeercoin";
        _ticker = "tPPC";
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
  String constructDerivePath({
    required DerivePathType derivePathType,
    int account = 0,
    required int chain,
    required int index,
  }) {
    String coinType;
    switch (networkParams.wifPrefix) {
      case 183: // PPC mainnet wif.
        coinType =
            "6"; // according to https://github.com/satoshilabs/slips/blob/master/slip-0044.md
        break;
      case 239: // PPC testnet wif.
        coinType = "1";
        break;
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
        return NodeModel(
          host: "testnet-electrum.peercoinexplorer.net",
          port: 50002,
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
  Amount get dustLimit => Amount(
        // TODO should this be 10000 instead of 294 for peercoin?
        rawValue: BigInt.from(294),
        fractionDigits: fractionDigits,
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
  ({coinlib.Address address, AddressType addressType}) getAddressForPublicKey({
    required coinlib.ECPublicKey publicKey,
    required DerivePathType derivePathType,
  }) {
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
  int get fractionDigits => 6;

  @override
  bool get hasBuySupport => false;

  @override
  bool get hasMnemonicPassphraseSupport => true;

  @override
  List<int> get possibleMnemonicLengths => [defaultSeedPhraseLength, 24];

  @override
  AddressType get primaryAddressType => AddressType.p2wpkh;

  @override
  BigInt get satsPerCoin => BigInt.from(1000000); // 1*10^6.

  @override
  int get targetBlockTimeSeconds => 600;

  @override
  DerivePathType get primaryDerivePathType => DerivePathType.bip84;

  @override
  Uri defaultBlockExplorer(String txid) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return Uri.parse("https://chainz.cryptoid.info/ppc/tx.dws?$txid.htm");
      case CryptoCurrencyNetwork.test:
        return Uri.parse(
          "https://chainz.cryptoid.info/ppc-test/search.dws?q=$txid.htm",
        );
      default:
        throw Exception(
          "Unsupported network for defaultBlockExplorer(): $network",
        );
    }
  }

  @override
  int get transactionVersion => 3;

  @override
  BigInt get defaultFeeRate => BigInt.from(5000);
}
