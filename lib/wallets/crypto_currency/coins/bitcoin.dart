import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;

import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/node_model.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/default_nodes.dart';
import '../../../utilities/enums/derive_path_type_enum.dart';
import '../crypto_currency.dart';
import '../interfaces/electrumx_currency_interface.dart';
import '../interfaces/paynym_currency_interface.dart';
import '../intermediate/bip39_hd_currency.dart';

class Bitcoin extends Bip39HDCurrency
    with ElectrumXCurrencyInterface, PaynymCurrencyInterface {
  Bitcoin(super.network) {
    _idMain = "bitcoin";
    _uriScheme = "bitcoin";
    switch (network) {
      case CryptoCurrencyNetwork.main:
        _id = _idMain;
        _name = "Bitcoin";
        _ticker = "BTC";
      case CryptoCurrencyNetwork.test:
        _id = "bitcoinTestNet";
        _name = "tBitcoin";
        _ticker = "tBTC";
      case CryptoCurrencyNetwork.test4:
        _id = "bitcoinTestNet4";
        _name = "t4Bitcoin";
        _ticker = "t4BTC";
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
  // change this to change the number of confirms a tx needs in order to show as confirmed
  int get minConfirms => 1;

  @override
  bool get torSupport => true;

  @override
  List<DerivePathType> get supportedDerivationPathTypes => [
    DerivePathType.bip44,
    DerivePathType.bip49,
    DerivePathType.bip84,
    DerivePathType.bip86, // P2TR.
  ];

  @override
  String get genesisHash {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f";
      case CryptoCurrencyNetwork.test:
        return "000000000933ea01ad0ee984209779baaec3ced90fa3f408719526f8d77f4943";
      case CryptoCurrencyNetwork.test4:
        return "00000000da84f2bafbbc53dee25a72ae507ff4914b867c565be350b0da8bf043";
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  Amount get dustLimit =>
      Amount(rawValue: BigInt.from(294), fractionDigits: fractionDigits);

  @override
  coinlib.Network get networkParams {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return coinlib.Network(
          wifPrefix: 0x80,
          p2pkhPrefix: 0x00,
          p2shPrefix: 0x05,
          privHDPrefix: 0x0488ade4,
          pubHDPrefix: 0x0488b21e,
          bech32Hrp: "bc",
          messagePrefix: '\x18Bitcoin Signed Message:\n',
          minFee: BigInt.from(1), // Not used in stack wallet currently
          minOutput: dustLimit.raw, // Not used in stack wallet currently
          feePerKb: BigInt.from(1), // Not used in stack wallet currently
        );
      case CryptoCurrencyNetwork.test:
      case CryptoCurrencyNetwork.test4:
        return coinlib.Network(
          wifPrefix: 0xef,
          p2pkhPrefix: 0x6f,
          p2shPrefix: 0xc4,
          privHDPrefix: 0x04358394,
          pubHDPrefix: 0x043587cf,
          bech32Hrp: "tb",
          messagePrefix: "\x18Bitcoin Signed Message:\n",
          minFee: BigInt.from(1), // Not used in stack wallet currently
          minOutput: dustLimit.raw, // Not used in stack wallet currently
          feePerKb: BigInt.from(1), // Not used in stack wallet currently
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
      case DerivePathType.bip49:
        purpose = 49;
        break;
      case DerivePathType.bip84:
        purpose = 84;
        break;
      case DerivePathType.bip86:
        purpose = 86;
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

      // TODO: [prio=high] verify this works similarly to bitcoindart's p2sh or something(!!)
      case DerivePathType.bip49:
        final p2wpkhScript =
            coinlib.P2WPKHAddress.fromPublicKey(
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

      case DerivePathType.bip86:
        final taproot = coinlib.Taproot(internalKey: publicKey);

        final addr = coinlib.P2TRAddress.fromTaproot(
          taproot,
          hrp: networkParams.bech32Hrp,
        );

        return (address: addr, addressType: AddressType.p2tr);

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
  NodeModel defaultNode({required bool isPrimary}) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return NodeModel(
          host: "bitcoin.stackwallet.com",
          port: 50002,
          name: DefaultNodes.defaultName,
          id: DefaultNodes.buildId(this),
          useSSL: true,
          enabled: true,
          coinName: identifier,
          isFailover: true,
          isDown: false,
          torEnabled: true,
          clearnetEnabled: true,
          isPrimary: isPrimary,
        );

      case CryptoCurrencyNetwork.test:
        return NodeModel(
          host: "bitcoin-testnet.stackwallet.com",
          port: 51002,
          name: DefaultNodes.defaultName,
          id: DefaultNodes.buildId(this),
          useSSL: true,
          enabled: true,
          coinName: identifier,
          isFailover: true,
          isDown: false,
          torEnabled: true,
          clearnetEnabled: true,
          isPrimary: isPrimary,
        );

      case CryptoCurrencyNetwork.test4:
        return NodeModel(
          host: "bitcoin-testnet4.stackwallet.com",
          port: 50002,
          name: DefaultNodes.defaultName,
          id: DefaultNodes.buildId(this),
          useSSL: true,
          enabled: true,
          coinName: identifier,
          isFailover: true,
          isDown: false,
          torEnabled: true,
          clearnetEnabled: true,
          isPrimary: isPrimary,
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
  AddressType get defaultAddressType => defaultDerivePathType.getAddressType();

  @override
  BigInt get satsPerCoin => BigInt.from(100000000);

  @override
  int get targetBlockTimeSeconds => 600;

  @override
  DerivePathType get defaultDerivePathType => DerivePathType.bip86;

  @override
  Uri defaultBlockExplorer(String txid) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return Uri.parse("https://mempool.space/tx/$txid");
      case CryptoCurrencyNetwork.test:
        return Uri.parse("https://mempool.space/testnet/tx/$txid");
      case CryptoCurrencyNetwork.test4:
        return Uri.parse("https://mempool.space/testnet4/tx/$txid");
      default:
        throw Exception(
          "Unsupported network for defaultBlockExplorer(): $network",
        );
    }
  }

  @override
  int get transactionVersion => 1;

  @override
  BigInt get defaultFeeRate => BigInt.from(1000);
  // https://github.com/bitcoin/bitcoin/blob/feab35189bc00bc4cf15e9dcb5cf6b34ff3a1e91/test/functional/mempool_limit.py#L259
}
