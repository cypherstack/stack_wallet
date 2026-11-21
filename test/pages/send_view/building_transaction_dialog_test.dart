import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/send_view/sub_widgets/building_transaction_dialog.dart';
import 'package:stackwallet/themes/coin_image_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';

import '../../sample_data/theme_json.dart';

void main() {
  for (final isDesktop in [false, true]) {
    testWidgets(
      'cancel dismisses only the ${isDesktop ? 'desktop' : 'mobile'} dialog',
      (tester) async {
        Util.screenWidth = isDesktop ? null : 400;
        addTearDown(() => Util.screenWidth = null);

        var cancelCount = 0;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              coinImageSecondaryProvider.overrideWithProvider(
                (_) => Provider((_) => 'coin.svg'),
              ),
            ],
            child: MaterialApp(
              theme: ThemeData(
                extensions: [
                  StackColors.fromStackColorTheme(
                    StackTheme.fromJson(json: lightThemeJsonMap),
                  ),
                ],
              ),
              home: _RootPage(
                isDesktop: isDesktop,
                onCancel: () => cancelCount++,
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open caller'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Build transaction'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(cancelCount, 1);
        expect(find.byKey(const Key('caller page')), findsOneWidget);
        expect(find.text('Generating transaction'), findsNothing);
        expect(
          tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
          isTrue,
        );
      },
    );
  }
}

class _RootPage extends StatelessWidget {
  const _RootPage({required this.isDesktop, required this.onCancel});

  final bool isDesktop;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TextButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                _CallerPage(isDesktop: isDesktop, onCancel: onCancel),
          ),
        ),
        child: const Text('Open caller'),
      ),
    );
  }
}

class _CallerPage extends StatelessWidget {
  const _CallerPage({required this.isDesktop, required this.onCancel});

  final bool isDesktop;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('caller page'),
      body: TextButton(
        onPressed: () => showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            final child = BuildingTransactionDialog(
              coin: Bitcoin(CryptoCurrencyNetwork.main),
              isSpark: false,
              onCancel: () {
                onCancel();
                Navigator.of(dialogContext).pop();
              },
            );

            return isDesktop ? DesktopDialog(child: child) : child;
          },
        ),
        child: const Text('Build transaction'),
      ),
    );
  }
}
