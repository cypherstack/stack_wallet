import 'package:isar/isar.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/input.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/output.dart';
import 'package:stackwallet/models/isar/models/transaction_note.dart';

@Collection()
class Transaction {
  Id id = Isar.autoIncrement;

  late String txid;

  late bool confirmed;

  late int confirmations;

  late int timestamp;

  late TransactionType txType;

  late String subType;

  late int amount;

  // TODO: do we need this?
  // late List<dynamic> aliens;

  late String worthAtBlockTimestamp;

  late int fee;

  late String address;

  late int height;

  late bool cancelled;

  late String? slateId;

  late String? otherData;

  final inputs = IsarLinks<Input>();

  final outputs = IsarLinks<Output>();

  final note = IsarLink<TransactionNote>();
}

// Used in Isar db and stored there as int indexes so adding/removing values
// in this definition should be done extremely carefully in production
enum TransactionType with IsarEnum<int> {
  // TODO: add more types before prod release?
  outgoing,
  incoming,
  sendToSelf, // should we keep this?
  anonymize; // firo specific

  @override
  int get value => index;
}
