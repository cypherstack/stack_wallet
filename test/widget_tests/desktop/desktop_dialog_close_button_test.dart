import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';

import '../../sample_data/theme_json.dart';

void main() {
  testWidgets("test DesktopDialog button pressed", (widgetTester) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await widgetTester.pumpWidget(
      ProviderScope(
        overrides: [],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(
                StackTheme.fromJson(
                  json: lightThemeJsonMap,
                ),
              ),
            ],
          ),
          home: DesktopDialogCloseButton(
            key: UniqueKey(),
            onPressedOverride: null,
          ),
        ),
      ),
    );

    final button = find.byType(AppBarIconButton);
    await widgetTester.tap(button);
    await widgetTester.pumpAndSettle();

    final navigatorState = navigatorKey.currentState;
    expect(navigatorState?.overlay, isNotNull);
  });
}
