import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/theme/light_colors.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:mockingjay/mockingjay.dart' as mockingjay;

void main() {
  testWidgets("test StackDialogBase", (widgetTester) async {
    await widgetTester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            StackColors.fromStackColorTheme(LightColors()),
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
            StackColors.fromStackColorTheme(LightColors()),
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
    final navigator = mockingjay.MockNavigator();

    await widgetTester.pumpWidget(ProviderScope(
        overrides: [],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(LightColors()),
            ],
          ),
          home: mockingjay.MockNavigatorProvider(
            navigator: navigator,
            child: const StackOkDialog(
              title: "Some random title",
              message: "Some message",
              leftButton: TextButton(onPressed: null, child: Text("I am left")),
            ),
          ),
        )));
    await widgetTester.pumpAndSettle();

    expect(find.byType(StackOkDialog), findsOneWidget);
    expect(find.text("Some random title"), findsOneWidget);
    expect(find.text("Some message"), findsOneWidget);
    expect(find.byType(TextButton), findsNWidgets(2));

    await widgetTester.tap(find.text("I am left"));
    await widgetTester.pumpAndSettle();
  });
}
