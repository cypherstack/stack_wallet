import 'package:isar/isar.dart';

part 'transaction_note.g.dart';

@Collection()
class TransactionNote {
  TransactionNote({
    required this.walletId,
    required this.txid,
    required this.value,
  });

  Id id = Isar.autoIncrement;

  @Index()
  late String walletId;

  @Index(unique: true, composite: [CompositeIndex("walletId")])
  late String txid;

  late String value;
}
