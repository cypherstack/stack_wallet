import 'package:isar/isar.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';

@Collection()
class Output {
  Id id = Isar.autoIncrement;

  late String? scriptPubKey;

  late String? scriptPubKeyAsm;

  late String? scriptPubKeyType;

  late String scriptPubKeyAddress;

  late int value;

  @Backlink(to: 'outputs')
  final transaction = IsarLink<Transaction>();
}
