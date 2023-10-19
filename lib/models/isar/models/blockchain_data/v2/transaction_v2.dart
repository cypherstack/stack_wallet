import 'dart:math';

import 'package:isar/isar.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/input_v2.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/output_v2.dart';

part 'transaction_v2.g.dart';

@Collection()
class TransactionV2 {
  final Id id = Isar.autoIncrement;

  @Index()
  final String walletId;

  @Index(unique: true, composite: [CompositeIndex("walletId")])
  final String txid;

  final String hash;

  @Index()
  late final int timestamp;

  final int? height;
  final String? blockHash;
  final int version;

  final List<InputV2> inputs;
  final List<OutputV2> outputs;

  TransactionV2({
    required this.walletId,
    required this.blockHash,
    required this.hash,
    required this.txid,
    required this.timestamp,
    required this.height,
    required this.inputs,
    required this.outputs,
    required this.version,
  });

  int getConfirmations(int currentChainHeight) {
    if (height == null || height! <= 0) return 0;
    return max(0, currentChainHeight - (height! - 1));
  }

  bool isConfirmed(int currentChainHeight, int minimumConfirms) {
    final confirmations = getConfirmations(currentChainHeight);
    return confirmations >= minimumConfirms;
  }

  @override
  String toString() {
    return 'TransactionV2(\n'
        '  walletId: $walletId,\n'
        '  hash: $hash,\n'
        '  txid: $txid,\n'
        '  timestamp: $timestamp,\n'
        '  height: $height,\n'
        '  blockHash: $blockHash,\n'
        '  version: $version,\n'
        '  inputs: $inputs,\n'
        '  outputs: $outputs,\n'
        ')';
  }
}
