import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart' as platform;
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
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';

import '../../sample_data/theme_json.dart';
import '../../wallets/support/xelis_test_fakes.dart';

void main() {
  for (final desktop in [false, true]) {
    for (final size in <int?>[100, 0, -1, null]) {
      testWidgets('confirmation fee rate desktop=$desktop size=$size', (
        tester,
      ) async {
        final previousPlatform = Util.layoutPlatform;
        final previousWidth = Util.screenWidth;
        final previousIpad = Util.isIpad;
        final previousThemes = StackFileSystem.themesDir;
        Util.layoutPlatform = platform.FakePlatform(
          operatingSystem: desktop ? 'macos' : 'android',
        );
        Util.screenWidth = null;
        Util.isIpad = false;
        StackFileSystem.themesDir = Directory('test/sample_data').absolute;
        tester.view.physicalSize = const Size(1400, 1800);
        tester.view.devicePixelRatio = 1;
        addTearDown(() {
          Util.layoutPlatform = previousPlatform;
          Util.screenWidth = previousWidth;
          Util.isIpad = previousIpad;
          StackFileSystem.themesDir = previousThemes;
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        final wallet = TestWallet(FakeNative());
        final coin = wallet.cryptoCurrency;
        final amount = Amount(rawValue: BigInt.from(1000), fractionDigits: 8);
        final theme = StackTheme.fromJson(json: lightThemeJsonMap);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              pWallets.overrideWithValue(ConfirmationWallets(wallet)),
              pWalletCoin('review-test').overrideWithValue(coin),
              prefsChangeNotifierProvider.overrideWithValue(
                ConfirmationPrefs(),
              ),
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
                  walletId: 'review-test',
                  onSuccess: () {},
                  txData: TxData(
                    note: '',
                    noteOnChain: '',
                    fee: Amount(rawValue: BigInt.from(125), fractionDigits: 8),
                    vSize: size,
                    recipients: [
                      TxRecipient(
                        address: 'destination',
                        amount: amount,
                        isChange: false,
                        addressType: AddressType.xelis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final rate = find.byWidgetPredicate(
          (widget) => widget is SelectableText && widget.data == '~1.3',
        );
        expect(rate, size == 100 ? findsOneWidget : findsNothing);
        expect(
          find.text('sats/vByte'),
          size == 100 ? findsOneWidget : findsNothing,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
