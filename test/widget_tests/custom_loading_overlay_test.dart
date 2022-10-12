import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/theme/light_colors.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_loading_overlay.dart';

void main() {
  testWidgets("Test wiget displays correct text", (widgetTester) async {
    const customLoadingOverlay =
        CustomLoadingOverlay(message: "Updating exchange rate", eventBus: null);
    await widgetTester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            StackColors.fromStackColorTheme(LightColors()),
          ],
        ),
        home: const Material(
          child: customLoadingOverlay,
        ),
      ),
    );

    expect(find.text("Updating exchange rate"), findsOneWidget);
  });
}
