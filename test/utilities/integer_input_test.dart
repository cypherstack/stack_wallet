import "package:flutter_test/flutter_test.dart";
import "package:stackwallet/utilities/integer_input.dart";

void main() {
  test("integer input rejects malformed text without normalizing it", () {
    for (final value in ["1.5", "1,5", "1e3", "1 000", "0x5208", "+21000"]) {
      expect(tryParseIntegerInput(value), isNull, reason: value);
    }

    expect(tryParseIntegerInput(" 1 "), 1);
  });

  test("integer input preserves signed decimal support", () {
    expect(tryParseIntegerInput("-42"), -42);
    expect(tryParseIntegerInput(" -42 "), -42);
    expect(tryParseIntegerInput("-42", minimum: 0), isNull);
  });

  test("integer input enforces inclusive bounds", () {
    expect(tryParseIntegerInput("0", minimum: 0), 0);
    expect(tryParseIntegerInput("-1", minimum: 0), isNull);
    expect(
      tryParseIntegerInput("21000", minimum: 21000, maximum: 30000000),
      21000,
    );
    expect(
      tryParseIntegerInput("30000000", minimum: 21000, maximum: 30000000),
      30000000,
    );
    expect(
      tryParseIntegerInput("30000001", minimum: 21000, maximum: 30000000),
      isNull,
    );
  });

  test("optional integer input distinguishes blank from malformed", () {
    expect(parseOptionalIntegerInput("", minimum: 0), (
      isValid: true,
      value: null,
    ));
    expect(parseOptionalIntegerInput("0", minimum: 0), (
      isValid: true,
      value: 0,
    ));
    expect(parseOptionalIntegerInput("1.5", minimum: 0), (
      isValid: false,
      value: null,
    ));
    expect(parseOptionalIntegerInput("-1", minimum: 0), (
      isValid: false,
      value: null,
    ));
  });
}
