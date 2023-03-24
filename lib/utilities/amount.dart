import 'package:decimal/decimal.dart';

final _ten = BigInt.from(10);

class Amount {
  Amount({
    required BigInt rawValue,
    required this.fractionDigits,
  })  : assert(fractionDigits >= 0),
        _value = rawValue;

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
}
