import 'package:solana/solana.dart';

import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/node_model.dart';
import '../../../utilities/default_nodes.dart';
import '../../../utilities/enums/derive_path_type_enum.dart';
import '../crypto_currency.dart';
import '../intermediate/bip39_currency.dart';

class Solana extends Bip39Currency {
  Solana(super.network) {
    _idMain = "solana";
    _uriScheme = "solana";
    switch (network) {
      case CryptoCurrencyNetwork.main:
        _id = _idMain;
        _name = "Solana";
        _ticker = "SOL";
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
  NodeModel get defaultNode {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return NodeModel(
          host: "https://solana.stackwallet.com",
          port: 443,
          name: DefaultNodes.defaultName,
          id: DefaultNodes.buildId(this),
          useSSL: true,
          enabled: true,
          coinName: identifier,
          isFailover: true,
          isDown: false,
        );
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  int get minConfirms => 21;

  @override
  bool get torSupport => true;

  @override
  bool validateAddress(String address) {
    try {
      return isPointOnEd25519Curve(
        Ed25519HDPublicKey.fromBase58(address).toByteArray(),
      );
    } catch (_) {
      return false;
    }
  }

  @override
  String get genesisHash => throw UnimplementedError();

  @override
  int get defaultSeedPhraseLength => 12;

  @override
  int get fractionDigits => 9;

  @override
  bool get hasBuySupport => false;

  @override
  bool get hasMnemonicPassphraseSupport => false;

  @override
  List<int> get possibleMnemonicLengths => [defaultSeedPhraseLength, 24];

  @override
  AddressType get defaultAddressType => defaultDerivePathType.getAddressType();

  @override
  BigInt get satsPerCoin => BigInt.from(1000000000);

  @override
  int get targetBlockTimeSeconds => 1;

  @override
  DerivePathType get defaultDerivePathType => DerivePathType.solana;

  @override
  Uri defaultBlockExplorer(String txid) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return Uri.parse("https://explorer.solana.com/tx/$txid");
      default:
        throw Exception(
          "Unsupported network for defaultBlockExplorer(): $network",
        );
    }
  }
}
