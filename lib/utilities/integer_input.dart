final _decimalIntegerPattern = RegExp(r'^-?[0-9]+$');

int? tryParseIntegerInput(String text, {int? minimum, int? maximum}) {
  assert(minimum == null || maximum == null || minimum <= maximum);

  final normalized = text.trim();
  if (!_decimalIntegerPattern.hasMatch(normalized)) {
    return null;
  }

  final value = int.tryParse(normalized, radix: 10);
  if (value == null ||
      (minimum != null && value < minimum) ||
      (maximum != null && value > maximum)) {
    return null;
  }

  return value;
}

({bool isValid, int? value}) parseOptionalIntegerInput(
  String text, {
  int? minimum,
  int? maximum,
}) {
  if (text.isEmpty) {
    return (isValid: true, value: null);
  }

  final value = tryParseIntegerInput(text, minimum: minimum, maximum: maximum);
  return (isValid: value != null, value: value);
}
