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
