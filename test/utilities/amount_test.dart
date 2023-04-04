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

  group("operators", () {
    final one = Amount(rawValue: BigInt.one, fractionDigits: 0);
    final two = Amount(rawValue: BigInt.two, fractionDigits: 0);
    final four4 = Amount(rawValue: BigInt.from(4), fractionDigits: 4);
    final four4_2 = Amount(rawValue: BigInt.from(4), fractionDigits: 4);
    final four5 = Amount(rawValue: BigInt.from(4), fractionDigits: 5);

    test(">", () {
      expect(one > two, false);
      expect(one > one, false);

      expect(two > two, false);
      expect(two > one, true);
    });

    test("<", () {
      expect(one < two, true);
      expect(one < one, false);

      expect(two < two, false);
      expect(two < one, false);
    });

    test(">=", () {
      expect(one >= two, false);
      expect(one >= one, true);

      expect(two >= two, true);
      expect(two >= one, true);
    });

    test("<=", () {
      expect(one <= two, true);
      expect(one <= one, true);

      expect(two <= two, true);
      expect(two <= one, false);
    });

    test("<=", () {
      expect(one <= two, true);
      expect(one <= one, true);

      expect(two <= two, true);
      expect(two <= one, false);
    });

    test("==", () {
      expect(one == two, false);
      expect(one == one, true);

      expect(BigInt.from(2) == BigInt.from(2), true);

      expect(four4 == four4_2, true);
      expect(four4 == four5, false);
    });

    test("+", () {
      expect(one + two, Amount(rawValue: BigInt.from(3), fractionDigits: 0));
      expect(one + one, Amount(rawValue: BigInt.from(2), fractionDigits: 0));

      expect(
          Amount(rawValue: BigInt.from(3), fractionDigits: 0) +
              Amount(rawValue: BigInt.from(-5), fractionDigits: 0),
          Amount(rawValue: BigInt.from(-2), fractionDigits: 0));
      expect(
          Amount(rawValue: BigInt.from(-3), fractionDigits: 0) +
              Amount(rawValue: BigInt.from(6), fractionDigits: 0),
          Amount(rawValue: BigInt.from(3), fractionDigits: 0));
    });

    test("-", () {
      expect(one - two, Amount(rawValue: BigInt.from(-1), fractionDigits: 0));
      expect(one - one, Amount(rawValue: BigInt.from(0), fractionDigits: 0));

      expect(
          Amount(rawValue: BigInt.from(3), fractionDigits: 0) -
              Amount(rawValue: BigInt.from(-5), fractionDigits: 0),
          Amount(rawValue: BigInt.from(8), fractionDigits: 0));
      expect(
          Amount(rawValue: BigInt.from(-3), fractionDigits: 0) -
              Amount(rawValue: BigInt.from(6), fractionDigits: 0),
          Amount(rawValue: BigInt.from(-9), fractionDigits: 0));
    });

    test("*", () {
      expect(one * two, Amount(rawValue: BigInt.from(2), fractionDigits: 0));
      expect(one * one, Amount(rawValue: BigInt.from(1), fractionDigits: 0));

      expect(
          Amount(rawValue: BigInt.from(3), fractionDigits: 0) *
              Amount(rawValue: BigInt.from(-5), fractionDigits: 0),
          Amount(rawValue: BigInt.from(-15), fractionDigits: 0));
      expect(
          Amount(rawValue: BigInt.from(-3), fractionDigits: 0) *
              Amount(rawValue: BigInt.from(-6), fractionDigits: 0),
          Amount(rawValue: BigInt.from(18), fractionDigits: 0));
    });
  });
}
