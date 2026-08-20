import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/add_wallet_views/restore_wallet_view/sub_widgets/mnemonic_word_count_select_sheet.dart';
import 'package:stackwallet/pages/add_wallet_views/restore_wallet_view/sub_widgets/restoring_dialog.dart';
import 'package:stackwallet/pages/cashfusion/fusion_rounds_selection_sheet.dart';
import 'package:stackwallet/pages/churning/churning_rounds_selection_sheet.dart';
import 'package:stackwallet/providers/ui/verify_recovery_phrase/mnemonic_word_count_state_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';

import '../sample_data/theme_json.dart';
import 'helpers/navigation_test_helpers.dart';

void main() {
  final navigatorKey = GlobalKey<NavigatorState>();

  setUp(() {
    Util.screenWidth = 400;
  });

  tearDown(() {
    Util.screenWidth = null;
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    List<Override> overrides = const <Override>[],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          theme: ThemeData(
            extensions: <ThemeExtension<dynamic>>[
              StackColors.fromStackColorTheme(
                StackTheme.fromJson(json: lightThemeJsonMap),
              ),
            ],
          ),
          home: const Scaffold(body: Text('home')),
        ),
      ),
    );
  }

  Future<T?> push<T>(Widget child) {
    return navigatorKey.currentState!.push<T>(
      MaterialPageRoute<T>(builder: (_) => Material(child: child)),
    );
  }

  testWidgets('mnemonic sheet returns its selection on system back', (
    tester,
  ) async {
    await pumpApp(
      tester,
      overrides: <Override>[
        mnemonicWordCountStateProvider.overrideWithValue(StateController(24)),
      ],
    );
    final result = push<int>(
      const MnemonicWordCountSelectSheet(lengthOptions: <int>[12, 24]),
    );
    await tester.pumpAndSettle();

    await simulateSystemBack();
    await tester.pumpAndSettle();

    await expectLater(result, completion(24));
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('fusion sheet returns its current option on system back', (
    tester,
  ) async {
    await pumpApp(tester);
    final result = push<FusionOption>(
      const FusionRoundCountSelectSheet(currentOption: FusionOption.custom),
    );
    await tester.pumpAndSettle();

    await simulateSystemBack();
    await tester.pumpAndSettle();

    await expectLater(result, completion(FusionOption.custom));
  });

  testWidgets('churning sheet returns its current option on system back', (
    tester,
  ) async {
    await pumpApp(tester);
    final result = push<ChurnOption>(
      const ChurnRoundCountSelectSheet(currentOption: ChurnOption.continuous),
    );
    await tester.pumpAndSettle();

    await simulateSystemBack();
    await tester.pumpAndSettle();

    await expectLater(result, completion(ChurnOption.continuous));
  });

  testWidgets(
    'restoring dialog blocks system back and its button still cancels',
    (tester) async {
      await pumpApp(tester);
      var cancellations = 0;
      unawaited(
        push<void>(
          RestoringDialog(
            onCancel: () async {
              cancellations++;
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await simulateSystemBack();
      await tester.pump();

      expect(find.text('Restoring wallet'), findsOneWidget);
      expect(cancellations, 0);

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(cancellations, 1);
      expect(find.text('Restoring wallet'), findsNothing);
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );
}
