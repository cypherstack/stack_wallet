import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epicmobile/utilities/theme/light_colors.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/shake/shake.dart';

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
          child: Shake(
              animationRange: 10,
              controller: ShakeController(),
              animationDuration: const Duration(milliseconds: 200),
              child: Column(
                children: const [
                  Center(
                    child: Text("Enter Pin"),
                  )
                ],
              )),
        ),
      ),
    );

    expect(find.byType(Shake), findsOneWidget);
    expect(find.byType(Text), findsOneWidget);
  });
}
