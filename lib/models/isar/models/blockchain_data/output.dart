import 'package:isar/isar.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';

part 'output.g.dart';

@Collection()
class Output {
  Id id = Isar.autoIncrement;

  @Index()
  late String walletId;

  late String? scriptPubKey;

  late String? scriptPubKeyAsm;

  late String? scriptPubKeyType;

  late String scriptPubKeyAddress;

  late int value;

  @Backlink(to: 'outputs')
  final transaction = IsarLink<Transaction>();
}
