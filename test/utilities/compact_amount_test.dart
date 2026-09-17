/*
 * This file is part of BitFinite Wallet.
 */

import 'package:flutter_test/flutter_test.dart';

import 'package:bitfinite/utilities/compact_amount.dart';

/// Shortening a balance that is too long to read.
///
/// The rule drops the fraction and keeps the magnitude, so it is only ever
/// safe on a number whose whole part already carries the meaning. The
/// threshold is what makes that true, and it was possible to pass a threshold
/// that switched the guard off entirely. The mining payout card did exactly
/// that with minWholeDigits: 1, and every total it rendered had eight
/// decimals, so the condition was always met: 0.87654321 BFX displayed as
/// "0 BFX" and 12.5 as "12".
///
/// These tests exist to make that trap visible at the helper, since the call
/// site read as though it were asking for something conservative.
void main() {
  group("withoutDustDecimals", () {
    test("leaves a number that is short enough alone", () {
      expect(withoutDustDecimals("1,234.56789012"), isNull);
      expect(withoutDustDecimals("0.5"), isNull);
    });

    test("drops only the fraction once the whole part is long enough", () {
      expect(withoutDustDecimals("12,345,678.90000000"), "12,345,678");
    });

    test("never mistakes a grouping separator for a decimal point", () {
      // A locale that groups with "." would otherwise have its number cut in
      // half rather than its decimals dropped.
      expect(withoutDustDecimals("1.234.567"), isNull);
    });

    test("a low threshold switches the guard off, which is the trap", () {
      // Documented, not endorsed. Anyone reaching for a small threshold to
      // tidy up a row is asking for the whole fraction to be deleted from
      // every number, including the ones that are nothing but fraction.
      expect(
        withoutDustDecimals("0.87654321", minWholeDigits: 1),
        "0",
        reason: "this is what the mining payout card used to render",
      );
      expect(withoutDustDecimals("12.50000000", minWholeDigits: 1), "12");
    });

    test("it truncates, it does not round", () {
      // Worth stating because "12" for 12.9 is a floor, not the nearest whole
      // coin, and the result carries no marker saying so.
      expect(withoutDustDecimals("12.99999999", minWholeDigits: 1), "12");
    });
  });
}
