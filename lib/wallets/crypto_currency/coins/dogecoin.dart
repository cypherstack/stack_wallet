import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;

import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/node_model.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/default_nodes.dart';
import '../../../utilities/enums/derive_path_type_enum.dart';
import '../crypto_currency.dart';
import '../interfaces/electrumx_currency_interface.dart';
import '../intermediate/bip39_hd_currency.dart';

class Dogecoin extends Bip39HDCurrency with ElectrumXCurrencyInterface {
  Dogecoin(super.network) {
    _idMain = "dogecoin";
    _uriScheme = "dogecoin";
    switch (network) {
      case CryptoCurrencyNetwork.main:
        _id = _idMain;
        _name = "Dogecoin";
        _ticker = "DOGE";
      case CryptoCurrencyNetwork.test:
        _id = "dogecoinTestNet";
        _name = "tDogecoin";
        _ticker = "tDOGE";
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
      case 0x9e: // doge mainnet wif
        coinType = "3"; // doge mainnet
        break;
      case 0xf1: // doge testnet wif
        coinType = "1"; // doge testnet
        break;
      default:
        throw Exception("Invalid Dogecoin network wif used!");
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
      case CryptoCurrencyNetwork.main:
        return "1a91e3dace36e2be3bf030a65679fe821aa1d6ef92e7c9902eb318182c355691";
      case CryptoCurrencyNetwork.test:
        return "bb0a78264637406b6360aad926284d544d7049f45189db5664f3c4d07350559e";
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
          wifPrefix: 0x9e,
          p2pkhPrefix: 0x1e,
          p2shPrefix: 0x16,
          privHDPrefix: 0x02fac398,
          pubHDPrefix: 0x02facafd,
          bech32Hrp: "doge",
          messagePrefix: '\x18Dogecoin Signed Message:\n',
          minFee: BigInt.from(1), // Not used in stack wallet currently
          minOutput: dustLimit.raw, // Not used in stack wallet currently
          feePerKb: BigInt.from(1), // Not used in stack wallet currently
        );
      case CryptoCurrencyNetwork.test:
        return coinlib.Network(
          wifPrefix: 0xf1,
          p2pkhPrefix: 0x71,
          p2shPrefix: 0xc4,
          privHDPrefix: 0x04358394,
          pubHDPrefix: 0x043587cf,
          bech32Hrp: "tdge",
          messagePrefix: "\x18Dogecoin Signed Message:\n",
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
      case CryptoCurrencyNetwork.main:
        return NodeModel(
          host: "dogecoin.stackwallet.com",
          port: 50022,
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
          host: "dogecoin-testnet.stackwallet.com",
          port: 50022,
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
  bool get hasBuySupport => true;

  @override
  bool get hasMnemonicPassphraseSupport => true;

  @override
  List<int> get possibleMnemonicLengths => [defaultSeedPhraseLength, 24];

  @override
  AddressType get primaryAddressType => AddressType.p2pkh;

  @override
  BigInt get satsPerCoin => BigInt.from(100000000);

  @override
  int get targetBlockTimeSeconds => 60;

  @override
  DerivePathType get primaryDerivePathType => DerivePathType.bip44;

  @override
  Uri defaultBlockExplorer(String txid) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return Uri.parse("https://chain.so/tx/DOGE/$txid");
      case CryptoCurrencyNetwork.test:
        return Uri.parse("https://chain.so/tx/DOGETEST/$txid");
      default:
        throw Exception(
          "Unsupported network for defaultBlockExplorer(): $network",
        );
    }
  }

  @override
  int get transactionVersion => 1;

  @override
  int get defaultFeeRate => 1000000;
  // https://github.com/dogecoin/dogecoin/blob/master/doc/fee-recommendation.md
}
