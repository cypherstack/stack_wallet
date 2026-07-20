import 'package:xrpl_dart/xrpl_dart.dart';

import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/node_model.dart';
import '../../../utilities/default_nodes.dart';
import '../../../utilities/enums/derive_path_type_enum.dart';
import '../crypto_currency.dart';
import '../interfaces/view_only_option_currency_interface.dart';
import '../intermediate/bip39_currency.dart';

/// XRP (XRP Ledger). Account-based coin, modelled on [Stellar]:
/// single account/address per wallet, reserves + activation, fees in drops
/// (1 XRP = 1,000,000 drops), rippled JSON-RPC access.
class Xrp extends Bip39Currency with ViewOnlyOptionCurrencyInterface {
  Xrp(super.network) {
    _idMain = "xrp";
    _uriScheme = "ripple";
    switch (network) {
      case CryptoCurrencyNetwork.main:
        _id = _idMain;
        _name = "XRP";
        _ticker = "XRP";
      case CryptoCurrencyNetwork.test:
        _id = "xrpTestnet";
        _name = "tXRP";
        _ticker = "tXRP";
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
  String get genesisHash => throw UnimplementedError("Not used for xrp");

  @override
  NodeModel defaultNode({required bool isPrimary}) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return NodeModel(
          host: "https://xrplcluster.com",
          port: 443,
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
          host: "https://s.altnet.rippletest.net",
          port: 51234,
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
        throw Exception("Unsupported network");
    }
  }

  @override
  bool validateAddress(String address) {
    try {
      // Accepts both classic "r..." and X-addresses; throws if invalid.
      XRPAddress(address, allowXAddress: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  int get defaultSeedPhraseLength => 24;

  @override
  int get fractionDigits => 6; // 1 XRP = 1,000,000 drops

  @override
  bool get hasBuySupport => false;

  @override
  bool get hasMnemonicPassphraseSupport => true;

  @override
  List<int> get possibleMnemonicLengths => [defaultSeedPhraseLength, 12];

  @override
  AddressType get defaultAddressType => AddressType.xrp;

  @override
  BigInt get satsPerCoin => BigInt.from(1000000);

  @override
  int get targetBlockTimeSeconds => 4;

  @override
  DerivePathType get defaultDerivePathType => throw UnsupportedError(
    "$runtimeType does not use bitcoin style derivation paths",
  );

  @override
  Uri defaultBlockExplorer(String txid) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return Uri.parse("https://livenet.xrpl.org/transactions/$txid");
      case CryptoCurrencyNetwork.test:
        return Uri.parse("https://testnet.xrpl.org/transactions/$txid");
      default:
        throw Exception(
          "Unsupported network for defaultBlockExplorer(): $network",
        );
    }
  }

  @override
  AddressType? getAddressType(String address) {
    if (validateAddress(address)) {
      return AddressType.xrp;
    }
    return null;
  }

  /// The XRP account activation / base reserve in drops. XRPL reserves are
  /// adjustable by validator fee-vote, so this is only a conservative fallback
  /// for UI/estimation; the wallet reads the live reserve from `server_info`.
  BigInt get fallbackBaseReserveDrops => BigInt.from(1000000); // 1 XRP
}
