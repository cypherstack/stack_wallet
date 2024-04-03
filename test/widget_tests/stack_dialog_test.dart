import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

import '../sample_data/theme_json.dart';

void main() {
  testWidgets("test StackDialogBase", (widgetTester) async {
    await widgetTester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            StackColors.fromStackColorTheme(
              StackTheme.fromJson(
                json: lightThemeJsonMap,
              ),
            ),
          ],
        ),
        home: const Material(
          child: StackDialogBase(),
        ),
      ),
    );

    expect(find.byType(StackDialogBase), findsOneWidget);
  });

  testWidgets("test StackDialog", (widgetTester) async {
    await widgetTester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            StackColors.fromStackColorTheme(
              StackTheme.fromJson(
                json: lightThemeJsonMap,
              ),
            ),
          ],
        ),
        home: const Material(
          child: StackDialog(
            title: "Some Dialog title",
            message: "Some Message",
            leftButton: TextButton(onPressed: null, child: Text("Left Button")),
            rightButton:
                TextButton(onPressed: null, child: Text("Right Button")),
          ),
        ),
      ),
    );

    expect(find.byType(StackDialogBase), findsOneWidget);
    expect(find.byType(StackDialog), findsOneWidget);
    expect(find.text("Some Dialog title"), findsOneWidget);
    expect(find.text("Some Message"), findsOneWidget);
    expect(find.text("Left Button"), findsOneWidget);
    expect(find.text("Right Button"), findsOneWidget);
  });

  testWidgets("Test StackDialogOk", (widgetTester) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await widgetTester.pumpWidget(
      ProviderScope(
        overrides: [],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(
                StackTheme.fromJson(
                  json: lightThemeJsonMap,
                ),
              ),
            ],
          ),
          home: StackOkDialog(
            title: "Some random title",
            message: "Some message",
            leftButton: TextButton(
              onPressed: () {},
              child: const Text("I am left"),
            ),
          ),
        ),
      ),
    );

    final button = find.text('I am left');
    await widgetTester.tap(button);
    await widgetTester.pumpAndSettle();

    final navigatorState = navigatorKey.currentState;
    expect(navigatorState?.overlay, isNotNull);
  });
}
