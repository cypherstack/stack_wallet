import 'package:decimal/decimal.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/amount/amount_formatter.dart';
import 'package:stackwallet/utilities/amount/amount_input_formatter.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

void main() {
  test("displayAmount BTC", () {
    final Amount amount = Amount(
      rawValue: BigInt.from(1012345678),
      fractionDigits: 8,
    );

    expect(
      AmountUnit.normal.displayAmount(
        amount: amount,
        locale: "en_US",
        coin: Bitcoin(CryptoCurrencyNetwork.main),
        maxDecimalPlaces: 8,
      ),
      "10.12345678 BTC",
    );

    expect(
      AmountUnit.milli.displayAmount(
        amount: amount,
        locale: "en_US",
        coin: Bitcoin(CryptoCurrencyNetwork.main),
        maxDecimalPlaces: 8,
      ),
      "10,123.45678 mBTC",
    );

    expect(
      AmountUnit.micro.displayAmount(
        amount: amount,
        locale: "en_US",
        coin: Bitcoin(CryptoCurrencyNetwork.main),
        maxDecimalPlaces: 8,
      ),
      "10,123,456.78 µBTC",
    );

    expect(
      AmountUnit.nano.displayAmount(
        amount: amount,
        locale: "en_US",
        coin: Bitcoin(CryptoCurrencyNetwork.main),
        maxDecimalPlaces: 8,
      ),
      "1,012,345,678 sats",
    );
    final dec = Decimal.parse("10.123456789123456789");

    expect(dec.toString(), "10.123456789123456789");
  });

  test("displayAmount ETH", () {
    final eth = Ethereum(CryptoCurrencyNetwork.main);

    final Amount amount = Amount.fromDecimal(
      Decimal.parse("10.123456789123456789"),
      fractionDigits: eth.fractionDigits,
    );

    expect(
      AmountUnit.normal.displayAmount(
        amount: amount,
        locale: "en_US",
        coin: eth,
        maxDecimalPlaces: 8,
      ),
      "~10.12345678 ETH",
    );

    expect(
      AmountUnit.normal.displayAmount(
        amount: amount,
        locale: "en_US",
        coin: eth,
        maxDecimalPlaces: 4,
      ),
      "~10.1234 ETH",
    );

    expect(
      AmountUnit.normal.displayAmount(
        amount: amount,
        locale: "en_US",
        coin: eth,
        maxDecimalPlaces: 18,
      ),
      "10.123456789123456789 ETH",
    );

    expect(
      AmountUnit.milli.displayAmount(
        amount: amount,
        locale: "en_US",
        coin: eth,
        maxDecimalPlaces: 9,
      ),
      "~10,123.456789123 mETH",
    );

    expect(
      AmountUnit.micro.displayAmount(
        amount: amount,
        locale: "en_US",
        coin: eth,
        maxDecimalPlaces: 8,
      ),
      "~10,123,456.78912345 µETH",
    );

    expect(
      AmountUnit.nano.displayAmount(
        amount: amount,
        locale: "en_US",
        coin: eth,
        maxDecimalPlaces: 1,
      ),
      "~10,123,456,789.1 gwei",
    );

    expect(
      AmountUnit.pico.displayAmount(
        amount: amount,
        locale: "en_US",
        coin: eth,
        maxDecimalPlaces: 18,
      ),
      "10,123,456,789,123.456789 mwei",
    );

    expect(
      AmountUnit.femto.displayAmount(
        amount: amount,
        locale: "en_US",
        coin: eth,
        maxDecimalPlaces: 4,
      ),
      "10,123,456,789,123,456.789 kwei",
    );

    expect(
      AmountUnit.atto.displayAmount(
        amount: amount,
        locale: "en_US",
        coin: eth,
        maxDecimalPlaces: 1,
      ),
      "10,123,456,789,123,456,789 wei",
    );
  });

  test("parse eth string to amount", () {
    final eth = Ethereum(CryptoCurrencyNetwork.main);
    final Amount amount = Amount.fromDecimal(
      Decimal.parse("10.123456789123456789"),
      fractionDigits: eth.fractionDigits,
    );

    expect(
      AmountUnit.nano.tryParse(
        "~10,123,456,789.1 gwei",
        locale: "en_US",
        coin: eth,
      ),
      Amount.fromDecimal(
        Decimal.parse("10.1234567891"),
        fractionDigits: eth.fractionDigits,
      ),
    );

    expect(
      AmountUnit.atto.tryParse(
        "10,123,456,789,123,456,789 wei",
        locale: "en_US",
        coin: eth,
      ),
      amount,
    );
  });

  test("parse btc string to amount", () {
    final Amount amount = Amount(
      rawValue: BigInt.from(1012345678),
      fractionDigits: 8,
    );

    expect(
      AmountUnit.normal.tryParse(
        "10.12345678 BTC",
        locale: "en_US",
        coin: Bitcoin(CryptoCurrencyNetwork.main),
      ),
      amount,
    );

    expect(
      AmountUnit.milli.tryParse(
        "10,123.45678 mBTC",
        locale: "en_US",
        coin: Bitcoin(CryptoCurrencyNetwork.main),
      ),
      amount,
    );

    expect(
      AmountUnit.micro.tryParse(
        "10,123,456.7822 µBTC",
        locale: "en_US",
        coin: Bitcoin(CryptoCurrencyNetwork.main),
      ),
      amount,
    );

    expect(
      AmountUnit.nano.tryParse(
        "1,012,345,678 sats",
        locale: "en_US",
        coin: Bitcoin(CryptoCurrencyNetwork.main),
      ),
      amount,
    );
  });

  test("amount field parsing rejects signs and ASCII whitespace", () {
    final coin = Bitcoin(CryptoCurrencyNetwork.main);
    final formatter = AmountFormatter(
      unit: AmountUnit.normal,
      locale: "en_US",
      coin: coin,
      maxDecimals: 8,
    );

    expect(formatter.tryParse("5")?.decimal, Decimal.fromInt(5));

    for (final value in [
      "+5",
      "-5",
      for (final codePoint in [0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x20])
        "1${String.fromCharCode(codePoint)}234",
    ]) {
      expect(formatter.tryParse(value), isNull, reason: value);
      expect(
        Amount.tryParseFiatString(value, locale: "en_US"),
        isNull,
        reason: value,
      );
    }

    expect(
      AmountUnit.normal
          .tryParse("5 legacy", locale: "en_US", coin: coin)
          ?.decimal,
      Decimal.fromInt(5),
    );
  });

  test("parse ASCII decimals in dot-group locales", () {
    final coin = Bitcoin(CryptoCurrencyNetwork.main);
    final formatter = AmountInputFormatter(decimals: 8, locale: "de_DE");
    expect(
      AmountUnit.normal.tryParse("1.5", locale: "de_DE", coin: coin)?.decimal,
      Decimal.parse("1.5"),
    );
    expect(
      AmountUnit.normal.tryParse("1.234", locale: "de_DE", coin: coin)?.decimal,
      Decimal.fromInt(1234),
    );
    expect(
      Amount.tryParseFiatString("1.50", locale: "de_DE")?.decimal,
      Decimal.parse("1.5"),
    );
    final formatted = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: "1.5",
        selection: TextSelection.collapsed(offset: 3),
      ),
    );
    expect(formatted.text, "1,5");

    final appended = formatter.formatEditUpdate(
      const TextEditingValue(
        text: "1.234",
        selection: TextSelection.collapsed(offset: 5),
      ),
      const TextEditingValue(
        text: "1.2345",
        selection: TextSelection.collapsed(offset: 6),
      ),
    );
    expect(appended.text, "12.345");

    final insertedDecimal = formatter.formatEditUpdate(
      const TextEditingValue(
        text: "1.234",
        selection: TextSelection.collapsed(offset: 1),
      ),
      const TextEditingValue(
        text: "1..234",
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    expect(insertedDecimal.text, "1,234");
    expect(insertedDecimal.selection.baseOffset, 2);
  });

  test("strict localized parsing validates grouping", () {
    expect(
      Amount.tryParseLocalizedNumber("1,000", locale: "en_US"),
      Decimal.fromInt(1000),
    );
    expect(
      Amount.tryParseLocalizedNumber("1.5", locale: "en_US"),
      Decimal.parse("1.5"),
    );
    expect(
      Amount.tryParseLocalizedNumber("1,5", locale: "de_DE"),
      Decimal.parse("1.5"),
    );
    expect(
      Amount.tryParseLocalizedNumber("1.5", locale: "de_DE"),
      Decimal.parse("1.5"),
    );

    for (final malformed in ["1,5", "12,34", "0,001", "1,,000"]) {
      expect(
        Amount.tryParseLocalizedNumber(malformed, locale: "en_US"),
        isNull,
        reason: malformed,
      );
    }
  });

  test("ambiguous dot-grouped values are rejected", () {
    // A single "." group with exactly three trailing digits reads as both a
    // grouped integer (1123) and a dot-decimal amount (1.123). Reject.
    for (final ambiguous in ["1.123", "1.000", "12.345", "999.999"]) {
      expect(
        Amount.tryParseLocalizedNumber(ambiguous, locale: "de_DE"),
        isNull,
        reason: ambiguous,
      );
    }

    // Values with only one possible reading still parse.
    expect(
      Amount.tryParseLocalizedNumber("1.12", locale: "de_DE"),
      Decimal.parse("1.12"),
    );
    expect(
      Amount.tryParseLocalizedNumber("1.1234", locale: "de_DE"),
      Decimal.parse("1.1234"),
    );
    expect(
      Amount.tryParseLocalizedNumber("0.123", locale: "de_DE"),
      Decimal.parse("0.123"),
    );
    expect(
      Amount.tryParseLocalizedNumber("1234.123", locale: "de_DE"),
      Decimal.parse("1234.123"),
    );
    expect(
      Amount.tryParseLocalizedNumber("1.000.000", locale: "de_DE"),
      Decimal.fromInt(1000000),
    );
    expect(
      Amount.tryParseLocalizedNumber("1.000,5", locale: "de_DE"),
      Decimal.parse("1000.5"),
    );

    // Locales with "." as the decimal separator are unaffected.
    expect(
      Amount.tryParseLocalizedNumber("1.123", locale: "en_US"),
      Decimal.parse("1.123"),
    );
    expect(
      Amount.tryParseLocalizedNumber("1,123", locale: "en_US"),
      Decimal.fromInt(1123),
    );
  });

  test("tryParseLocalizedNumber input class matrix", () {
    // (input, expected for en_US, expected for de_DE); null means rejected.
    final cases = <(String, String?, String?)>[
      // Plain integers.
      ("0", "0", "0"),
      ("5", "5", "5"),
      ("007", "7", "7"),
      (
        "1234567890123456789012345678901234567890",
        "1234567890123456789012345678901234567890",
        "1234567890123456789012345678901234567890",
      ),
      // Decimal-separator forms.
      ("1.5", "1.5", "1.5"),
      ("0.5", "0.5", "0.5"),
      (".5", "0.5", "0.5"),
      ("00.5", "0.5", "0.5"),
      ("1.12345678", "1.12345678", "1.12345678"),
      ("1,5", null, "1.5"),
      (",5", null, "0.5"),
      (",000", null, "0"),
      ("0,5", null, "0.5"),
      ("1,12345678", null, "1.12345678"),
      ("0.000000000000000001", "0.000000000000000001", "0.000000000000000001"),
      // Grouped values; note a 3-digit comma "decimal" is valid in de_DE.
      ("1,000", "1000", "1"),
      ("10,000", "10000", "10"),
      ("100,000", "100000", "100"),
      ("999,999", "999999", "999.999"),
      ("1,234,567", "1234567", null),
      ("1,000.5", "1000.5", null),
      ("1,000,000.12345678", "1000000.12345678", null),
      ("1.234.567", null, "1234567"),
      ("1.000,5", null, "1000.5"),
      ("1.000.000,12345678", null, "1000000.12345678"),
      // Malformed grouping (en_US); most re-read as decimals in de_DE.
      ("1,23", null, "1.23"),
      ("12,3456", null, "12.3456"),
      ("1234,567", null, "1234.567"),
      ("0,001", null, "0.001"),
      ("1,0000", null, "1"),
      ("1,,000", null, null),
      ("1,000,00", null, null),
      // Ambiguous single dot group in de_DE; plain decimals in en_US.
      ("1.123", "1.123", null),
      ("1.000", "1", null),
      ("12.345", "12.345", null),
      ("999.999", "999.999", null),
      // Unambiguous dot forms in de_DE.
      ("1.12", "1.12", "1.12"),
      ("1.1234", "1.1234", "1.1234"),
      ("0.123", "0.123", "0.123"),
      ("1000.123", "1000.123", "1000.123"),
      ("1234.123", "1234.123", "1234.123"),
      // Separator garbage.
      ("1.2.3", null, null),
      ("1..5", null, null),
      (".", null, null),
      ("..", null, null),
      (",", null, null),
      ("1.", null, null),
      ("5.", null, null),
      ("5,", null, null),
      ("1,000.", null, null),
      ("1.000.", null, null),
      (".5.5", null, null),
      // Signs and whitespace.
      ("", null, null),
      ("+5", null, null),
      ("-5", null, null),
      ("5-", null, null),
      ("1-2", null, null),
      (" 5", null, null),
      ("5 ", null, null),
      ("1 000", null, null),
      ("\t5", null, null),
      ("5\n", null, null),
      ("5\r", null, null),
      // Non-numeric and exotic digits.
      ("abc", null, null),
      ("1a", null, null),
      ("a1", null, null),
      ("1e5", null, null),
      ("1E5", null, null),
      ("0x10", null, null),
      ("NaN", null, null),
      ("Infinity", null, null),
      ("١٢٣", null, null),
      ("１２３", null, null),
    ];

    for (final (input, enExpected, deExpected) in cases) {
      expect(
        Amount.tryParseLocalizedNumber(input, locale: "en_US"),
        enExpected == null ? isNull : Decimal.parse(enExpected),
        reason: "en_US: '$input'",
      );
      expect(
        Amount.tryParseLocalizedNumber(input, locale: "de_DE"),
        deExpected == null ? isNull : Decimal.parse(deExpected),
        reason: "de_DE: '$input'",
      );
    }
  });

  test("tryParseLocalizedNumber locale symbols and fallback defaults", () {
    // fr_FR groups with a non-breaking space variant; build input from the
    // actual symbol so the test survives intl data updates.
    final frGroup = Util.getSymbolsFor(locale: "fr_FR")!.GROUP_SEP;
    expect(
      Amount.tryParseLocalizedNumber("1${frGroup}234,5", locale: "fr_FR"),
      Decimal.parse("1234.5"),
    );
    expect(
      Amount.tryParseLocalizedNumber("1234,5", locale: "fr_FR"),
      Decimal.parse("1234.5"),
    );
    // A typed ASCII space is never a valid separator.
    expect(Amount.tryParseLocalizedNumber("1 000", locale: "fr_FR"), isNull);

    // Unknown locale falls back to "," grouping and "." decimals.
    expect(
      Amount.tryParseLocalizedNumber("1,000.5", locale: "zz_ZZ"),
      Decimal.parse("1000.5"),
    );
    expect(
      Amount.tryParseLocalizedNumber("1.5", locale: "zz_ZZ"),
      Decimal.parse("1.5"),
    );
    expect(Amount.tryParseLocalizedNumber("1,5", locale: "zz_ZZ"), isNull);
  });

  test("formatter tolerates an invalid selection", () {
    final formatter = AmountInputFormatter(decimals: 8, locale: "en_US");
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: "1234"),
    );
    expect(result.text, "1,234");
  });
}
