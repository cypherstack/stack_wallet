import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/node_model.dart';
import '../../../utilities/default_nodes.dart';
import '../../../utilities/enums/derive_path_type_enum.dart';
import '../crypto_currency.dart';
import '../intermediate/bip39_currency.dart';

class Cardano extends Bip39Currency {
  Cardano(super.network) {
    _idMain = "cardano";
    _uriScheme = "cardano";
    switch (network) {
      case CryptoCurrencyNetwork.main:
        _id = _idMain;
        _name = "Cardano";
        _ticker = "ADA";
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
  AddressType get defaultAddressType => AddressType.cardanoShelley;

  @override
  Uri defaultBlockExplorer(String txid) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return Uri.parse(
          "https://explorer.cardano.org/en/transaction?id=$txid",
        );
      default:
        throw Exception(
          "Unsupported network for defaultBlockExplorer(): $network",
        );
    }
  }

  @override
  DerivePathType get defaultDerivePathType => DerivePathType.cardanoShelley;

  @override
  NodeModel defaultNode({required bool isPrimary}) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return NodeModel(
          host: "https://cardano.stackwallet.com",
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

      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  int get defaultSeedPhraseLength => 15;

  @override
  int get fractionDigits => 6;

  @override
  String get genesisHash =>
      "f0f7892b5c333cffc4b3c4344de48af4cc63f55e44936196f365a9ef2244134f";

  @override
  bool get hasBuySupport => false;

  @override
  bool get hasMnemonicPassphraseSupport => false;

  @override
  int get minConfirms => 2;

  @override
  List<int> get possibleMnemonicLengths => [defaultSeedPhraseLength];

  @override
  BigInt get satsPerCoin => BigInt.from(1000000);

  @override
  int get targetBlockTimeSeconds => 20;

  @override
  bool get torSupport => true;

  @override
  bool validateAddress(String address) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return RegExp(r"^addr1[0-9a-zA-Z]{98}$").hasMatch(address);
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  AddressType? getAddressType(String address) {
    if (validateAddress(address)) {
      return AddressType.cardanoShelley;
    }
    return null;
  }
}
