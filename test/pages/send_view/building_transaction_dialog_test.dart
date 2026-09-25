import 'dart:async';

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

Widget _app(Widget home) {
  return ProviderScope(
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
      home: home,
    ),
  );
}

void main() {
  for (final isDesktop in [false, true]) {
    final label = isDesktop ? 'desktop' : 'mobile';

    testWidgets('cancel dismisses only the $label dialog', (tester) async {
      Util.screenWidth = isDesktop ? null : 400;
      addTearDown(() => Util.screenWidth = null);

      var cancelCount = 0;
      await tester.pumpWidget(
        _app(_RootPage(isDesktop: isDesktop, onCancel: () => cancelCount++)),
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
    });

    testWidgets('a build failing after cancel keeps the $label caller route', (
      tester,
    ) async {
      Util.screenWidth = isDesktop ? null : 400;
      addTearDown(() => Util.screenWidth = null);

      final txData = Completer<Object>();
      await tester.pumpWidget(
        _app(_RootPage(isDesktop: isDesktop, txData: txData)),
      );

      await tester.tap(find.text('Open caller'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Build transaction'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Generating transaction'), findsNothing);
      expect(find.byKey(const Key('caller page')), findsOneWidget);

      txData.completeError(Exception('insufficient funds'));
      await tester.pump(const Duration(milliseconds: 2600));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('caller page')), findsOneWidget);
      expect(find.byKey(const Key('failed dialog')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}

class _RootPage extends StatelessWidget {
  const _RootPage({required this.isDesktop, this.onCancel, this.txData});

  final bool isDesktop;
  final VoidCallback? onCancel;
  final Completer<Object>? txData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TextButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => txData == null
                ? _CallerPage(isDesktop: isDesktop, onCancel: onCancel!)
                : _PreviewCallerPage(isDesktop: isDesktop, txData: txData!),
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

/// Mirrors the preview flow shared by the send views, which cannot be pumped
/// directly here because they need live wallet providers.
class _PreviewCallerPage extends StatefulWidget {
  const _PreviewCallerPage({required this.isDesktop, required this.txData});

  final bool isDesktop;
  final Completer<Object> txData;

  @override
  State<_PreviewCallerPage> createState() => _PreviewCallerPageState();
}

class _PreviewCallerPageState extends State<_PreviewCallerPage> {
  bool wasCancelled = false;

  Future<void> _preview() async {
    try {
      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            final child = BuildingTransactionDialog(
              coin: Bitcoin(CryptoCurrencyNetwork.main),
              isSpark: false,
              onCancel: () {
                wasCancelled = true;

                Navigator.of(dialogContext).pop();
              },
            );

            return widget.isDesktop ? DesktopDialog(child: child) : child;
          },
        ),
      );

      final time = Future<dynamic>.delayed(const Duration(milliseconds: 2500));
      final results = await Future.wait([widget.txData.future, time]);

      if (!wasCancelled && mounted) {
        // pop building dialog
        Navigator.of(context, rootNavigator: true).pop();

        unawaited(
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                key: const Key('confirm page'),
                body: Text('${results.first}'),
              ),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted && !wasCancelled) {
        // pop building dialog
        Navigator.of(context, rootNavigator: true).pop();

        unawaited(
          showDialog<void>(
            context: context,
            barrierDismissible: true,
            builder: (dialogContext) => AlertDialog(
              key: const Key('failed dialog'),
              title: const Text('Transaction failed'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Ok'),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('caller page'),
      body: TextButton(
        onPressed: () => unawaited(_preview()),
        child: const Text('Build transaction'),
      ),
    );
  }
}
