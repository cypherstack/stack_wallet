import 'package:nanodart/nanodart.dart';

import '../../../models/isar/models/isar_models.dart';
import '../../../models/node_model.dart';
import '../../../utilities/default_nodes.dart';
import '../../../utilities/enums/derive_path_type_enum.dart';
import '../crypto_currency.dart';
import '../intermediate/nano_currency.dart';

class Nano extends NanoCurrency {
  Nano(super.network) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        _id = "nano";
        _idMain = "nano";
        _name = "Nano";
        _uriScheme = "nano";
        _ticker = "XNO";
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
  int get fractionDigits => 30;

  @override
  BigInt get satsPerCoin => BigInt.parse(
        "1000000000000000000000000000000",
      ); // 1*10^30

  @override
  int get minConfirms => 1;

  @override
  AddressType get defaultAddressType => AddressType.nano;

  @override
  String get defaultRepresentative =>
      "nano_38713x95zyjsqzx6nm1dsom1jmm668owkeb9913ax6nfgj15az3nu8xkx579";

  @override
  int get nanoAccountType => NanoAccountType.NANO;

  @override
  NodeModel get defaultNode {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return NodeModel(
          // host: "https://rainstorm.city/api",
          host: "https://nodes.nanswap.com/XNO",
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
        throw UnimplementedError();
    }
  }

  @override
  DerivePathType get defaultDerivePathType => throw UnsupportedError(
        "$runtimeType does not use bitcoin style derivation paths",
      );

  @override
  Uri defaultBlockExplorer(String txid) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return Uri.parse("https://www.nanolooker.com/block/$txid");
      default:
        throw Exception(
          "Unsupported network for defaultBlockExplorer(): $network",
        );
    }
  }
}
