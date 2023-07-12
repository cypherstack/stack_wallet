import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';

import '../../sample_data/theme_json.dart';

void main() {
  testWidgets("AppBarIconButton test", (tester) async {
    int buttonPressedCount = 0;
    final button = AppBarIconButton(
      icon: const Icon(Icons.print),
      onPressed: () => buttonPressedCount++,
      shadows: const [
        BoxShadow(
          color: Colors.green,
          spreadRadius: 1.0,
          blurRadius: 2.0,
        )
      ],
    );

    await tester.pumpWidget(
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
        home: Material(
          child: button,
        ),
      ),
    );

    expect(find.byIcon(Icons.print), findsOneWidget);

    await tester.tap(find.byType(AppBarIconButton));
    await tester.pumpAndSettle();

    expect(buttonPressedCount, 1);
  });
}
