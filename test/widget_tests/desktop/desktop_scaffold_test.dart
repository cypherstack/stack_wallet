import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/theme/light_colors.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';

void main() {
  testWidgets("test DesktopScaffold", (widgetTester) async {
    final key = UniqueKey();
    await widgetTester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            StackColors.fromStackColorTheme(LightColors()),
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
            StackColors.fromStackColorTheme(LightColors()),
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
            StackColors.fromStackColorTheme(LightColors()),
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
