import '../../wallets/wallet/wallet_mixin_interfaces/extended_keys_interface.dart';
import 'key_data_interface.dart';

class XPrivData with KeyDataInterface {
  XPrivData({
    required this.walletId,
    required this.fingerprint,
    required List<XPriv> xprivs,
  }) : xprivs = List.unmodifiable(xprivs);

  @override
  final String walletId;

  final String fingerprint;

  final List<XPriv> xprivs;
}
