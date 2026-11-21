import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages/coin_control/selectable_utxo_surface.dart';

void main() {
  Widget testApp({
    required bool canSelect,
    required bool selected,
    required VoidCallback onToggle,
    required VoidCallback onOptions,
  }) => MaterialApp(
    home: Scaffold(
      body: SelectableUtxoSurface(
        canSelect: canSelect,
        selected: selected,
        onToggle: onToggle,
        child: SizedBox(
          width: 300,
          height: 64,
          child: Row(
            children: [
              const Expanded(child: Text("Output 1")),
              IconButton(
                key: const Key("options"),
                onPressed: onOptions,
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  testWidgets("row and nested options have independent actions", (
    tester,
  ) async {
    var toggles = 0;
    var options = 0;

    await tester.pumpWidget(
      testApp(
        canSelect: true,
        selected: false,
        onToggle: () => toggles++,
        onOptions: () => options++,
      ),
    );

    await tester.tap(find.text("Output 1"));
    await tester.pump();
    expect(toggles, 1);
    expect(options, 0);

    await tester.tap(find.byKey(const Key("options")));
    await tester.pump();
    expect(toggles, 1);
    expect(options, 1);
  });

  testWidgets("row selection supports keyboard activation and semantics", (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var toggles = 0;

    await tester.pumpWidget(
      testApp(
        canSelect: true,
        selected: true,
        onToggle: () => toggles++,
        onOptions: () {},
      ),
    );

    final selectedSurface = find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.selected == true,
    );
    expect(
      tester.getSemantics(selectedSurface).flagsCollection.isSelected,
      Tristate.isTrue,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(toggles, 1);

    semantics.dispose();
  });

  testWidgets("nonselectable rows retain their options action", (tester) async {
    var toggles = 0;
    var options = 0;

    await tester.pumpWidget(
      testApp(
        canSelect: false,
        selected: false,
        onToggle: () => toggles++,
        onOptions: () => options++,
      ),
    );

    await tester.tap(find.text("Output 1"));
    await tester.tap(find.byKey(const Key("options")));
    await tester.pump();

    expect(toggles, 0);
    expect(options, 1);
  });
}
