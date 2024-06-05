import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;

import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/node_model.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/default_nodes.dart';
import '../../../utilities/enums/derive_path_type_enum.dart';
import '../crypto_currency.dart';
import '../interfaces/electrumx_currency_interface.dart';
import '../intermediate/bip39_hd_currency.dart';

class Namecoin extends Bip39HDCurrency with ElectrumXCurrencyInterface {
  Namecoin(super.network) {
    _idMain = "namecoin";
    _uriScheme = "namecoin";
    switch (network) {
      case CryptoCurrencyNetwork.main:
        _id = _idMain;
        _name = "Namecoin";
        _ticker = "NMC";
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
  // See https://github.com/cypherstack/stack_wallet/blob/621aff47969761014e0a6c4e699cb637d5687ab3/lib/services/coins/namecoin/namecoin_wallet.dart#L58
  int get minConfirms => 2;

  @override
  bool get torSupport => true;

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
          id: DefaultNodes.buildId(this),
          useSSL: true,
          enabled: true,
          coinName: identifier,
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
  Amount get dustLimit => Amount(
        rawValue: BigInt.from(546),
        fractionDigits: fractionDigits,
      );

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
  // See https://github.com/cypherstack/stack_wallet/blob/621aff47969761014e0a6c4e699cb637d5687ab3/lib/services/coins/namecoin/namecoin_wallet.dart#L3474
  coinlib.Network get networkParams {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return coinlib.Network(
          wifPrefix: 0xb4, // From 180.
          p2pkhPrefix: 0x34, // From 52.
          p2shPrefix: 0x0d, // From 13.
          privHDPrefix: 0x0488ade4,
          pubHDPrefix: 0x0488b21e,
          bech32Hrp: "nc",
          messagePrefix: '\x18Namecoin Signed Message:\n',
          minFee: BigInt.from(1), // TODO [prio=high].
          minOutput: dustLimit.raw, // TODO.
          feePerKb: BigInt.from(1), // TODO.
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

  @override
  int get defaultSeedPhraseLength => 12;

  @override
  int get fractionDigits => 8;

  @override
  bool get hasBuySupport => false;

  @override
  bool get hasMnemonicPassphraseSupport => true;

  @override
  List<int> get possibleMnemonicLengths => [defaultSeedPhraseLength, 12];

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
        return Uri.parse("https://chainz.cryptoid.info/nmc/tx.dws?$txid.htm");
      default:
        throw Exception(
          "Unsupported network for defaultBlockExplorer(): $network",
        );
    }
  }

  @override
  int get transactionVersion => 1;
}
