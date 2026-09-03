import 'package:decimal/decimal.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/solana/sol_contract.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/amount/amount_formatter.dart';
import 'package:stackwallet/utilities/amount/amount_input_formatter.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

void main() {
  TextEditingController testController() {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    return controller;
  }

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

  test("tryParse rejects display-formatted strings", () {
    final eth = Ethereum(CryptoCurrencyNetwork.main);
    final btc = Bitcoin(CryptoCurrencyNetwork.main);

    // Display output (grouped, unit-suffixed, "~"-prefixed) is never
    // valid input; only editable text parses.
    expect(
      AmountUnit.nano.tryParse(
        "~10,123,456,789.1 gwei",
        locale: "en_US",
        coin: eth,
      ),
      isNull,
    );
    expect(
      AmountUnit.normal.tryParse("10.12345678 BTC", locale: "en_US", coin: btc),
      isNull,
    );
    expect(
      AmountUnit.milli.tryParse(
        "10,123.45678 mBTC",
        locale: "en_US",
        coin: btc,
      ),
      isNull,
    );

    expect(
      AmountUnit.normal
          .tryParse("10.12345678", locale: "en_US", coin: btc)
          ?.raw,
      BigInt.from(1012345678),
    );
    expect(
      AmountUnit.milli.tryParse("10123.45678", locale: "en_US", coin: btc)?.raw,
      BigInt.from(1012345678),
    );
    expect(
      AmountUnit.nano.tryParse("1012345678", locale: "en_US", coin: btc)?.raw,
      BigInt.from(1012345678),
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

    expect(formatter.tryParseEditable("5")?.decimal, Decimal.fromInt(5));

    for (final value in [
      "+5",
      "-5",
      "1,000",
      for (final codePoint in [0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x20])
        "1${String.fromCharCode(codePoint)}234",
    ]) {
      expect(formatter.tryParseEditable(value), isNull, reason: value);
      expect(
        Amount.tryParseFiatString(value, locale: "en_US"),
        isNull,
        reason: value,
      );
    }

    expect(formatter.tryParseEditable("0.000000001"), isNull);
    expect(Amount.tryParseFiatString("1.001", locale: "en_US"), isNull);

    expect(
      AmountUnit.normal.tryParse("5 legacy", locale: "en_US", coin: coin),
      isNull,
    );
  });

  test("strict parsing accepts only the locale decimal separator", () {
    final coin = Bitcoin(CryptoCurrencyNetwork.main);

    // de_DE uses "," as its decimal separator, so ASCII dots are rejected.
    for (final value in ["1.5", "1.234", "1.000", "10.000", "1.000,5"]) {
      expect(
        AmountUnit.normal.tryParse(value, locale: "de_DE", coin: coin),
        isNull,
        reason: value,
      );
    }
    expect(Amount.tryParseFiatString("1.50", locale: "de_DE"), isNull);

    // The locale's own decimal separator parses.
    expect(
      AmountUnit.normal.tryParse("1,5", locale: "de_DE", coin: coin)?.decimal,
      Decimal.parse("1.5"),
    );
    expect(
      Amount.tryParseFiatString("1,50", locale: "de_DE")?.decimal,
      Decimal.parse("1.5"),
    );
    expect(
      Amount.tryParseEditableDecimal("1,234", locale: "de_DE"),
      Decimal.parse("1.234"),
    );

    expect(
      Util.getSymbolsFor(locale: "de-Latn-CH")?.DECIMAL_SEP,
      Util.getSymbolsFor(locale: "de_CH")?.DECIMAL_SEP,
    );
  });

  test("formatter rejects non-decimal separators", () {
    TextEditingValue edit(
      AmountInputFormatter formatter,
      String oldText,
      String newText,
    ) {
      return formatter.formatEditUpdate(
        TextEditingValue(
          text: oldText,
          selection: TextSelection.collapsed(offset: oldText.length),
        ),
        TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        ),
      );
    }

    final de = AmountInputFormatter(
      controller: testController(),
      decimals: 8,
      locale: "de_DE",
    );
    expect(edit(de, "1", "1.").text, "1");
    expect(edit(de, "1", "1,").text, "1,");
    expect(edit(de, "", "1.200").text, "");
    expect(edit(de, "", "1.200,5").text, "");

    final us = AmountInputFormatter(
      controller: testController(),
      decimals: 8,
      locale: "en_US",
    );
    expect(edit(us, "1", "1,").text, "1");
    expect(edit(us, "1", "1.").text, "1.");
    expect(edit(us, "", "1,200").text, "");
    expect(edit(us, "", "1,200.5").text, "");
  });

  test("canonical and token parsing preserve exact precision", () {
    final canonical = Amount.tryParseCanonicalAmount(
      "1.234567",
      fractionDigits: 6,
    );
    expect(canonical?.raw, BigInt.from(1234567));
    // Excess trailing zeros still represent the exact value; only real
    // sub-atomic precision is rejected.
    expect(
      Amount.tryParseCanonicalAmount("1.2345670", fractionDigits: 6)?.raw,
      BigInt.from(1234567),
    );
    expect(
      Amount.tryParseCanonicalAmount(
        "0.0000000100000000",
        fractionDigits: 8,
      )?.raw,
      BigInt.one,
    );
    expect(
      Amount.tryParseCanonicalAmount("1.2345671", fractionDigits: 6),
      isNull,
    );
    expect(Amount.tryParseCanonicalAmount("1", fractionDigits: -1), isNull);

    // Externally supplied QR/URI amounts may opt into truncation instead of
    // rejection.
    expect(
      Amount.tryParseCanonicalAmount(
        "0.123456789",
        fractionDigits: 8,
        truncateOverprecision: true,
      )?.raw,
      BigInt.from(12345678),
    );
    expect(
      Amount.tryParseCanonicalAmount(
        "1.2345671",
        fractionDigits: 6,
        truncateOverprecision: true,
      )?.raw,
      BigInt.from(1234567),
    );
    // Truncation never loosens the grammar itself.
    expect(
      Amount.tryParseCanonicalAmount(
        "1e-3",
        fractionDigits: 8,
        truncateOverprecision: true,
      ),
      isNull,
    );
    expect(
      Amount.tryParseCanonicalAmount(
        "-1",
        fractionDigits: 8,
        truncateOverprecision: true,
      ),
      isNull,
    );

    final token = SolContract(
      address: "mint",
      name: "Token",
      symbol: "TKN",
      decimals: 6,
    );
    final parsedToken = AmountUnit.normal.tryParse(
      "1000",
      locale: "en_US",
      coin: Solana(CryptoCurrencyNetwork.main),
      tokenContract: token,
    );
    expect(parsedToken?.raw, BigInt.from(1000000000));
    expect(parsedToken?.fractionDigits, 6);
  });

  test("formatter tolerates an invalid selection", () {
    final formatter = AmountInputFormatter(
      controller: testController(),
      decimals: 8,
      locale: "en_US",
    );
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: "1234"),
    );
    expect(result.text, "1234");

    const composingValue = TextEditingValue(
      text: "1.",
      selection: TextSelection.collapsed(offset: 2),
      composing: TextRange(start: 1, end: 2),
    );
    final commaFormatter = AmountInputFormatter(
      controller: testController(),
      decimals: 8,
      locale: "de_DE",
    );
    expect(
      commaFormatter.formatEditUpdate(TextEditingValue.empty, composingValue),
      composingValue,
    );

    // When the IME commits that invalid composing text, the formatter
    // sanitizes instead of trapping the field in an unparseable state.
    final committed = commaFormatter.formatEditUpdate(
      composingValue,
      const TextEditingValue(
        text: "1.",
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    expect(committed.text, "1");
    expect(committed.composing, TextRange.empty);
  });

  test("formatter restores valid text after rebuilding during IME input", () {
    const valid = TextEditingValue(
      text: "1,5",
      selection: TextSelection.collapsed(offset: 3),
    );
    const composing = TextEditingValue(
      text: "1.5",
      selection: TextSelection.collapsed(offset: 3),
      composing: TextRange(start: 1, end: 2),
    );
    const committed = TextEditingValue(
      text: "1.5",
      selection: TextSelection.collapsed(offset: 3),
    );

    final controller = testController();
    final beforeRebuild = AmountInputFormatter(
      controller: controller,
      decimals: 8,
      locale: "de_DE",
    );
    expect(beforeRebuild.formatEditUpdate(valid, composing), composing);

    final afterRebuild = AmountInputFormatter(
      controller: controller,
      decimals: 8,
      locale: "de_DE",
    );
    expect(afterRebuild.formatEditUpdate(composing, committed), valid);
  });

  test("formatter restores valid text when an IME changes text at commit", () {
    const valid = TextEditingValue(
      text: "1,5",
      selection: TextSelection.collapsed(offset: 3),
    );
    const composing = TextEditingValue(
      text: "1.5",
      selection: TextSelection.collapsed(offset: 3),
      composing: TextRange(start: 1, end: 2),
    );
    const changedCommit = TextEditingValue(
      text: "1.",
      selection: TextSelection.collapsed(offset: 2),
    );

    final controller = testController();
    AmountInputFormatter(
      controller: controller,
      decimals: 8,
      locale: "de_DE",
    ).formatEditUpdate(valid, composing);

    expect(
      AmountInputFormatter(
        controller: controller,
        decimals: 8,
        locale: "de_DE",
      ).formatEditUpdate(composing, changedCommit),
      valid,
    );
  });

  test("formatter recovery is isolated by controller and configuration", () {
    TextEditingValue value(String text) => TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );

    final controller = testController();
    final de = AmountInputFormatter(
      controller: controller,
      decimals: 8,
      locale: "de_DE",
    );
    de.formatEditUpdate(TextEditingValue.empty, value("1,5"));

    final otherController = AmountInputFormatter(
      controller: testController(),
      decimals: 8,
      locale: "de_DE",
    );
    expect(
      otherController.formatEditUpdate(value("2.5"), value("2.5")).text,
      "2",
    );

    final otherLocale = AmountInputFormatter(
      controller: controller,
      decimals: 8,
      locale: "en_US",
    );
    expect(otherLocale.formatEditUpdate(value("2,5"), value("2,5")).text, "2");

    final highPrecision = AmountInputFormatter(
      controller: controller,
      decimals: 8,
      locale: "en_US",
    );
    highPrecision.formatEditUpdate(TextEditingValue.empty, value("1.234"));
    final lowPrecision = AmountInputFormatter(
      controller: controller,
      decimals: 2,
      locale: "en_US",
    );
    expect(
      lowPrecision.formatEditUpdate(value("1.234"), value("1.234")).text,
      "1.23",
    );
  });

  test(
    "formatter does not restore stale recovery after a config round trip",
    () {
      TextEditingValue value(String text) => TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );

      final controller = testController();
      final fiat = AmountInputFormatter(
        controller: controller,
        decimals: 2,
        locale: "en_US",
      );
      fiat.formatEditUpdate(TextEditingValue.empty, value("50"));

      final highPrecision = AmountInputFormatter(
        controller: controller,
        decimals: 8,
        locale: "en_US",
      );
      highPrecision.formatEditUpdate(value("50"), value("0.12345"));

      final fiatAgain = AmountInputFormatter(
        controller: controller,
        decimals: 2,
        locale: "en_US",
      );
      expect(
        fiatAgain.formatEditUpdate(value("0.12345"), value("0.123456")).text,
        "0.12",
      );
    },
  );

  test("formatter clears recovery and isolates amount-unit shifts", () {
    TextEditingValue value(String text) => TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );

    final controller = testController();
    final de = AmountInputFormatter(
      controller: controller,
      decimals: 8,
      locale: "de_DE",
    );
    de.formatEditUpdate(TextEditingValue.empty, value("1,5"));
    de.formatEditUpdate(value("1,5"), TextEditingValue.empty);
    expect(
      AmountInputFormatter(
        controller: controller,
        decimals: 8,
        locale: "de_DE",
      ).formatEditUpdate(value("2.5"), value("2.5")).text,
      "2",
    );

    final normal = AmountInputFormatter(
      controller: controller,
      decimals: 8,
      locale: "en_US",
      unit: AmountUnit.normal,
    );
    normal.formatEditUpdate(TextEditingValue.empty, value("1.123456"));
    expect(
      AmountInputFormatter(
        controller: controller,
        decimals: 8,
        locale: "en_US",
        unit: AmountUnit.milli,
      ).formatEditUpdate(value("1.123456"), value("1.123456")).text,
      "1.12345",
    );
  });

  test("formatter never joins digits around stripped invalid characters", () {
    TextEditingValue committedInvalid(String text, {int? caret}) {
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: caret ?? text.length),
      );
    }

    // Both old and new values invalid (IME commit path): the recovered text
    // must be a prefix of the committed text, never digits joined across a
    // stripped character ("1.5" must not become "15").
    final de = AmountInputFormatter(
      controller: testController(),
      decimals: 8,
      locale: "de_DE",
    );
    expect(
      de
          .formatEditUpdate(committedInvalid("1.5"), committedInvalid("1.5"))
          .text,
      "1",
    );
    expect(
      de
          .formatEditUpdate(committedInvalid("1e3"), committedInvalid("1e3"))
          .text,
      "1",
    );
    expect(
      de.formatEditUpdate(committedInvalid("-5"), committedInvalid("-5")).text,
      "",
    );
    expect(
      de
          .formatEditUpdate(
            committedInvalid("abc12", caret: 3),
            committedInvalid("abc12", caret: 3),
          )
          .text,
      "",
    );

    // A formatter that admitted an invalid composing edit restores the valid
    // value from immediately before that composition.
    final usController = testController();
    final us = AmountInputFormatter(
      controller: usController,
      decimals: 8,
      locale: "en_US",
    );
    final valid = committedInvalid("1.5");
    const composingInvalid = TextEditingValue(
      text: "1,5",
      selection: TextSelection.collapsed(offset: 3),
      composing: TextRange(start: 1, end: 2),
    );
    expect(us.formatEditUpdate(valid, composingInvalid), composingInvalid);
    expect(
      AmountInputFormatter(
        controller: usController,
        decimals: 8,
        locale: "en_US",
      ).formatEditUpdate(composingInvalid, committedInvalid("1,5")).text,
      "1.5",
    );
  });

  test("editable parsers accept one trailing decimal separator", () {
    expect(Amount.tryParseEditableDecimal("1.", locale: "en_US"), Decimal.one);
    expect(Amount.tryParseEditableDecimal("1,", locale: "de_DE"), Decimal.one);
    expect(
      AmountUnit.normal
          .tryParse(
            "10.",
            locale: "en_US",
            coin: Bitcoin(CryptoCurrencyNetwork.main),
          )
          ?.raw,
      BigInt.from(1000000000),
    );
    // Separator-only and doubled separators stay invalid.
    for (final (value, locale) in [
      (".", "en_US"),
      (",", "de_DE"),
      ("1..", "en_US"),
      (".5.", "en_US"),
    ]) {
      expect(
        Amount.tryParseEditableDecimal(value, locale: locale),
        isNull,
        reason: "$locale '$value'",
      );
    }
    // Canonical parsing stays strict.
    expect(Amount.tryParseCanonicalAmount("1.", fractionDigits: 8), isNull);
  });

  test("formatEditableDecimal writes locale-editable text", () {
    expect(
      Amount.formatEditableDecimal(Decimal.parse("1.5"), locale: "en_US"),
      "1.5",
    );
    expect(
      Amount.formatEditableDecimal(Decimal.parse("1.5"), locale: "de_DE"),
      "1,5",
    );
    // no grouping, ever: editable text must parse back via tryParseEditable*
    expect(
      Amount.formatEditableDecimal(
        Decimal.parse("1234567.89"),
        locale: "de_DE",
      ),
      "1234567,89",
    );
    expect(
      Amount.tryParseEditableDecimal(
        Amount.formatEditableDecimal(
          Decimal.parse("1234567.89"),
          locale: "de_DE",
        ),
        locale: "de_DE",
      ),
      Decimal.parse("1234567.89"),
    );
  });

  test("formatFixedDecimal writes locale-editable fixed text", () {
    expect(
      Amount.formatFixedDecimal(
        Decimal.parse("1.5"),
        fractionDigits: 3,
        locale: "de_DE",
      ),
      "1,500",
    );
    expect(
      Amount.formatFixedDecimal(
        Decimal.parse("1.5"),
        fractionDigits: 2,
        locale: "en_US",
      ),
      "1.50",
    );
    expect(
      () => Amount.formatFixedDecimal(
        Decimal.one,
        fractionDigits: -1,
        locale: "en_US",
      ),
      throwsArgumentError,
    );
  });

  test("formatEditable round-trips through tryParseEditable", () {
    final coin = Bitcoin(CryptoCurrencyNetwork.main);
    final amount = Amount(rawValue: BigInt.from(1012345678), fractionDigits: 8);

    for (final locale in ["en_US", "de_DE"]) {
      for (final unit in [
        AmountUnit.normal,
        AmountUnit.milli,
        AmountUnit.nano,
      ]) {
        final formatter = AmountFormatter(
          unit: unit,
          locale: locale,
          coin: coin,
          maxDecimals: 8,
        );
        final text = formatter.formatEditable(amount);
        expect(
          formatter.tryParseEditable(text),
          amount,
          reason: "$locale $unit $text",
        );
      }
    }

    expect(
      AmountUnit.normal.formatEditable(amount: amount, locale: "de_DE"),
      "10,12345678",
    );
    expect(
      AmountUnit.nano.formatEditable(amount: amount, locale: "de_DE"),
      "1012345678",
    );
  });

  test("relocalizeEditableDecimal rewrites the decimal separator", () {
    expect(
      Amount.relocalizeEditableDecimal(
        "1,5",
        sourceLocale: "de_DE",
        targetLocale: "en_US",
      ),
      "1.5",
    );
    expect(
      Amount.relocalizeEditableDecimal(
        "1.5",
        sourceLocale: "en_US",
        targetLocale: "de_DE",
      ),
      "1,5",
    );
    expect(
      Amount.relocalizeEditableDecimal(
        "",
        sourceLocale: "en_US",
        targetLocale: "de_DE",
      ),
      "",
    );
    // same separator locales: unchanged
    expect(
      Amount.relocalizeEditableDecimal(
        "1.5",
        sourceLocale: "en_US",
        targetLocale: "en_GB",
      ),
      "1.5",
    );
  });
}
