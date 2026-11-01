import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/settings_views/wallet_settings_view/wallet_network_settings_view/sub_widgets/rescanning_dialog.dart';
import 'package:stackwallet/themes/stack_colors.dart';

import '../sample_data/theme_json.dart';

void main() {
  testWidgets("marks a background rescan closed before dismissing", (
    tester,
  ) async {
    final theme = StackTheme.fromJson(json: lightThemeJsonMap);
    var closed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [StackColors.fromStackColorTheme(theme)]),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => RescanningDialog(
                rescansInBackground: true,
                onClose: () {
                  expect(find.byType(RescanningDialog), findsOneWidget);
                  closed = true;
                },
              ),
            ),
            child: const Text("Open"),
          ),
        ),
      ),
    );
    await tester.tap(find.text("Open"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    tester
        .widget<TextButton>(find.widgetWithText(TextButton, "Close"))
        .onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(closed, isTrue);
    expect(find.byType(RescanningDialog), findsNothing);
  });
}
