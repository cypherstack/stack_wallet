import 'package:isar/isar.dart';
import 'package:stackwallet/wallets/isar/isar_id_interface.dart';

part 'frost_wallet_info.g.dart';

@Collection(accessor: "frostWalletInfo", inheritance: false)
class FrostWalletInfo implements IsarId {
  @override
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: false)
  final String walletId;

  final List<String> knownSalts;

  FrostWalletInfo({
    required this.walletId,
    required this.knownSalts,
  });

  FrostWalletInfo copyWith({
    List<String>? knownSalts,
  }) {
    return FrostWalletInfo(
      walletId: walletId,
      knownSalts: knownSalts ?? this.knownSalts,
    );
  }

  Future<void> updateKnownSalts(
    List<String> knownSalts, {
    required Isar isar,
  }) async {
    // await isar.writeTxn(() async {
    //   await isar.
    // })
  }
}
