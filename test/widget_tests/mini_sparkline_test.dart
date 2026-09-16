/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2023 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 *
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bitfinite/widgets/price_sparkline.dart';

/// The glyph that sits on the balance card's market row.
///
/// The cases worth pinning are the degenerate ones, because both are real.
/// The BFX market opened in September 2026, so a range can come back with one
/// point or none; and a coin nobody traded today comes back flat. Neither may
/// throw, and neither may draw a shape claiming something the numbers do not
/// say.
void main() {
  Future<void> show(WidgetTester tester, List<double> series) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 64,
              child: MiniSparkline(series: series, color: Colors.green),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  // Scoped to the widget: the framework paints plenty of its own.
  final drawing = find.descendant(
    of: find.byType(MiniSparkline),
    matching: find.byType(CustomPaint),
  );

  testWidgets("a series too short to be a line draws no line", (tester) async {
    await show(tester, const []);
    expect(drawing, findsNothing);
    expect(tester.takeException(), isNull);

    await show(tester, const [0.004]);
    expect(
      drawing,
      findsNothing,
      reason: "one point stretched across the width would be a flat claim "
          "about a market nobody measured",
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets("a price that never moved paints without dividing by zero", (
    tester,
  ) async {
    await show(tester, const [0.004, 0.004, 0.004, 0.004]);
    expect(drawing, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("an ordinary series keeps the height it was given", (
    tester,
  ) async {
    await show(tester, const [0.0044, 0.0051, 0.0049, 0.0090]);
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(MiniSparkline)).height,
      26,
      reason: "the glyph must not resize the row it sits in",
    );
  });
}
