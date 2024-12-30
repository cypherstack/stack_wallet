import '../../../utilities/enums/derive_path_type_enum.dart';
import 'bitcoin.dart';

class BIP48Bitcoin extends Bitcoin {
  BIP48Bitcoin(super.network);

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
