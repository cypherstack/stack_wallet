import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epicmobile/pages_desktop_specific/home/my_stack_view/exit_to_my_stack_button.dart';
import 'package:epicmobile/utilities/theme/light_colors.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicmobile/widgets/desktop/desktop_app_bar.dart';

void main() {
  testWidgets("Test DesktopAppBar widget", (widgetTester) async {
    final key = UniqueKey();

    await widgetTester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            StackColors.fromStackColorTheme(LightColors()),
          ],
        ),
        home: Material(
          child: DesktopAppBar(
            key: key,
            isCompactHeight: false,
            leading: const AppBarBackButton(),
            trailing: const ExitToMyStackButton(),
            center: const Text("Some Text"),
          ),
        ),
      ),
    );

    expect(find.byType(DesktopAppBar), findsOneWidget);
  });
}
