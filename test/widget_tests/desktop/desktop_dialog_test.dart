import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/theme/light_colors.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';

void main() {
  testWidgets("test DesktopDialog builds", (widgetTester) async {
    final key = UniqueKey();

    await widgetTester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            StackColors.fromStackColorTheme(LightColors()),
          ],
        ),
        home: Material(
          child: DesktopDialog(
            key: key,
            child: const DesktopDialogCloseButton(),
          ),
        ),
      ),
    );

    expect(find.byType(DesktopDialog), findsOneWidget);
  });
}
