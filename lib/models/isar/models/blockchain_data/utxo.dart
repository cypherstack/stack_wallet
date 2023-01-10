import 'package:isar/isar.dart';

part 'utxo.g.dart';

@Collection()
class UTXO {
  Id id = Isar.autoIncrement;

  late String txid;

  late int vout;

  late Status status;

  late int value;

  late String fiatWorth;

  late String txName;

  late bool blocked;

  late bool isCoinbase;
}

@Embedded()
class Status {
  late bool confirmed;

  late int confirmations;

  late String blockHash;

  late int blockHeight;

  late int blockTime;
}
