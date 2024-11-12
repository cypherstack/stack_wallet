import 'package:flutter_libmwc/lib.dart' as mimblewimblecoin;

import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/node_model.dart';
import '../../../utilities/default_nodes.dart';
import '../../../utilities/enums/derive_path_type_enum.dart';
import '../crypto_currency.dart';
import '../intermediate/bip39_currency.dart';

class Mimblewimblecoin extends Bip39Currency {
  Mimblewimblecoin(super.network) {
    _idMain = "mimblewimblecoin";
    _uriScheme = "mimblewimblecoin"; // ?
    switch (network) {
      case CryptoCurrencyNetwork.main:
        _id = _idMain;
        _name = "MimbleWimbleCoin";
        _ticker = "MWC";
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
  String get genesisHash {
    return "not used in mimblewimblecoin";
  }

  @override
  // change this to change the number of confirms a tx needs in order to show as confirmed
  int get minConfirms => 3;

 @override
bool validateAddress(String address) {
  Uri? uri = Uri.tryParse(address);
  if (uri != null &&
      (uri.scheme == "http" || uri.scheme == "https" || uri.scheme == "mwcmqs") &&
      uri.host.isNotEmpty &&
      !uri.host.endsWith(".onion")) {
    return true;
  }
  return mimblewimblecoin.Libmwc.validateSendAddress(address: address);
}


  @override
  NodeModel get defaultNode {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return NodeModel(
          host: "https://mwc713.mwc.mw",
          port: 443,
          name: DefaultNodes.defaultName,
          id: DefaultNodes.buildId(this),
          useSSL: true,
          enabled: true,
          coinName: identifier,
          isFailover: true,
          isDown: false
        );

      default:
        throw UnimplementedError();
    }
  }

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
  AddressType get defaultAddressType => AddressType.mimbleWimble;

  @override
  BigInt get satsPerCoin => BigInt.from(1000000000);

  @override
  int get targetBlockTimeSeconds => 60;

  @override
  DerivePathType get defaultDerivePathType => throw UnsupportedError(
        "$runtimeType does not use bitcoin style derivation paths",
      );

  @override
  Uri defaultBlockExplorer(String txid) {
    switch (network) {
      default:
        throw Exception(
          "Unsupported network for defaultBlockExplorer(): $network",
        );
    }
  }
}
