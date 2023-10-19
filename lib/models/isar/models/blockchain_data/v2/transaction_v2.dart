import 'package:stackwallet/models/isar/models/blockchain_data/v2/input_v2.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/output_v2.dart';

class TransactionV2 {
  final String hash;
  final String txid;

  final int size;
  final int lockTime;

  final DateTime? blockTime;
  final String? blockHash;

  final List<InputV2> inputs;
  final List<OutputV2> outputs;

  TransactionV2({
    required this.blockHash,
    required this.hash,
    required this.txid,
    required this.lockTime,
    required this.size,
    required this.blockTime,
    required this.inputs,
    required this.outputs,
  });

  static TransactionV2 fromElectrumXJson(Map<String, dynamic> json) {
    try {
      final inputs = (json["vin"] as List).map(
        (e) => InputV2.fromElectrumXJson(
          Map<String, dynamic>.from(e as Map),
        ),
      );
      final outputs = (json["vout"] as List).map(
        (e) => OutputV2.fromElectrumXJson(
          Map<String, dynamic>.from(e as Map),
        ),
      );

      final blockTimeUnix = json["blocktime"] as int?;
      DateTime? blockTime;
      if (blockTimeUnix != null) {
        blockTime = DateTime.fromMillisecondsSinceEpoch(
          blockTimeUnix * 1000,
          isUtc: true,
        );
      }

      return TransactionV2(
        blockHash: json["blockhash"] as String?,
        hash: json["hash"] as String,
        txid: json["txid"] as String,
        lockTime: json["locktime"] as int,
        size: json["size"] as int,
        blockTime: blockTime,
        inputs: List.unmodifiable(inputs),
        outputs: List.unmodifiable(outputs),
      );
    } catch (e) {
      throw Exception(
        "Failed to parse TransactionV2 for txid=${json["txid"]}: $e",
      );
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TransactionV2 &&
        other.hash == hash &&
        other.txid == txid &&
        other.size == size &&
        other.lockTime == lockTime &&
        other.blockTime == blockTime &&
        other.blockHash == blockHash &&
        _listEquals(other.inputs, inputs) &&
        _listEquals(other.outputs, outputs);
  }

  @override
  int get hashCode => Object.hash(
        hash,
        txid,
        size,
        lockTime,
        blockTime,
        blockHash,
        inputs,
        outputs,
      );

  @override
  String toString() {
    return 'TransactionV2(\n'
        '  hash: $hash,\n'
        '  txid: $txid,\n'
        '  size: $size,\n'
        '  lockTime: $lockTime,\n'
        '  blockTime: $blockTime,\n'
        '  blockHash: $blockHash,\n'
        '  inputs: $inputs,\n'
        '  outputs: $outputs,\n'
        ')';
  }
}

bool _listEquals<T, U>(List<T> a, List<U> b) {
  if (T != U) {
    return false;
  }

  if (a.length != b.length) {
    return false;
  }

  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }

  return true;
}
