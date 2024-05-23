import 'package:isar/isar.dart';
import '../isar_id_interface.dart';

part 'wallet_info_meta.g.dart';

@Collection(accessor: "walletInfoMeta", inheritance: false)
class WalletInfoMeta implements IsarId {
  @override
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: false)
  final String walletId;

  /// Wallets without this flag set to true should be deleted on next app run
  /// and should not be displayed in the ui.
  final bool isMnemonicVerified;

  WalletInfoMeta({
    required this.walletId,
    required this.isMnemonicVerified,
  });
}
