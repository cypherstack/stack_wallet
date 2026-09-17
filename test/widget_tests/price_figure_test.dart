/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2023 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 *
 */

import 'package:flutter_test/flutter_test.dart';

import 'package:bitfinite/pages/wallet_view/price_view.dart';

/// How the price screen writes a figure.
///
/// The case that forced this to exist: BFX traded at 0.0249 in the 24 hours
/// to 17 September 2026, and the shared money formatter printed that high as
/// "0.02" because it keeps two places from a cent up. The screen drew a peak
/// at two and a half times the current price and captioned it with a number a
/// fifth smaller. A chart and the row under it must not disagree.
void main() {
  const locale = "en_US";

  test("a price above a cent keeps its significant digits", () {
    expect(priceFigure(0.02492901, locale, "USD"), "0.02493 USD");
  });

  test("a price below a cent still widens", () {
    expect(priceFigure(0.00445055, locale, "USD"), "0.004451 USD");
  });

  test("a price of a dollar or more keeps two places and separators", () {
    expect(priceFigure(75838.0, locale, "USD"), "75,838.00 USD");
    expect(priceFigure(1.0, locale, "USD"), "1.00 USD");
  });

  test("widening never leaves trailing zeros", () {
    expect(priceFigure(0.5, locale, "USD"), "0.5 USD");
    expect(priceFigure(0.25, locale, "USD"), "0.25 USD");
  });

  test("zero is still zero", () {
    expect(priceFigure(0, locale, "USD"), "0.00 USD");
  });

  _windowLabels();

  test("a locale that writes a comma gets a comma", () {
    expect(priceFigure(0.02492901, "de_DE", "EUR"), "0,02493 EUR");
  });
}

/// The two window labels on the price screen must describe the same window.
///
/// They did not. The change at the top derived its label from the span the
/// server measured while the high and low rows underneath used the range that
/// had been requested, so BFX showed "+2.14% past 2 days" directly above "30D
/// high". Two scopes, one screen, and the high was a two day extreme wearing a
/// monthly label. Both now come from spanHours, and these pin that.
void _windowLabels() {
  group("window labels", () {
    test("agree about hours", () {
      expect(windowLabel(24), "past 24 hours");
      expect(windowShort(24), "24h");
    });

    test("agree about days", () {
      expect(windowLabel(48), "past 2 days");
      expect(windowShort(48), "2d");
    });

    test("never describe more than the data covers", () {
      // The case that caused this: a 30 day request on a market that has only
      // existed for about two days.
      expect(windowShort(50), "2d");
      expect(windowShort(50), isNot(contains("30")));
    });

    test("say nothing rather than guess when there is no span", () {
      expect(windowLabel(0), "so far");
      expect(windowShort(0), "");
    });

    test("cross from hours to days at the same point", () {
      // A boundary that differed between the two would put "35h" next to
      // "past 1 days" on the same screen.
      for (final hours in <double>[1, 12, 35, 35.9, 36, 48, 200, 720]) {
        final longIsDays = windowLabel(hours).contains("days");
        final shortIsDays = windowShort(hours).endsWith("d");
        expect(
          longIsDays,
          shortIsDays,
          reason: "at $hours the two labels pick different units",
        );
      }
    });
  });
}
