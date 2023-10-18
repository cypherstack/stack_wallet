import 'package:decimal/decimal.dart';

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

class InputV2 {
  final String scriptSigHex;
  final int sequence;
  final String txid;
  final int vout;

  InputV2({
    required this.scriptSigHex,
    required this.sequence,
    required this.txid,
    required this.vout,
  });

  static InputV2 fromElectrumXJson(Map<String, dynamic> json) {
    try {
      return InputV2(
          scriptSigHex: json["scriptSig"]["hex"] as String,
          sequence: json["sequence"] as int,
          txid: json["txid"] as String,
          vout: json["vout"] as int);
    } catch (e) {
      throw Exception("Failed to parse InputV2 from $json");
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is InputV2 &&
        other.scriptSigHex == scriptSigHex &&
        other.sequence == sequence &&
        other.txid == txid &&
        other.vout == vout;
  }

  @override
  int get hashCode => Object.hash(
        scriptSigHex,
        sequence,
        txid,
        vout,
      );

  @override
  String toString() {
    return 'InputV2(\n'
        '  scriptSigHex: $scriptSigHex,\n'
        '  sequence: $sequence,\n'
        '  txid: $txid,\n'
        '  vout: $vout,\n'
        ')';
  }
}

class OutputV2 {
  final String scriptPubKeyHex;
  final String valueStringSats;

  BigInt get value => BigInt.parse(valueStringSats);

  OutputV2({
    required this.scriptPubKeyHex,
    required this.valueStringSats,
  });

  // TODO: move this to a subclass based on coin since we don't know if the value will be sats or a decimal amount
  // For now assume 8 decimal places
  @Deprecated("See TODO and comments")
  static OutputV2 fromElectrumXJson(Map<String, dynamic> json) {
    try {
      final temp = Decimal.parse(json["value"].toString());
      if (temp < Decimal.zero) {
        throw Exception("Negative value found");
      }

      final String valueStringSats;
      if (temp.isInteger) {
        valueStringSats = temp.toString();
      } else {
        valueStringSats = temp.shift(8).toBigInt().toString();
      }

      return OutputV2(
        scriptPubKeyHex: json["scriptPubKey"]["hex"] as String,
        valueStringSats: valueStringSats,
      );
    } catch (e) {
      throw Exception("Failed to parse OutputV2 from $json");
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OutputV2 &&
        other.scriptPubKeyHex == scriptPubKeyHex &&
        other.valueStringSats == valueStringSats;
  }

  @override
  int get hashCode => Object.hash(
        scriptPubKeyHex,
        valueStringSats,
      );

  @override
  String toString() {
    return 'OutputV2(\n'
        '  scriptPubKeyHex: $scriptPubKeyHex,\n'
        '  value: $value,\n'
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
