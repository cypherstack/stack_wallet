import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

final _ten = BigInt.from(10);

class Amount implements Equatable {
  Amount({
    required BigInt rawValue,
    required this.fractionDigits,
  })  : assert(fractionDigits >= 0),
        _value = rawValue;

  /// special zero case with [fractionDigits] set to 0
  static Amount get zero => Amount(
        rawValue: BigInt.zero,
        fractionDigits: 0,
      );

  /// truncate double value to [fractionDigits] places
  Amount.fromDouble(double amount, {required this.fractionDigits})
      : assert(fractionDigits >= 0),
        _value =
            Decimal.parse(amount.toString()).shift(fractionDigits).toBigInt();

  /// truncate decimal value to [fractionDigits] places
  Amount.fromDecimal(Decimal amount, {required this.fractionDigits})
      : assert(fractionDigits >= 0),
        _value = amount.shift(fractionDigits).toBigInt();

  // ===========================================================================
  // ======= Instance properties ===============================================

  final int fractionDigits;
  final BigInt _value;

  // ===========================================================================
  // ======= Getters ===========================================================

  /// raw base value
  BigInt get raw => _value;

  /// actual decimal vale represented
  Decimal get decimal =>
      (Decimal.fromBigInt(_value) / _ten.pow(fractionDigits).toDecimal())
          .toDecimal(scaleOnInfinitePrecision: fractionDigits);

  /// convenience getter
  @Deprecated("provided for convenience only. Use fractionDigits instead.")
  int get decimals => fractionDigits;

  Map<String, dynamic> toMap() {
    // ===========================================================================
    // ======= Serialization =====================================================

    return {"raw": raw.toString(), "fractionDigits": fractionDigits};
  }

  String toJsonString() {
    return jsonEncode(toMap());
  }

  // ===========================================================================
  // ======= Deserialization ===================================================

  static Amount fromSerializedJsonString(String json) {
    final map = jsonDecode(json) as Map;
    return Amount(
      rawValue: BigInt.parse(map["raw"] as String),
      fractionDigits: map["fractionDigits"] as int,
    );
  }

  // ===========================================================================
  // ======= operators =========================================================

  bool operator >(Amount other) => raw > other.raw;

  bool operator <(Amount other) => raw < other.raw;

  bool operator >=(Amount other) => raw >= other.raw;

  bool operator <=(Amount other) => raw <= other.raw;

  // ===========================================================================
  // ======= Overrides =========================================================

  @override
  String toString() => "Amount($raw, $fractionDigits)";

  @override
  List<Object?> get props => [fractionDigits, _value];

  @override
  bool? get stringify => false;
}
