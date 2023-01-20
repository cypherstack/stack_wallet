import 'dart:math';

import 'package:isar/isar.dart';

part 'utxo.g.dart';

@Collection(accessor: "utxos")
class UTXO {
  UTXO({
    required this.walletId,
    required this.txid,
    required this.vout,
    required this.value,
    required this.name,
    required this.isBlocked,
    required this.blockedReason,
    required this.isCoinbase,
    required this.blockHash,
    required this.blockHeight,
    required this.blockTime,
    this.otherData,
  });

  Id id = Isar.autoIncrement;

  @Index()
  late final String walletId;

  @Index(unique: true, replace: true, composite: [CompositeIndex("walletId")])
  late final String txid;

  late final int vout;

  late final int value;

  late final String name;

  @Index()
  late final bool isBlocked;

  late final String? blockedReason;

  late final bool isCoinbase;

  late final String? blockHash;

  late final int? blockHeight;

  late final int? blockTime;

  late final String? otherData;

  int getConfirmations(int currentChainHeight) {
    if (blockTime == null || blockHash == null) return 0;
    if (blockHeight == null || blockHeight! <= 0) return 0;
    return max(0, currentChainHeight - (blockHeight! - 1));
  }

  bool isConfirmed(int currentChainHeight, int minimumConfirms) {
    final confirmations = getConfirmations(currentChainHeight);
    return confirmations >= minimumConfirms;
  }

  @override
  String toString() => "{ "
      "id: $id, "
      "walletId: $walletId, "
      "txid: $txid, "
      "vout: $vout, "
      "value: $value, "
      "name: $name, "
      "isBlocked: $isBlocked, "
      "blockedReason: $blockedReason, "
      "isCoinbase: $isCoinbase, "
      "blockHash: $blockHash, "
      "blockHeight: $blockHeight, "
      "blockTime: $blockTime, "
      "}";
}
