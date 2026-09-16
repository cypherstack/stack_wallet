import "package:flutter_test/flutter_test.dart";
import "package:stackwallet/pages/wallet_view/transaction_views/transaction_search_filter_view.dart";
import "package:stackwallet/utilities/amount/amount_formatter.dart";
import "package:stackwallet/utilities/amount/amount_unit.dart";
import "package:stackwallet/wallets/crypto_currency/crypto_currency.dart";

void main() {
  AmountFormatter formatter(String locale) => AmountFormatter(
    unit: AmountUnit.normal,
    locale: locale,
    coin: Bitcoin(CryptoCurrencyNetwork.main),
    maxDecimals: 8,
  );

  test("transaction filter distinguishes empty from malformed amounts", () {
    for (final text in ["", "."]) {
      expect(
        parseTransactionFilterAmountInput(
          text: text,
          locale: "en_US",
          formatter: formatter("en_US"),
        ),
        (isValid: true, amount: null),
        reason: text,
      );
    }

    final trailingSeparator = parseTransactionFilterAmountInput(
      text: "1.",
      locale: "en_US",
      formatter: formatter("en_US"),
    );
    expect(trailingSeparator.isValid, isTrue);
    expect(trailingSeparator.amount?.raw, BigInt.from(100000000));

    for (final text in ["1..", "1.2."]) {
      expect(
        parseTransactionFilterAmountInput(
          text: text,
          locale: "en_US",
          formatter: formatter("en_US"),
        ).isValid,
        isFalse,
        reason: text,
      );
    }
  });

  test("transaction filter uses the locale separator", () {
    expect(
      parseTransactionFilterAmountInput(
        text: ",",
        locale: "de_DE",
        formatter: formatter("de_DE"),
      ),
      (isValid: true, amount: null),
    );
    expect(
      parseTransactionFilterAmountInput(
        text: "1,,",
        locale: "de_DE",
        formatter: formatter("de_DE"),
      ).isValid,
      isFalse,
    );
  });
}
