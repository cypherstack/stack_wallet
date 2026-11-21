import 'package:grin_native/grin_native.dart';

import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/node_model.dart';
import '../../../utilities/default_nodes.dart';
import '../../../utilities/enums/derive_path_type_enum.dart';
import '../../../wl_gen/interfaces/libgrin_interface.dart';
import '../crypto_currency.dart';
import '../intermediate/bip39_currency.dart';

class Grin extends Bip39Currency {
  /// [addressBackend] replaces the native backend for address checks.
  Grin(super.network, {this.addressBackend}) {
    _idMain = "grin";
    _uriScheme = "grin";
    switch (network) {
      case CryptoCurrencyNetwork.main:
        _id = _idMain;
        _name = "Grin";
        _ticker = "GRIN";
        _grinNetwork = GrinNetwork.mainnet;
      case CryptoCurrencyNetwork.test:
        _id = "grinTestNet";
        _name = "tGrin";
        _ticker = "tGRIN";
        _grinNetwork = GrinNetwork.testnet;
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  final GrinWalletBackend? addressBackend;
  GrinWalletBackend get _addressBackend => addressBackend ?? libGrin.backend;

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

  late final GrinNetwork _grinNetwork;

  /// The chain as the Grin library names it.
  GrinNetwork get grinNetwork => _grinNetwork;

  @override
  String get genesisHash => "not used in grin";

  /// libwallet's default.
  @override
  int get minConfirms => 10;

  /// COINBASE_MATURITY.
  @override
  int get minCoinbaseConfirms => 1440;

  @override
  bool get torSupport => true;

  /// Accepts a Slatepack address, a v3 onion address and an http(s) URL of
  /// this network.
  @override
  bool validateAddress(String address) => addressKind(address) != null;

  /// The kind of send target [address] is, or null when it is not one for
  /// this network.
  GrinAddressKind? addressKind(String address) {
    try {
      final result = _addressBackend.validateAddressSync(address, _grinNetwork);
      return result.kind == GrinAddressKind.unknown ? null : result.kind;
    } catch (_) {
      return null;
    }
  }

  /// Genesis block times, in seconds since the epoch.
  static const int genesisTimestampMain = 1547568086;
  static const int genesisTimestampTest = 1546030084;

  /// A height at or below the chain height at [date], for restore heights.
  /// Blocks are counted at 61 seconds, so the result runs a little low.
  int heightFromDate(DateTime date) {
    final genesis = network == CryptoCurrencyNetwork.main
        ? genesisTimestampMain
        : genesisTimestampTest;
    final seconds = date.millisecondsSinceEpoch ~/ 1000 - genesis;
    return seconds <= 0 ? 0 : seconds ~/ 61;
  }

  /// Whether [text] looks like an armored Slatepack.
  bool isSlatepack(String text) {
    final trimmed = text.trim();
    return trimmed.startsWith("BEGINSLATEPACK.") &&
        trimmed.endsWith("ENDSLATEPACK.");
  }

  @override
  NodeModel defaultNode({required bool isPrimary}) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return NodeModel(
          host: "https://grinnode.live",
          port: 3413,
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
          host: "http://127.0.0.1",
          port: 13413,
          name: DefaultNodes.defaultName,
          id: DefaultNodes.buildId(this),
          useSSL: false,
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
  int get defaultSeedPhraseLength => 24;

  @override
  int get fractionDigits => 9;

  @override
  bool get hasBuySupport => false;

  @override
  bool get hasMnemonicPassphraseSupport => false;

  @override
  List<int> get possibleMnemonicLengths => [defaultSeedPhraseLength, 12];

  @override
  AddressType get defaultAddressType => AddressType.mimbleWimble;

  @override
  BigInt get satsPerCoin => BigInt.from(1000000000);

  @override
  int get targetBlockTimeSeconds => 60;

  @override
  DerivePathType get defaultDerivePathType => throw UnsupportedError(
    "$runtimeType does not use bitcoin style derivation paths",
  );

  /// No explorer until a kernel search URL is chosen.
  @override
  Uri defaultBlockExplorer(String txid) =>
      throw UnsupportedError("$runtimeType has no default block explorer");

  @override
  AddressType? getAddressType(String address) =>
      validateAddress(address) ? AddressType.mimbleWimble : null;
}
