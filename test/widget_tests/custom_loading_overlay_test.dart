import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/sw_theme.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/defaults/dark.dart';
import 'package:stackwallet/widgets/custom_loading_overlay.dart';

void main() {
  testWidgets("Test wiget displays correct text", (widgetTester) async {
    final eventBus = EventBus();
    await widgetTester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            StackColors.fromStackColorTheme(
              StackTheme.fromJson(
                json: darkJson,
                applicationThemesDirectoryPath: "",
              ),
            ),
          ],
        ),
        home: Material(
          child: CustomLoadingOverlay(
              message: "Updating exchange rate", eventBus: eventBus),
        ),
      ),
    );

    expect(find.text("Updating exchange rate"), findsOneWidget);
  });
}
