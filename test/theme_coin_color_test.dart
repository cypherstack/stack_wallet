import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bitfinite/models/isar/stack_theme.dart';
import 'package:bitfinite/themes/theme_providers.dart';
import 'package:bitfinite/wallets/crypto_currency/coins/bitfinite.dart';
import 'package:bitfinite/wallets/crypto_currency/coins/dash.dart';
import 'package:bitfinite/wallets/crypto_currency/crypto_currency.dart';

import 'sample_data/theme_json.dart';

/// Which colour a coin wears, and who gets to decide.
///
/// Three rungs, in order: the active theme's own entry for the coin, then the
/// coin's published brand colour, then the theme's primary. Each rung was
/// added because the one below it got something wrong, and the order is the
/// whole behaviour, so all three are pinned here.
///
/// This file previously asserted only the third rung and went stale the moment
/// the second was added. It stayed red for weeks without anyone noticing,
/// which is its own argument for CI actually running.
void main() {
  StackTheme themeWithoutCoinColours() =>
      StackTheme.fromJson(json: lightThemeJsonMap);

  ProviderContainer containerFor(StackTheme theme) {
    final container = ProviderContainer(
      overrides: [
        themeProvider.overrideWithProvider(StateProvider((ref) => theme)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test(
    "the fixture really has no coin colours, or nothing below means much",
    () {
      expect(
        themeWithoutCoinColours().coinColors.containsKey("bitfinite"),
        isFalse,
      );
    },
  );

  test("a coin with a brand colour keeps it under a foreign theme", () {
    // Themes inherited from upstream only define colours for the coins
    // upstream ships, so they have no BitFinite entry. Before the brand rung
    // existed, BFX wore Forest teal or OceanBreeze blue: the coin that IS the
    // product was the only one on the screen losing its face.
    final theme = themeWithoutCoinColours();
    final color = containerFor(
      theme,
    ).read(pCoinColor(Bitfinite(CryptoCurrencyNetwork.main)));

    expect(color, const Color(0xFF2258E6));
    expect(
      color,
      isNot(theme.buttonBackPrimary),
      reason: "the brand rung must beat the theme's primary, not tie with it",
    );
  });

  test("a coin with no brand colour still follows the theme", () {
    // The third rung is still load-bearing, and this is what proves it did
    // not get bypassed for every coin when the second rung arrived.
    // Dash, because the fixture names no colour for it and it publishes no
    // brand colour here. Bitcoin looks like the obvious choice and is not:
    // the fixture DOES name a colour for it, so it never reaches rung three.
    final coin = Dash(CryptoCurrencyNetwork.main);
    expect(
      coin.brandColorValue,
      isNull,
      reason: "pick a coin with no brand colour, or this tests the wrong rung",
    );
    expect(
      themeWithoutCoinColours().coinColors.containsKey(coin.mainNetId),
      isFalse,
      reason: "pick a coin the fixture does not name, or rung one wins",
    );

    final theme = themeWithoutCoinColours();
    final color = containerFor(theme).read(pCoinColor(coin));

    expect(color, theme.buttonBackPrimary);
    expect(
      color,
      isNot(Colors.deepOrangeAccent),
      reason: "the old hardcoded orange clashed with every non-orange theme",
    );
  });

  test("a theme that names the coin beats the brand colour", () {
    // The top rung. A theme author who has chosen a BitFinite colour must not
    // be overruled by ours, which is what keeps the brand rung a fallback
    // rather than a hardcode with extra steps.
    final json = Map<String, dynamic>.from(lightThemeJsonMap);
    final colors = Map<String, dynamic>.from(json["colors"] as Map);
    colors["coin"] = {"bitfinite": "0xFF00FF00"};
    json["colors"] = colors;

    final theme = StackTheme.fromJson(json: json);
    final color = containerFor(
      theme,
    ).read(pCoinColor(Bitfinite(CryptoCurrencyNetwork.main)));

    expect(color, const Color(0xFF00FF00));
  });
}
