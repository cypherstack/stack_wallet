import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:stackwallet/models/isar/stack_theme.dart";
import "package:stackwallet/themes/stack_colors.dart";
import "package:stackwallet/widgets/textfields/adaptive_text_field.dart";
import "package:stackwallet/widgets/textfield_icon_button.dart";

import "../sample_data/theme_json.dart";

void main() {
  testWidgets("paste trims whitespace and runs input formatters", (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == "Clipboard.getData") {
        return <String, dynamic>{"text": " 12x3 "};
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            StackColors.fromStackColorTheme(
              StackTheme.fromJson(json: lightThemeJsonMap),
            ),
          ],
        ),
        home: Scaffold(
          body: AdaptiveTextField(
            controller: controller,
            showPasteClearButton: true,
            inputFormatters: [
              TextInputFormatter.withFunction((oldValue, newValue) {
                final text = "[${newValue.text}]";
                return TextEditingValue(
                  text: text,
                  selection: TextSelection.collapsed(offset: text.length),
                );
              }),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextFieldIconButton));
    await tester.pump();

    expect(controller.text, "[12x3]");
  });
}
