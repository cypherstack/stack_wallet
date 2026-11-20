import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/widgets/hideable_balance.dart';

void main() {
  Widget testApp({required bool hidden, required Widget child}) {
    return ProviderScope(
      overrides: [hideBalancesProvider.overrideWithValue(hidden)],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  testWidgets("shows the balance when masking is disabled", (tester) async {
    await tester.pumpWidget(
      testApp(
        hidden: false,
        child: const HideableBalance(child: Text("12.34 BTC")),
      ),
    );

    expect(find.text("12.34 BTC"), findsOneWidget);
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets("exposes a labeled keyboard-accessible reveal control", (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      testApp(
        hidden: true,
        child: const HideableBalance(child: Text("12.34 BTC")),
      ),
    );

    final control = find.byType(IconButton);
    expect(find.text("12.34 BTC"), findsNothing);
    expect(
      tester.widget<IconButton>(control).tooltip,
      "Show balance temporarily",
    );
    expect(tester.getSize(control).shortestSide, greaterThanOrEqualTo(24));

    final semanticsNode = tester.getSemantics(control);
    final semanticsData = semanticsNode.getSemanticsData();
    expect(semanticsData.tooltip, contains("Show balance temporarily"));
    expect(semanticsNode.flagsCollection.isButton, isTrue);
    expect(semanticsNode.flagsCollection.isEnabled, Tristate.isTrue);
    expect(semanticsData.hasAction(SemanticsAction.tap), isTrue);
    expect(semanticsData.hasAction(SemanticsAction.focus), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(
      tester.getSemantics(control).flagsCollection.isFocused,
      Tristate.isTrue,
      reason: "screen readers need the focus flag on desktop",
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(find.text("12.34 BTC"), findsOneWidget);
    expect(control, findsNothing);

    await tester.pump(HideableBalance.revealDuration);
    expect(find.text("12.34 BTC"), findsNothing);
    expect(find.byType(IconButton), findsOneWidget);
    semantics.dispose();
  });

  testWidgets("reveals only the selected balance", (tester) async {
    await tester.pumpWidget(
      testApp(
        hidden: true,
        child: const Column(
          children: [
            HideableBalance(child: Text("1 BTC")),
            HideableBalance(child: Text(r"$2")),
          ],
        ),
      ),
    );

    await tester.tap(find.byType(IconButton).first);
    await tester.pump();

    expect(find.text("1 BTC"), findsOneWidget);
    expect(find.text(r"$2"), findsNothing);
    expect(find.byType(IconButton), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(HideableBalance.revealDuration);
    expect(tester.takeException(), isNull);
  });
}
