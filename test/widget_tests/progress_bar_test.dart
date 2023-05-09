import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/sw_theme.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/defaults/dark.dart';
import 'package:stackwallet/widgets/progress_bar.dart';

void main() {
  testWidgets("Widget build", (widgetTester) async {
    final theme = StackTheme.fromJson(
      json: darkJson,
      applicationThemesDirectoryPath: "",
    );
    await widgetTester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            StackColors.fromStackColorTheme(theme),
          ],
        ),
        home: Material(
          child: ProgressBar(
              width: 20,
              height: 10,
              fillColor: StackColors.fromStackColorTheme(theme).accentColorRed,
              backgroundColor:
                  StackColors.fromStackColorTheme(theme).accentColorYellow,
              percent: 30),
        ),
      ),
    );

    expect(find.byType(ProgressBar), findsOneWidget);
  });
}
