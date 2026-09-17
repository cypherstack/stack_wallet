/*
 * This file is part of BitFinite Wallet.
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bitfinite/widgets/address_text.dart';

/// Accenting the ends of an address is a check, so the rules about WHICH
/// characters get accented are the whole feature.
void main() {
  const style = TextStyle(color: Color(0xFF111111));
  const accent = Color(0xFF0644F1);

  List<TextSpan> spansOf(String address, {int edge = 6}) {
    final span = AddressText.spanFor(
      address,
      style: style,
      accentColor: accent,
      edgeLength: edge,
    );
    return (span.children ?? [span]).cast<TextSpan>();
  }

  String rendered(String address) =>
      spansOf(address).map((s) => s.text ?? "").join();

  group("splitPrefix", () {
    test("separates a cashaddr prefix from its payload", () {
      expect(AddressText.splitPrefix("bfx:ffdwzfex3g"), ("bfx:", "ffdwzfex3g"));
    });

    test("leaves a base58 address alone", () {
      // Pepecoin, Bellscoin, Dogecoin and Bitcoin carry no prefix.
      expect(AddressText.splitPrefix("PeU3PGXMGcFcABC"), (
        "",
        "PeU3PGXMGcFcABC",
      ));
    });

    test("ignores a colon at either extreme", () {
      expect(AddressText.splitPrefix(":abc"), ("", ":abc"));
      expect(AddressText.splitPrefix("abc:"), ("", "abc:"));
    });
  });

  group("accenting", () {
    test("never changes the address", () {
      const address = "bfx:ffdwzfex3g058z4zl4ntphkmxue3ecpesu0jqu0ek0";
      expect(
        rendered(address),
        address,
        reason: "every character must survive; this widget hides nothing",
      );
    });

    test("does not spend the accent on the coin prefix", () {
      // "bfx:" is on every BFX address, so accenting it would compare two
      // addresses on the part that can never differ.
      final spans = spansOf("bfx:ffdwzfex3g058z4zl4ntphkmxue3ecpesu0jqu0ek0");
      expect(spans.first.text, "bfx:");
      expect(spans.first.style?.color, style.color);
      expect(spans[1].text, "ffdwzf");
      expect(spans[1].style?.color, accent);
    });

    test("accents both ends of a base58 address", () {
      final spans = spansOf("PeU3PGXMGcFcn7if84xxxxxxxxxxxx");
      expect(spans.first.text, "PeU3PG");
      expect(spans.first.style?.color, accent);
      expect(spans.last.style?.color, accent);
    });

    test(
      "the middle stays unaccented, because that is the part that differs",
      () {
        // The whole point. A poisoned address matches the ends and differs in
        // the middle, so the middle must be visible and must not be styled as
        // though it were part of the match.
        final spans = spansOf("bfx:ffdwzfex3g058z4zl4ntphkmxue3ecpesu0jqu0ek0");
        final middle = spans[2];
        expect(middle.style?.color, style.color);
        expect(middle.text!.length, greaterThan(12));
      },
    );

    test("an address too short for two distinct ends is left plain", () {
      // Accenting six at each end of a ten character string would paint the
      // same characters twice and imply a match that is not there.
      final spans = spansOf("bfx:abcdefgh");
      expect(spans.length, 1);
      expect(spans.first.style?.color, style.color);
    });
  });

  testWidgets("renders every character on screen", (tester) async {
    const address = "bfx:ffdwzfex3g058z4zl4ntphkmxue3ecpesu0jqu0ek0";
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AddressText(address, style: style, accentColor: accent),
        ),
      ),
    );
    final widget = tester.widget<Text>(find.byType(Text));
    expect(widget.textSpan!.toPlainText(), address);
  });
}
