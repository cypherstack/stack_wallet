import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/amount.dart';

void main() {
  test("Basic Amount Constructor tests", () {
    Amount amount = Amount(rawValue: BigInt.two, fractionDigits: 0);
    expect(amount.fractionDigits, 0);
    expect(amount.raw, BigInt.two);
    expect(amount.decimal, Decimal.fromInt(2));

    amount = Amount(rawValue: BigInt.two, fractionDigits: 2);
    expect(amount.fractionDigits, 2);
    expect(amount.raw, BigInt.two);
    expect(amount.decimal, Decimal.parse("0.02"));

    amount = Amount(rawValue: BigInt.from(123456789), fractionDigits: 7);
    expect(amount.fractionDigits, 7);
    expect(amount.raw, BigInt.from(123456789));
    expect(amount.decimal, Decimal.parse("12.3456789"));

    bool didThrow = false;
    try {
      amount = Amount(rawValue: BigInt.one, fractionDigits: -1);
    } catch (_) {
      didThrow = true;
    }
    expect(didThrow, true);
  });

  test("Named fromDouble Amount Constructor tests", () {
    Amount amount = Amount.fromDouble(2.0, fractionDigits: 0);
    expect(amount.fractionDigits, 0);
    expect(amount.raw, BigInt.two);
    expect(amount.decimal, Decimal.fromInt(2));

    amount = Amount.fromDouble(2.0, fractionDigits: 2);
    expect(amount.fractionDigits, 2);
    expect(amount.raw, BigInt.from(200));
    expect(amount.decimal, Decimal.fromInt(2));

    amount = Amount.fromDouble(0.0123456789, fractionDigits: 7);
    expect(amount.fractionDigits, 7);
    expect(amount.raw, BigInt.from(123456));
    expect(amount.decimal, Decimal.parse("0.0123456"));

    bool didThrow = false;
    try {
      amount = Amount.fromDouble(2.0, fractionDigits: -1);
    } catch (_) {
      didThrow = true;
    }
    expect(didThrow, true);
  });

  test("Named fromDecimal Amount Constructor tests", () {
    Amount amount = Amount.fromDecimal(Decimal.fromInt(2), fractionDigits: 0);
    expect(amount.fractionDigits, 0);
    expect(amount.raw, BigInt.two);
    expect(amount.decimal, Decimal.fromInt(2));

    amount = Amount.fromDecimal(Decimal.fromInt(2), fractionDigits: 2);
    expect(amount.fractionDigits, 2);
    expect(amount.raw, BigInt.from(200));
    expect(amount.decimal, Decimal.fromInt(2));

    amount =
        Amount.fromDecimal(Decimal.parse("0.0123456789"), fractionDigits: 7);
    expect(amount.fractionDigits, 7);
    expect(amount.raw, BigInt.from(123456));
    expect(amount.decimal, Decimal.parse("0.0123456"));

    bool didThrow = false;
    try {
      amount = Amount.fromDecimal(Decimal.fromInt(2), fractionDigits: -1);
    } catch (_) {
      didThrow = true;
    }
    expect(didThrow, true);
  });
}
