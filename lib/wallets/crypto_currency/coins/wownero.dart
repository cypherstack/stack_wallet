import 'package:cw_wownero/api/wallet.dart' as wownero_wallet;
import '../../../models/node_model.dart';
import '../../../utilities/default_nodes.dart';
import '../../../utilities/enums/derive_path_type_enum.dart';
import '../crypto_currency.dart';
import '../intermediate/cryptonote_currency.dart';

class Wownero extends CryptonoteCurrency {
  Wownero(super.network) {
    _idMain = "wownero";
    _uriScheme = "wownero";
    switch (network) {
      case CryptoCurrencyNetwork.main:
        _id = _idMain;
        _name = "Wownero";
        _ticker = "WOW";
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
  int get minConfirms => 15;

  @override
  bool validateAddress(String address) {
    return wownero_wallet.addressValid(address);
  }

  @override
  NodeModel get defaultNode {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return NodeModel(
          host: "https://wownero.stackwallet.com",
          port: 34568,
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
  int get defaultSeedPhraseLength => 14;

  @override
  int get fractionDigits => 11;

  @override
  bool get hasBuySupport => false;

  @override
  bool get hasMnemonicPassphraseSupport => false;

  @override
  List<int> get possibleMnemonicLengths => [defaultSeedPhraseLength, 25];

  @override
  BigInt get satsPerCoin => BigInt.from(100000000000);

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
        return Uri.parse("https://explore.wownero.com/search?value=$txid");
      default:
        throw Exception(
          "Unsupported network for defaultBlockExplorer(): $network",
        );
    }
  }
}
