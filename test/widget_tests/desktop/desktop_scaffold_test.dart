import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/sw_theme.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/defaults/dark.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';

void main() {
  testWidgets("test DesktopScaffold", (widgetTester) async {
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
          child: DesktopScaffold(
            key: key,
            body: const SizedBox(),
          ),
        ),
      ),
    );
  });

  testWidgets("Test MasterScaffold for non desktop", (widgetTester) async {
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
          child: MasterScaffold(
            key: key,
            body: const SizedBox(),
            appBar: AppBar(),
            isDesktop: false,
          ),
        ),
      ),
    );
  });

  testWidgets("Test MasterScaffold for desktop", (widgetTester) async {
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
          child: MasterScaffold(
            key: key,
            body: const SizedBox(),
            appBar: AppBar(),
            isDesktop: true,
          ),
        ),
      ),
    );
  });
}
