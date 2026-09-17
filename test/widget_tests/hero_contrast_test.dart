/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2023 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 *
 */

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bitfinite/utilities/hero_ink.dart';

/// The hero fill is one colour that every label on the balance card has to
/// survive, so changing it is the one edit that can make several screens
/// unreadable at once and still compile.
///
/// The card has already been three colours. It was the coin's own, which put
/// white on Bellscoin gold at 1.64:1. It was a near-black, which was safe and
/// said nothing. It is the brand blue now. Each move was justified by numbers
/// and none of the numbers were enforced anywhere, so this file enforces them.
double _relativeLuminance(Color c) {
  double channel(int v) {
    final s = v / 255;
    return s <= 0.03928
        ? s / 12.92
        : math.pow((s + 0.055) / 1.055, 2.4) as double;
  }

  return 0.2126 * channel(c.red) +
      0.7152 * channel(c.green) +
      0.0722 * channel(c.blue);
}

double contrast(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// White at [alpha] as it is actually seen: composited onto the hero, not
/// measured as if it floated free. Opacity is what every hero label uses to
/// step down, so the composite is the thing worth checking.
Color _whiteOn(double alpha, Color ground) =>
    Color.alphaBlend(Colors.white.withOpacity(alpha), ground);

void main() {
  group("hero ink", () {
    test("solid hero ink clears AA on the fill", () {
      expect(
        contrast(heroInk(kHeroSurface), kHeroSurface),
        greaterThanOrEqualTo(4.5),
        reason:
            "the balance itself is the one thing on this card nobody may "
            "have to squint at",
      );
    });

    test("every de-emphasis step still clears its floor", () {
      // 0.62 is the greyed tail of the balance, which is 30px w700. That is
      // large text, so the line it has to clear is 3:1, not 4.5:1. Every other
      // step carries small text and takes the full AA floor.
      final steps = <double, double>{
        0.62: 3.0,
        0.78: 4.5,
        0.80: 4.5,
        0.85: 4.5,
        0.92: 4.5,
        1.00: 4.5,
      };
      steps.forEach((alpha, floor) {
        final seen = _whiteOn(heroEmphasis(Colors.white, alpha), kHeroSurface);
        expect(
          contrast(seen, kHeroSurface),
          greaterThanOrEqualTo(floor),
          reason: "white at $alpha on the hero is unreadable",
        );
      });
    });
  });

  group("hero signal tints", () {
    // The three colours a theme can hand in. Values are the bundled light
    // theme's, but the point is the mapping, not these inputs.
    const green = Color(0xFF17A44F);
    const red = Color(0xFFD34E50);
    const amber = Color(0xFFF7D65D);

    test("each tint clears AA on the hero", () {
      for (final c in [green, red, amber]) {
        expect(
          contrast(onHeroSignal(c), kHeroSurface),
          greaterThanOrEqualTo(4.5),
          reason: "a status colour nobody can read is not a status colour",
        );
      }
    });

    test("up and down stay far apart in hue", () {
      // This is the check that would have caught the naive version. Lifting
      // the theme's own green and red toward white until they cleared the
      // blue produced #9BE5B6 and #F2CCCD: both passed on contrast and both
      // were barely tinted whites. A rise and a fall have to be told apart at
      // a glance, so the hues are pinned too.
      final up = HSVColor.fromColor(onHeroSignal(green)).hue;
      final down = HSVColor.fromColor(onHeroSignal(red)).hue;
      final gap = math.min((up - down).abs(), 360 - (up - down).abs());
      expect(
        gap,
        greaterThan(90),
        reason: "up and down are $up and $down degrees, only $gap apart",
      );
    });

    test("saturation survives the mapping", () {
      // A tint that has lost its colour is white with extra steps.
      for (final c in [green, red, amber]) {
        expect(
          HSVColor.fromColor(onHeroSignal(c)).saturation,
          greaterThan(0.15),
          reason: "${onHeroSignal(c)} has washed out to near white",
        );
      }
    });

    test("a theme's dark green still maps to the up tint", () {
      // The old implementation was sensitive to how dark the theme's colour
      // was, because it lifted until it passed. This one reads the hue, so a
      // deep forest green and a bright one land on the same tint.
      expect(onHeroSignal(const Color(0xFF0B3D20)), onHeroSignal(green));
    });
  });
}
