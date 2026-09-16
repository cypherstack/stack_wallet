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

  test("a locale that writes a comma gets a comma", () {
    expect(priceFigure(0.02492901, "de_DE", "EUR"), "0,02493 EUR");
  });
}
