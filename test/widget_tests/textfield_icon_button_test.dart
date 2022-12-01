import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epicmobile/utilities/theme/light_colors.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/icon_widgets/x_icon.dart';
import 'package:epicmobile/widgets/textfield_icon_button.dart';

void main() {
  testWidgets("test", (widgetTester) async {
    await widgetTester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            StackColors.fromStackColorTheme(LightColors()),
          ],
        ),
        home: const Material(
          child: TextFieldIconButton(child: XIcon()),
        ),
      ),
    );

    expect(find.byType(TextFieldIconButton), findsOneWidget);
    expect(find.byType(XIcon), findsOneWidget);
  });
}
