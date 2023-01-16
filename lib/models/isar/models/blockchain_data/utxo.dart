import 'dart:math';

import 'package:isar/isar.dart';

part 'utxo.g.dart';

@Collection(accessor: "utxos")
class UTXO {
  Id id = Isar.autoIncrement;

  @Index()
  late String walletId;

  @Index(unique: true, replace: true, composite: [CompositeIndex("walletId")])
  late String txid;

  late int vout;

  late int value;

  late String name;

  @Index()
  late bool isBlocked;

  late String? blockedReason;

  late bool isCoinbase;

  late String? blockHash;

  late int? blockHeight;

  late int? blockTime;

  int getConfirmations(int currentChainHeight) {
    if (blockTime == null || blockHash == null) return 0;
    if (blockHeight == null || blockHeight! <= 0) return 0;
    return max(0, currentChainHeight - (blockHeight! - 1));
  }

  bool isConfirmed(int currentChainHeight, int minimumConfirms) {
    final confirmations = getConfirmations(currentChainHeight);
    return confirmations >= minimumConfirms;
  }
}
