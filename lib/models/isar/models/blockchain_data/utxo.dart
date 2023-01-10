import 'dart:math';

import 'package:isar/isar.dart';

part 'utxo.g.dart';

@Collection()
class UTXO {
  Id id = Isar.autoIncrement;

  late String txid;

  late int vout;

  late Status status;

  late int value;

  late String txName;

  late bool blocked;

  late String? blockedReason;

  late bool isCoinbase;
}

@Embedded()
class Status {
  late String blockHash;

  late int blockHeight;

  late int blockTime;

  int getConfirmations(int currentChainHeight) {
    return max(0, currentChainHeight - blockHeight);
  }

  bool isConfirmed(int currentChainHeight, int minimumConfirms) {
    final confirmations = getConfirmations(currentChainHeight);
    return confirmations >= minimumConfirms;
  }
}
