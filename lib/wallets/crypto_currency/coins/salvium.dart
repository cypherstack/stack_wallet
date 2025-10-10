import '../../../models/node_model.dart';
import '../../../utilities/default_nodes.dart';
import '../../../utilities/enums/derive_path_type_enum.dart';
import '../../../wl_gen/interfaces/cs_salvium_interface.dart';
import '../crypto_currency.dart';
import '../intermediate/cryptonote_currency.dart';

class Salvium extends CryptonoteCurrency {
  Salvium(super.network) {
    _idMain = "salvium";
    _uriScheme = "salvium";
    switch (network) {
      case CryptoCurrencyNetwork.main:
        _id = _idMain;
        _name = "Salvium";
        _ticker = "SAL";
      case CryptoCurrencyNetwork.test:
        _id = "${_idMain}TestNet";
        _name = "tSalvium";
        _ticker = "tSAL";
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
  int get minConfirms => 10;

  @override
  bool get torSupport => true;

  @override
  bool validateAddress(String address) {
    if (address.contains("111")) {
      return false;
    }
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return csSalvium.validateAddress(address, 0);
      case CryptoCurrencyNetwork.test:
        return csSalvium.validateAddress(address, 1);
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  NodeModel defaultNode({required bool isPrimary}) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return NodeModel(
          host: "https://salvium.stackwallet.com",
          port: 19081,
          name: DefaultNodes.defaultName,
          id: DefaultNodes.buildId(this),
          useSSL: true,
          enabled: true,
          coinName: identifier,
          isFailover: true,
          isDown: false,
          trusted: true,
          torEnabled: true,
          clearnetEnabled: true,
          isPrimary: isPrimary,
        );
      case CryptoCurrencyNetwork.test:
        return NodeModel(
          host: "http://127.0.0.1",
          port: 29081,
          name: DefaultNodes.defaultName,
          id: DefaultNodes.buildId(this),
          useSSL: false,
          enabled: true,
          coinName: identifier,
          isFailover: true,
          isDown: false,
          trusted: true,
          torEnabled: true,
          clearnetEnabled: true,
          isPrimary: isPrimary,
        );

      default:
        throw UnimplementedError();
    }
  }

  @override
  int get defaultSeedPhraseLength => 25;

  @override
  int get fractionDigits => 8;

  @override
  bool get hasBuySupport => false;

  @override
  bool get hasMnemonicPassphraseSupport => false;

  @override
  List<int> get possibleMnemonicLengths => [defaultSeedPhraseLength];

  @override
  BigInt get satsPerCoin => BigInt.from(100000000);

  @override
  int get targetBlockTimeSeconds => 120;

  @override
  DerivePathType get defaultDerivePathType => throw UnsupportedError(
    "$runtimeType does not use bitcoin style derivation paths",
  );

  @override
  Uri defaultBlockExplorer(String txid) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return Uri.parse("https://explorer.salvium.io/tx/$txid");
      default:
        throw Exception(
          "Unsupported network for defaultBlockExplorer(): $network",
        );
    }
  }
}
