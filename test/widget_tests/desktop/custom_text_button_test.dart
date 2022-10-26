import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/theme/light_colors.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/desktop/custom_text_button.dart';

void main() {
  testWidgets("Test text button ", (widgetTester) async {
    final key = UniqueKey();

    await widgetTester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            StackColors.fromStackColorTheme(LightColors()),
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
