import 'package:monero/monero.dart' as monero;

import '../../../models/node_model.dart';
import '../../../utilities/default_nodes.dart';
import '../../../utilities/enums/derive_path_type_enum.dart';
import '../crypto_currency.dart';
import '../intermediate/cryptonote_currency.dart';

class Monero extends CryptonoteCurrency {
  Monero(super.network) {
    _idMain = "monero";
    _uriScheme = "monero";
    switch (network) {
      case CryptoCurrencyNetwork.main:
        _id = _idMain;
        _name = "Monero";
        _ticker = "XMR";
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
  bool validateAddress(String address) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return monero.Wallet_addressValid(address, 0);
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  NodeModel get defaultNode {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return NodeModel(
          host: "https://monero.stackwallet.com",
          port: 18081,
          name: DefaultNodes.defaultName,
          id: DefaultNodes.buildId(this),
          useSSL: true,
          enabled: true,
          coinName: identifier,
          isFailover: true,
          isDown: false,
          trusted: true,
        );

      default:
        throw UnimplementedError();
    }
  }

  @override
  int get defaultSeedPhraseLength => 25;

  @override
  int get fractionDigits => 12;

  @override
  bool get hasBuySupport => false;

  @override
  bool get hasMnemonicPassphraseSupport => false;

  @override
  List<int> get possibleMnemonicLengths => [defaultSeedPhraseLength];

  @override
  BigInt get satsPerCoin => BigInt.from(1000000000000);

  @override
  int get targetBlockTimeSeconds => 120;

  @override
  DerivePathType get primaryDerivePathType => throw UnsupportedError(
        "$runtimeType does not use bitcoin style derivation paths",
      );

  @override
  Uri defaultBlockExplorer(String txid) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return Uri.parse("https://xmrchain.net/tx/$txid");
      default:
        throw Exception(
          "Unsupported network for defaultBlockExplorer(): $network",
        );
    }
  }
}
