import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/format.dart';

void main() {
  group("satoshisToAmount", () {
    test("12345", () {
      expect(Format.satoshisToAmount(12345, coin: Coin.bitcoin),
          Decimal.parse("0.00012345"));
    });

    test("100012345", () {
      expect(Format.satoshisToAmount(100012345, coin: Coin.bitcoin),
          Decimal.parse("1.00012345"));
    });

    test("0", () {
      expect(Format.satoshisToAmount(0, coin: Coin.bitcoin), Decimal.zero);
    });

    test("1000000000", () {
      expect(Format.satoshisToAmount(1000000000, coin: Coin.bitcoin),
          Decimal.parse("10"));
    });
  });

  group("satoshiAmountToPrettyString", () {
    const locale = "en_US";
    test("12345", () {
      expect(Format.satoshiAmountToPrettyString(12345, locale, Coin.bitcoin),
          "0.00012345");
    });

    test("100012345", () {
      expect(
          Format.satoshiAmountToPrettyString(100012345, locale, Coin.bitcoin),
          "1.00012345");
    });

    test("123450000", () {
      expect(
          Format.satoshiAmountToPrettyString(123450000, locale, Coin.bitcoin),
          "1.23450000");
    });

    test("1230045000", () {
      expect(
          Format.satoshiAmountToPrettyString(1230045000, locale, Coin.bitcoin),
          "12.30045000");
    });

    test("1000000000", () {
      expect(
          Format.satoshiAmountToPrettyString(1000000000, locale, Coin.bitcoin),
          "10.00000000");
    });

    test("0", () {
      expect(Format.satoshiAmountToPrettyString(0, locale, Coin.bitcoin),
          "0.00000000");
    });
  });

  group("extractDateFrom", () {
    test("1614578400", () {
      expect(Format.extractDateFrom(1614578400, localized: false),
          "1 Mar 2021, 6:00");
    });

    test("1641589563", () {
      expect(Format.extractDateFrom(1641589563, localized: false),
          "7 Jan 2022, 21:06");
    });
  });

  group("formatDate", () {
    test("formatDate", () {
      final date = DateTime(2020);
      expect(Format.formatDate(date), "01/01/20");
    });
    test("formatDate", () {
      final date = DateTime(2021, 2, 6, 23, 58);
      expect(Format.formatDate(date), "02/06/21");
    });
    test("formatDate", () {
      final date = DateTime(2021, 13);
      expect(Format.formatDate(date), "01/01/22");
    });
    test("formatDate", () {
      final date = DateTime(2021, 2, 35);
      expect(Format.formatDate(date), "03/07/21");
    });
  });
}
