import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/dialogs/basic_dialog.dart';

import '../sample_data/theme_json.dart';
import 'helpers/navigation_test_helpers.dart';

void main() {
  final navigatorKey = GlobalKey<NavigatorState>();

  setUp(() {
    Util.screenWidth = 400;
  });

  tearDown(() {
    Util.screenWidth = null;
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        theme: ThemeData(
          extensions: [
            StackColors.fromStackColorTheme(
              StackTheme.fromJson(json: lightThemeJsonMap),
            ),
          ],
        ),
        home: const Scaffold(body: Text("Home")),
      ),
    );
  }

  Future<void> pushDialog(WidgetTester tester, {required bool canPop}) async {
    unawaited(
      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) =>
              BasicDialog(title: "Dialog", canPopWithBackButton: canPop),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets("blocks back navigation when disabled", (tester) async {
    await pumpApp(tester);
    await pushDialog(tester, canPop: false);

    await simulateSystemBack();
    await tester.pumpAndSettle();

    expect(find.text("Dialog"), findsOneWidget);

    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();

    expect(find.text("Dialog"), findsNothing);
  }, variant: TargetPlatformVariant.all());

  testWidgets("allows back navigation when enabled", (tester) async {
    await pumpApp(tester);
    await pushDialog(tester, canPop: true);

    await simulateSystemBack();
    await tester.pumpAndSettle();

    expect(find.text("Dialog"), findsNothing);
    expect(find.text("Home"), findsOneWidget);
  }, variant: TargetPlatformVariant.all());
}
