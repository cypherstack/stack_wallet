import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/send_view/confirm_transaction_view.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/amount/amount_formatter.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';

import '../../sample_data/theme_json.dart';
import '../../wallets/support/xelis_test_fakes.dart';

void main() {
  for (final (replacePreparation, sendAll, cancelAuthentication) in [
    (false, false, false),
    (true, false, false),
    (false, true, false),
    (false, false, true),
    (false, true, true),
  ]) {
    final reviewAction = replacePreparation
        ? 'preserves a newer preparation'
        : 'discards its preparation';
    testWidgets('closing Xelis ${sendAll ? 'maximum' : 'ordinary'} review '
        '$reviewAction (cancel auth: $cancelAuthentication)', (tester) async {
      tester.view.resetPhysicalSize();
      tester.view.physicalSize = const Size(1400, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final previousThemesDir = StackFileSystem.themesDir;
      addTearDown(() => StackFileSystem.themesDir = previousThemesDir);
      StackFileSystem.themesDir = Directory('test/sample_data').absolute;
      final native = FakeNative();
      final wallet = TestWallet(native);
      final coin = wallet.cryptoCurrency;
      final request = TxData(
        xelisSendAll: sendAll,
        recipients: [
          TxRecipient(
            address: 'integrated-destination',
            amount: Amount(rawValue: BigInt.from(100), fractionDigits: 8),
            isChange: false,
            addressType: AddressType.xelis,
          ),
        ],
      );
      final reviewed = await wallet.prepareSend(txData: request);
      final theme = StackTheme.fromJson(json: lightThemeJsonMap);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pWallets.overrideWithValue(ConfirmationWallets(wallet)),
            pWalletCoin('review-test').overrideWithValue(coin),
            prefsChangeNotifierProvider.overrideWithValue(ConfirmationPrefs()),
            themeProvider.overrideWithProvider(StateProvider((ref) => theme)),
            pAmountFormatter(coin).overrideWithValue(
              AmountFormatter(
                unit: AmountUnit.normal,
                locale: 'en_US',
                coin: coin,
                maxDecimals: 8,
              ),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(
              extensions: [StackColors.fromStackColorTheme(theme)],
            ),
            home: Scaffold(
              body: ConfirmTransactionView(
                txData: reviewed,
                walletId: 'review-test',
                onSuccess: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Send'), findsOneWidget);
      final expectedAmount = sendAll ? '0.00000093' : '0.00000100';
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is SelectableText &&
              widget.data == '$expectedAmount ${coin.ticker}',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is SelectableText &&
              widget.data == '0.00000007 ${coin.ticker}',
        ),
        findsOneWidget,
      );
      expect(native.usedMax, sendAll);
      expect(native.broadcast, isEmpty);
      if (cancelAuthentication) {
        await tester.ensureVisible(find.text('Send'));
        await tester.tap(find.text('Send'));
        await tester.pumpAndSettle();
        expect(find.text('Confirm transaction'), findsOneWidget);
        expect(native.broadcast, isEmpty);
        expect(native.discarded, isEmpty);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.text('Confirm transaction'), findsNothing);
        expect(find.byType(ConfirmTransactionView), findsOneWidget);
        expect(native.broadcast, isEmpty);
        expect(native.discarded, isEmpty);
      }
      final newer = replacePreparation
          ? await wallet.prepareSend(txData: request)
          : null;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(native.discarded, [reviewed.xelisPreparedTransaction]);
      expect(native.broadcast, isEmpty);
      if (newer != null) {
        await wallet.confirmSend(txData: newer);
        expect(native.broadcast, [newer.xelisPreparedTransaction]);
      } else {
        await expectLater(
          wallet.confirmSend(txData: reviewed),
          throwsStateError,
        );
      }
    });
  }
}
