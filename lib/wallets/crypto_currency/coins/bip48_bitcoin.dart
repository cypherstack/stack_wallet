import '../../../utilities/enums/derive_path_type_enum.dart';
import '../crypto_currency.dart';

class BIP48Bitcoin extends Bitcoin {
  BIP48Bitcoin(super.network) {
    _idMain = "bip48Bitcoin";
    _uriScheme = "bitcoin";
    switch (network) {
      case CryptoCurrencyNetwork.main:
        _id = _idMain;
        _name = "Bitcoin";
        _ticker = "BTC";
      case CryptoCurrencyNetwork.test:
        _id = "bip48BitcoinTestNet";
        _name = "tBitcoin";
        _ticker = "tBTC";
      case CryptoCurrencyNetwork.test4:
        _id = "bip48BitcoinTestNet4";
        _name = "t4Bitcoin";
        _ticker = "t4BTC";
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
  List<DerivePathType> get supportedDerivationPathTypes => [
        ...super.supportedDerivationPathTypes,
        DerivePathType.bip48p2shp2wsh,
        DerivePathType.bip48p2wsh,
      ];

  @override
  String constructDerivePath({
    required DerivePathType derivePathType,
    int account = 0,
    required int chain,
    required int index,
  }) {
    if (derivePathType == DerivePathType.bip48p2shp2wsh ||
        derivePathType == DerivePathType.bip48p2wsh) {
      final coinType = networkParams.wifPrefix == 0x80 ? "0" : "1";
      return "m/48'/$coinType'/$account'/$chain/$index";
    }

    return super.constructDerivePath(
      derivePathType: derivePathType,
      account: account,
      chain: chain,
      index: index,
    );
  }
}
