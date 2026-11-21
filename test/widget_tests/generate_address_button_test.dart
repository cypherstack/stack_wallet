import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/widgets/generate_address_button.dart';

import '../sample_data/theme_json.dart';

void main() {
  Widget testApp(
    Widget child, {
    GlobalKey<NavigatorState>? rootKey,
    GlobalKey<NavigatorState>? nestedKey,
  }) {
    final theme = StackTheme.fromJson(json: lightThemeJsonMap);
    return ProviderScope(
      overrides: [themeProvider.overrideWithValue(StateController(theme))],
      child: MaterialApp(
        navigatorKey: rootKey,
        theme: ThemeData(extensions: [StackColors.fromStackColorTheme(theme)]),
        home: Scaffold(
          body: Navigator(
            key: nestedKey,
            onGenerateRoute: (_) =>
                MaterialPageRoute<void>(builder: (_) => child),
          ),
        ),
      ),
    );
  }

  testWidgets("closes only its dialog after generation", (tester) async {
    final generation = Completer<void>();
    var generated = 0;

    await tester.pumpWidget(
      testApp(
        Column(
          children: [
            const Text("Nested page remains"),
            GenerateAddressButton(
              generateAddress: () => generation.future,
              onGenerated: () => generated++,
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text("Generate new address"));
    await tester.pump();

    expect(find.text("Generating address"), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text("Generating address"), findsOneWidget);

    generation.complete();
    await tester.pumpAndSettle();

    expect(find.text("Generating address"), findsNothing);
    expect(find.text("Nested page remains"), findsOneWidget);
    expect(generated, 1);
  });

  testWidgets("ignores repeated taps while generation is running", (
    tester,
  ) async {
    final generation = Completer<void>();
    var calls = 0;

    await tester.pumpWidget(
      testApp(
        GenerateAddressButton(
          generateAddress: () {
            calls++;
            return generation.future;
          },
        ),
      ),
    );

    final button = tester.widget<TextButton>(find.byType(TextButton));
    button.onPressed!.call();
    button.onPressed!.call();
    await tester.pump();

    expect(calls, 1);

    generation.complete();
    await tester.pumpAndSettle();
  });

  testWidgets("closes the dialog and reports generation failures", (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        GenerateAddressButton(
          generateAddress: () => throw StateError("native failure"),
        ),
      ),
    );

    await tester.tap(find.text("Generate new address"));
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text("Generating address"), findsNothing);
    expect(find.text("Failed to generate a new address"), findsOneWidget);

    final button = tester.widget<TextButton>(find.byType(TextButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets("shows the progress dialog on the root navigator", (
    tester,
  ) async {
    final rootKey = GlobalKey<NavigatorState>();
    final nestedKey = GlobalKey<NavigatorState>();
    final generation = Completer<void>();

    await tester.pumpWidget(
      testApp(
        GenerateAddressButton(generateAddress: () => generation.future),
        rootKey: rootKey,
        nestedKey: nestedKey,
      ),
    );

    expect(rootKey.currentState!.canPop(), isFalse);
    await tester.tap(find.text("Generate new address"));
    await tester.pump();

    expect(find.text("Generating address"), findsOneWidget);
    expect(
      rootKey.currentState!.canPop(),
      isTrue,
      reason: "the dialog must cover the whole app, not just a nested pane",
    );
    expect(nestedKey.currentState!.canPop(), isFalse);

    generation.complete();
    await tester.pumpAndSettle();

    expect(rootKey.currentState!.canPop(), isFalse);
    expect(find.text("Generating address"), findsNothing);
  });

  testWidgets("closes its dialog even if the button is disposed mid run", (
    tester,
  ) async {
    final generation = Completer<void>();
    var generated = 0;
    final show = ValueNotifier<bool>(true);

    await tester.pumpWidget(
      testApp(
        ValueListenableBuilder<bool>(
          valueListenable: show,
          builder: (_, visible, __) => visible
              ? GenerateAddressButton(
                  generateAddress: () => generation.future,
                  onGenerated: () => generated++,
                )
              : const Text("button gone"),
        ),
      ),
    );

    await tester.tap(find.text("Generate new address"));
    await tester.pump();
    expect(find.text("Generating address"), findsOneWidget);

    show.value = false;
    await tester.pump();
    expect(find.byType(GenerateAddressButton), findsNothing);
    expect(find.text("Generating address"), findsOneWidget);

    generation.complete();
    await tester.pumpAndSettle();

    expect(find.text("Generating address"), findsNothing);
    expect(find.text("button gone"), findsOneWidget);
    expect(generated, 0, reason: "callback must not fire after dispose");
    expect(tester.takeException(), isNull);
  });

  testWidgets("leaves routes pushed above the dialog alone", (tester) async {
    final rootKey = GlobalKey<NavigatorState>();
    final generation = Completer<void>();
    var generated = 0;

    await tester.pumpWidget(
      testApp(
        GenerateAddressButton(
          generateAddress: () => generation.future,
          onGenerated: () => generated++,
        ),
        rootKey: rootKey,
      ),
    );

    await tester.tap(find.text("Generate new address"));
    await tester.pump();
    expect(find.text("Generating address"), findsOneWidget);

    // Stands in for the idle lockscreen, or any other event driven route that
    // can land on the root navigator while generation is still running.
    unawaited(
      rootKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text("Intruder route")),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("Intruder route"), findsOneWidget);

    generation.complete();
    // Fixed pumps rather than pumpAndSettle: a stranded dialog animates its
    // loading indicator forever, which would time out instead of failing here.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text("Intruder route"), findsOneWidget);
    expect(find.text("Generating address", skipOffstage: false), findsNothing);
    expect(generated, 1);

    rootKey.currentState!.pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNotNull,
    );
  });
}
