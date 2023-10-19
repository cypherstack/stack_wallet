import 'package:decimal/decimal.dart';

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
