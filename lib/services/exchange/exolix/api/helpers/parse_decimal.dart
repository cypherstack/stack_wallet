import 'package:decimal/decimal.dart';

Decimal parseDecimal(dynamic value) {
  if (value is Decimal) return value;
  if (value is int) return Decimal.fromInt(value);
  if (value is double) {
    final parsed = Decimal.tryParse(value.toString());
    if (parsed != null) return parsed;
    throw FormatException(
      "Could not convert double to Decimal",
      value.toString(),
    );
  }
  if (value is String) {
    final parsed = Decimal.tryParse(value);
    if (parsed != null) return parsed;
    throw FormatException(
      "Expected a numeric Decimal value but got unparseable string",
      value,
    );
  }
  throw FormatException(
    "Expected a Decimal-compatible value (num or numeric String) but got"
        " ${value.runtimeType}",
    "$value",
  );
}
