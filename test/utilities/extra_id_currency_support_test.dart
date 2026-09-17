import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/extra_id_currency_support.dart';

void main() {
  test("known tag currencies match case-insensitively", () {
    for (final ticker in [
      "xrp",
      "XRP",
      " xlm ",
      "Atom",
      "eos",
      "hbar",
      "ton",
    ]) {
      expect(ExtraIdCurrencySupport.mayRequire(ticker), isTrue, reason: ticker);
    }

    for (final ticker in ["btc", "eth", "xmr", "ltc", "doge", "bnb", ""]) {
      expect(
        ExtraIdCurrencySupport.mayRequire(ticker),
        isFalse,
        reason: ticker,
      );
    }
  });
}
