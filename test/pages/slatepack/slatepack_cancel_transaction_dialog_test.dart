import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/slatepack/slatepack_cancel_transaction_dialog.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';

import '../../sample_data/theme_json.dart';

void main() {
  for (final width in [320.0, 375.0, 412.0]) {
    testWidgets('cancel confirmation fits at ${width.toInt()} dp', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final previousWidth = Util.screenWidth;
      Util.screenWidth = width;
      addTearDown(() => Util.screenWidth = previousWidth);

      final theme = StackTheme.fromJson(json: lightThemeJsonMap);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [StackColors.fromStackColorTheme(theme)],
          ),
          home: const SlatepackCancelTransactionDialog(),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Cancel transaction'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
