import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/theme/light_colors.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/progress_bar.dart';
// import 'package:stackwallet/widgets/animated_text.dart';

void main() {
  testWidgets("Widget build", (widgetTester) async {
    await widgetTester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            StackColors.fromStackColorTheme(LightColors()),
          ],
        ),
        home: Material(
          child: ProgressBar(
              width: 20,
              height: 10,
              fillColor:
                  StackColors.fromStackColorTheme(LightColors()).accentColorRed,
              backgroundColor: StackColors.fromStackColorTheme(LightColors())
                  .accentColorYellow,
              percent: 30),
        ),
      ),
    );

    // expect(find.text("Calculating"), findsOneWidget);
    expect(find.byType(ProgressBar), findsOneWidget);
  });
}
