import 'package:ethereum_addresses/ethereum_addresses.dart';

import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/node_model.dart';
import '../../../utilities/default_nodes.dart';
import '../../../utilities/enums/derive_path_type_enum.dart';
import '../../../utilities/eth_commons.dart';
import '../crypto_currency.dart';
import '../intermediate/bip39_currency.dart';

class Ethereum extends Bip39Currency {
  Ethereum(super.network) {
    _idMain = "ethereum";
    _uriScheme = "ethereum";
    switch (network) {
      case CryptoCurrencyNetwork.main:
        _id = _idMain;
        _name = "Ethereum";
        _ticker = "ETH";
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

  int get gasLimit => kEthereumMinGasLimit;

  @override
  bool get hasTokenSupport => true;

  @override
  NodeModel get defaultNode => NodeModel(
    host: "https://eth2.stackwallet.com",
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
  );

  @override
  // Not used for eth
  String get genesisHash => throw UnimplementedError("Not used for eth");

  @override
  int get minConfirms => 3;

  @override
  bool validateAddress(String address) {
    return isValidEthereumAddress(address);
  }

  @override
  int get defaultSeedPhraseLength => 12;

  @override
  int get fractionDigits => 18;

  @override
  bool get hasBuySupport => true;

  @override
  bool get hasMnemonicPassphraseSupport => true;

  @override
  List<int> get possibleMnemonicLengths => [defaultSeedPhraseLength, 24];

  @override
  AddressType get defaultAddressType => defaultDerivePathType.getAddressType();

  @override
  BigInt get satsPerCoin => BigInt.from(1000000000000000000);

  @override
  int get targetBlockTimeSeconds => 15;

  @override
  DerivePathType get defaultDerivePathType => DerivePathType.eth;

  @override
  Uri defaultBlockExplorer(String txid) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return Uri.parse("https://etherscan.io/tx/$txid");
      default:
        throw Exception(
          "Unsupported network for defaultBlockExplorer(): $network",
        );
    }
  }
}
