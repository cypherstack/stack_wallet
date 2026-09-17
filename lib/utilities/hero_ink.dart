/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2023 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 *
 */

import 'package:flutter/material.dart';

/// The wallet hero is ONE brand surface for every coin, with white ink.
///
/// The coin's colour has not gone anywhere. It still paints the coin icon, its
/// card on the home screen, and the accents. It just is not the wall the
/// balance sits on.
///
/// Two earlier rules failed on the same coin. The hero began as the coin's own
/// colour with white ink, which put white on Bellscoin's Bell Bag Gold #F3C532
/// at 1.64:1, near invisible. The fix after that adapted the INK per coin,
/// which was always legible but flipped between white and near-black from coin
/// to coin, so three coins read as three products.
///
/// Measured, which is what ruled those out:
///
///     BitFinite  #245BF3   white 5.43:1   near-black 3.48:1
///     Pepecoin   #269B4D   white 3.57:1   near-black 5.07:1
///     Bellscoin  #F3C532   white 1.64:1   near-black 11.08:1
///
/// White cannot be used on that gold at all, so no single ink was reachable
/// while the surface followed the coin. Moving the surface settles it once.
///
/// It was a dark neutral #18181B for a while, which was safe and said nothing.
/// The surface is the brand fill now, blue-600 from the token set, the same
/// blue the Rust wallet's hero card uses. White lands at 6.76:1 on it, so the
/// balance, the labels and the address all clear AA, and the card finally
/// looks like this product rather than like any product.
///
/// Every white step measured against this fill:
///
///     1.00  balance                6.76:1
///     0.92  price, address         5.94:1
///     0.85  sub                    5.28:1
///     0.80  eyebrow, copy glyph    4.84:1
///     0.78  labels                 4.66:1
///     0.62  the balance's dust     3.46:1
///
/// Only the last sits under 4.5, and it is the greyed tail of a 30px w700
/// number, which is large text and clears the 3:1 line that applies to it.
const Color kHeroSurface = Color(0xFF0644F1);

/// Always white now. Kept as a function because every hero label calls it, and
/// a single definition is what stops the ink drifting apart again.
Color heroInk(Color hero) => Colors.white;

/// Hero de-emphasis opacities, passed through unchanged.
///
/// This used to map each white-tuned opacity onto a higher dark-ink one,
/// because dark ink on a mid-luminance fill had less headroom. There is no
/// dark ink on the hero any more, and every step clears AA against
/// [kHeroSurface] by a wide margin, so the shipped values stand as measured.
double heroEmphasis(Color ink, double whiteTunedOpacity) => whiteTunedOpacity;

/// Ink for content on any *other* filled surface — dock pills, the dock itself.
///
/// Unlike the hero, these are not a brand statement, and unreadable text here
/// is a defect rather than a style. The rule is "trust the theme, verify the
/// result": a theme's declared ink is used as-is, and replaced only when it
/// actually fails against the surface it lands on.
///
/// This exists because tokens can disagree with reality. The Orange theme sets
/// `bottom_nav_text` and `popup_bg` to the *same* `#FFFFFF`, so its inactive
/// nav label was painted in the dock's own background — 1.00:1, invisible.
/// No amount of trusting the token fixes that.
///
/// The 4.0 floor sits just under the 4.5 AA line on purpose. Forest puts white
/// at 4.41:1, which reads correctly and was signed off; snapping at 4.5 would
/// restyle Forest over a 0.09 difference. Only genuine failures are replaced.
Color readableInk(Color preferred, Color surface, {double min = 4.0}) {
  if (_contrast(preferred, surface) >= min) return preferred;
  return _contrast(Colors.white, surface) >= _contrast(kInkDark, surface)
      ? Colors.white
      : kInkDark;
}

/// A signal colour (green up, red down, amber busy) that works on the hero.
///
/// This used to take the theme's own colour and lift it toward white until it
/// cleared the floor. That worked on the old dark neutral, where every bundled
/// theme's green and red already passed and nothing was lifted at all. It does
/// not work on the brand blue: the blue is far lighter than the neutral was, so
/// the same loop had to lift the theme's green 9 steps and its red 15 before
/// either cleared, landing on #9BE5B6 and #F2CCCD. Both pass on paper, and on
/// screen they are two barely tinted whites. A rise and a fall have to be
/// telling apart at a glance, and those were not.
///
/// So the hero has its own three tints, authored against this one fill rather
/// than derived from a theme that was authored against the page. The theme
/// still says WHICH state it is; the hero says what that state looks like on
/// blue. Measured on #0644F1:
///
///     up     #7BE8B3   4.52:1   150deg
///     down   #FFC7C1   4.57:1     6deg   (145deg from the up tint)
///     busy   #FFDF9E   5.25:1    38deg
///
/// The hue gap is the point. Contrast alone would have accepted the two
/// washed-out pastels above.
Color onHeroSignal(Color themeColor, {double min = 4.5}) {
  final hue = HSVColor.fromColor(themeColor).hue;
  // Warm reds wrap past 360, so both ends of the wheel are the down tint.
  if (hue < 20 || hue >= 330) return const Color(0xFFFFC7C1);
  if (hue < 70) return const Color(0xFFFFDF9E);
  return const Color(0xFF7BE8B3);
}

/// A near-black rather than pure black: on a saturated fill pure black reads as
/// a hole punched in the surface.
const Color kInkDark = Color(0xFF14161A);

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}
