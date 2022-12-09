import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:epicmobile/utilities/theme/light_colors.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicmobile/widgets/desktop/desktop_dialog_close_button.dart';

void main() {
  testWidgets("test DesktopDialog button pressed", (widgetTester) async {
    final key = UniqueKey();

    final navigator = mockingjay.MockNavigator();

    await widgetTester.pumpWidget(
      ProviderScope(
        overrides: [],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(LightColors()),
            ],
          ),
          home: mockingjay.MockNavigatorProvider(
              navigator: navigator,
              child: DesktopDialogCloseButton(
                key: key,
                onPressedOverride: null,
              )),
        ),
      ),
    );

    await widgetTester.tap(find.byType(AppBarIconButton));
    await widgetTester.pumpAndSettle();

    mockingjay.verify(() => navigator.pop()).called(1);
  });
}
