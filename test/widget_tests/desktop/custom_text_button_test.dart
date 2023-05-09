import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/sw_theme.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/defaults/dark.dart';
import 'package:stackwallet/widgets/desktop/custom_text_button.dart';

void main() {
  testWidgets("Test text button ", (widgetTester) async {
    final key = UniqueKey();

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
          child: CustomTextButtonBase(
            key: key,
            width: 200,
            height: 300,
            textButton:
                const TextButton(onPressed: null, child: Text("Some Text")),
          ),
        ),
      ),
    );

    expect(find.byType(CustomTextButtonBase), findsOneWidget);
  });
}
