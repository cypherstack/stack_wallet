import 'package:isar/isar.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';

part 'transaction_note.g.dart';

@Collection()
class TransactionNote {
  Id id = Isar.autoIncrement;

  late String value;

  final transaction = IsarLink<Transaction>();
}
