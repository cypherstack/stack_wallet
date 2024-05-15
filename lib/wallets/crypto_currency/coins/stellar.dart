import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/derive_path_type_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/bip39_currency.dart';

class Stellar extends Bip39Currency {
  Stellar(super.network) {
    _idMain = "stellar";
    _uriScheme = "stellar";
    switch (network) {
      case CryptoCurrencyNetwork.main:
        _id = _idMain;
        _name = "Stellar";
        _ticker = "XLM";
      case CryptoCurrencyNetwork.test:
        _id = "stellarTestnet";
        _name = "tStellar";
        _ticker = "tXLM";
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
  String get genesisHash => throw UnimplementedError(
        "Not used for stellar",
      );

  @override
  NodeModel get defaultNode {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return NodeModel(
          host: "https://horizon.stellar.org",
          port: 443,
          name: DefaultNodes.defaultName,
          id: DefaultNodes.buildId(this),
          useSSL: false,
          enabled: true,
          coinName: identifier,
          isFailover: true,
          isDown: false,
        );

      case CryptoCurrencyNetwork.test:
        return NodeModel(
          host: "https://horizon-testnet.stellar.org/",
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
        throw Exception("Unsupported network");
    }
  }

  @override
  bool validateAddress(String address) =>
      RegExp(r"^[G][A-Z0-9]{55}$").hasMatch(address);

  @override
  int get defaultSeedPhraseLength => 24;

  @override
  int get fractionDigits => 7;

  @override
  bool get hasBuySupport => false;

  @override
  bool get hasMnemonicPassphraseSupport => true;

  @override
  List<int> get possibleMnemonicLengths => [defaultSeedPhraseLength, 12];

  @override
  AddressType get primaryAddressType => AddressType.stellar;

  @override
  BigInt get satsPerCoin => BigInt.from(
        10000000,
      ); // https://developers.stellar.org/docs/fundamentals-and-concepts/stellar-data-structures/assets#amount-precision

  @override
  int get targetBlockTimeSeconds => 5;

  @override
  DerivePathType get primaryDerivePathType => throw UnsupportedError(
    "$runtimeType does not use bitcoin style derivation paths",);

  @override
  Uri defaultBlockExplorer(String txid) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return Uri.parse("https://stellarchain.io/tx/$txid");
      case CryptoCurrencyNetwork.test:
        return Uri.parse("https://testnet.stellarchain.io/transactions/$txid");
      default:
        throw Exception(
          "Unsupported network for defaultBlockExplorer(): $network",
        );
    }
  }
}
