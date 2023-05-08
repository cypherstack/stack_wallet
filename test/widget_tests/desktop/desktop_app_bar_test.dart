import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/sw_theme.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/exit_to_my_stack_button.dart';
import 'package:stackwallet/themes/defaults/dark.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';

void main() {
  testWidgets("Test DesktopAppBar widget", (widgetTester) async {
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
