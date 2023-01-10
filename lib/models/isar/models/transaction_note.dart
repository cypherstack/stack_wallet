import 'package:isar/isar.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';

@Collection()
class TransactionNote {
  Id id = Isar.autoIncrement;

  late String value;

  @Backlink(to: 'note')
  final transaction = IsarLink<Transaction>();
}
