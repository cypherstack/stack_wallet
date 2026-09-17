/*
 * This file is part of BitFinite Wallet.
 */

import 'package:flutter/material.dart';

/// An address with its first and last characters picked out.
///
/// Nothing is hidden. The whole string is rendered; the ends are simply drawn
/// in a second colour so the eye has something to compare against when
/// checking one address against another.
///
/// This is a security control, not decoration. Address poisoning works by
/// minting a vanity address that matches the start and end of one you have
/// already used, so a truncated "bfx:ffdwz...ek0" looks identical to the real
/// thing. Blockaid counted 65 million poisoning transactions between January
/// 2025 and February 2026, rising from 628,000 attempts in November 2025 to
/// 3.4 million in January 2026. MetaMask shipped detection in June 2026 and,
/// in the same change, began showing MORE characters rather than fewer.
///
/// So the rule is the one BlueWallet settled on: show everything, accent the
/// ends, never truncate. Accenting the ends is what makes a by-eye check
/// possible; showing the middle is what makes the check meaningful, because
/// the middle is the part an attacker cannot match.
class AddressText extends StatelessWidget {
  const AddressText(
    this.address, {
    required this.style,
    required this.accentColor,
    this.edgeLength = 6,
    this.textAlign,
    super.key,
  });

  final String address;
  final TextStyle style;

  /// Colour for the leading and trailing run. Passed in rather than read from
  /// the theme because these appear on the page AND on the hero, and anything
  /// on the hero takes its ink from the hero.
  final Color accentColor;

  /// How many characters at each end. Six is what BlueWallet and MetaMask both
  /// settled on: enough to be memorable, short enough that the unaccented
  /// middle still dominates.
  final int edgeLength;

  final TextAlign? textAlign;

  /// Splits "bfx:ffdw..." into its prefix and its payload.
  ///
  /// The accent starts after the colon. "bfx:ff" would spend four of the six
  /// accented characters on a prefix every BFX address shares, which tells a
  /// reader comparing two addresses nothing at all.
  static (String prefix, String body) splitPrefix(String address) {
    final colon = address.indexOf(":");
    if (colon <= 0 || colon >= address.length - 1) return ("", address);
    return (address.substring(0, colon + 1), address.substring(colon + 1));
  }

  /// The accented spans, so a SelectableText.rich can use the same rule.
  ///
  /// Exposed rather than only rendered because several of these sit on screens
  /// where the address has to stay selectable, and a widget that quietly took
  /// that away would be a worse screen than the one it replaced.
  static TextSpan spanFor(
    String address, {
    required TextStyle style,
    required Color accentColor,
    int edgeLength = 6,
  }) {
    final (prefix, body) = splitPrefix(address);
    final accent = style.copyWith(color: accentColor);

    // Too short to have two distinct ends: accent nothing rather than accent
    // the same characters twice, which would imply a match that is not there.
    if (body.length <= edgeLength * 2) {
      return TextSpan(text: address, style: style);
    }

    return TextSpan(
      children: [
        if (prefix.isNotEmpty) TextSpan(text: prefix, style: style),
        TextSpan(text: body.substring(0, edgeLength), style: accent),
        TextSpan(
          text: body.substring(edgeLength, body.length - edgeLength),
          style: style,
        ),
        TextSpan(text: body.substring(body.length - edgeLength), style: accent),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      spanFor(
        address,
        style: style,
        accentColor: accentColor,
        edgeLength: edgeLength,
      ),
      textAlign: textAlign,
    );
  }
}
