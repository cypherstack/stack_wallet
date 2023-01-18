import 'package:isar/isar.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';

part 'output.g.dart';

@Collection()
class Output {
  Output({
    required this.walletId,
    required this.scriptPubKey,
    required this.scriptPubKeyAsm,
    required this.scriptPubKeyType,
    required this.scriptPubKeyAddress,
    required this.value,
  });

  Id id = Isar.autoIncrement;

  @Index()
  late final String walletId;

  late final String? scriptPubKey;

  late final String? scriptPubKeyAsm;

  late final String? scriptPubKeyType;

  late final String scriptPubKeyAddress;

  late final int value;

  @Backlink(to: 'outputs')
  final transaction = IsarLink<Transaction>();
}
