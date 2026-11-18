import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart' as platform;
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
      final previousPlatform = Util.layoutPlatform;
      Util.layoutPlatform = platform.FakePlatform(operatingSystem: 'android');
      addTearDown(() => Util.layoutPlatform = previousPlatform);
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
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.15)),
            child: child!,
          ),
          home: const SlatepackCancelTransactionDialog(),
        ),
      );

      expect(find.text('Go back'), findsOneWidget);
      expect(find.text('Cancel it'), findsOneWidget);
      expect(find.text('Cancel transaction'), findsNothing);
      expect(
        find.textContaining('may not prevent another party'),
        findsOneWidget,
      );
      expect(find.textContaining('can no longer complete'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('cancel confirmation returns the selected action', (
    tester,
  ) async {
    final theme = StackTheme.fromJson(json: lightThemeJsonMap);
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [StackColors.fromStackColorTheme(theme)]),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDialog<bool>(
                context: context,
                builder: (_) => const SlatepackCancelTransactionDialog(),
              );
            },
            child: const Text('Show'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go back'));
    await tester.pumpAndSettle();
    expect(result, isFalse);

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel it'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
