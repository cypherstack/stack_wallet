import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/exceptions/electrumx/broadcast_outcome_unknown.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/send_view/confirm_transaction_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_auth_send.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/amount/amount_formatter.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';

import '../../sample_data/theme_json.dart';
import '../../wallets/support/xelis_test_fakes.dart';

class _WalletInfo extends Fake implements WalletInfo {
  @override
  CryptoCurrency get coin => Bitcoin(CryptoCurrencyNetwork.main);
}

class _Wallet extends Fake implements Wallet {
  int attempts = 0;
  @override
  WalletInfo get info => _WalletInfo();
  @override
  CryptoCurrency get cryptoCurrency => info.coin;
  @override
  Future<TxData> confirmSend({required TxData txData}) async {
    attempts++;
    throw BroadcastOutcomeUnknown(
      txid: 'expected-transaction-id',
      cause: TimeoutException('lost reply'),
    );
  }

  @override
  Future<void> cancelSend({required TxData txData}) async {}
}

void main() {
  testWidgets(
    'uncertain Electrum send shows its ID, avoids success, and disables resubmission',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final previousThemesDir = StackFileSystem.themesDir;
      addTearDown(() => StackFileSystem.themesDir = previousThemesDir);
      StackFileSystem.themesDir = Directory('test/sample_data').absolute;
      final wallet = _Wallet();
      final coin = wallet.cryptoCurrency;
      final theme = StackTheme.fromJson(json: lightThemeJsonMap);
      var succeeded = false;
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
                txData: TxData(
                  fee: Amount(rawValue: BigInt.from(7), fractionDigits: 8),
                  recipients: [
                    TxRecipient(
                      address: 'recipient',
                      amount: Amount(
                        rawValue: BigInt.from(100),
                        fractionDigits: 8,
                      ),
                      isChange: false,
                      addressType: AddressType.p2pkh,
                    ),
                  ],
                ),
                walletId: 'review-test',
                onSuccess: () => succeeded = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Send'));
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      // Complete the authentication route, then exercise the real send/error UI.
      Navigator.of(tester.element(find.byType(DesktopAuthSend))).pop(true);
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(BroadcastOutcomeUnknown.title), findsOneWidget);
      expect(
        find.textContaining('Transaction ID: expected-transaction-id'),
        findsOneWidget,
      );
      expect(find.text('Broadcast transaction failed'), findsNothing);
      expect(succeeded, isFalse);
      expect(wallet.attempts, 1);
      await tester.tap(find.text('Ok'));
      await tester.pumpAndSettle();
      final send = tester.widget<PrimaryButton>(
        find.byWidgetPredicate(
          (widget) => widget is PrimaryButton && widget.label == 'Send',
        ),
      );
      expect(send.enabled, isFalse);
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(wallet.attempts, 1);
      expect(find.byType(DesktopAuthSend), findsNothing);
    },
  );
}
