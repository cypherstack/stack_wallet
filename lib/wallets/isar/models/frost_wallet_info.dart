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
  final List<String> participants;
  final String myName;
  final int threshold;

  FrostWalletInfo({
    required this.walletId,
    required this.knownSalts,
    required this.participants,
    required this.myName,
    required this.threshold,
  });

  FrostWalletInfo copyWith({
    List<String>? knownSalts,
    List<String>? participants,
    String? myName,
    int? threshold,
  }) {
    return FrostWalletInfo(
      walletId: walletId,
      knownSalts: knownSalts ?? this.knownSalts,
      participants: participants ?? this.participants,
      myName: myName ?? this.myName,
      threshold: threshold ?? this.threshold,
    )..id = id;
  }
}
