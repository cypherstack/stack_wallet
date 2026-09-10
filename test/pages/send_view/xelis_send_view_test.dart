import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/send_view/send_view.dart';
import 'package:stackwallet/pages/send_view/sub_widgets/transaction_fee_selection_sheet.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/themes/coin_icon_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/amount/amount_formatter.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';

import '../../sample_data/theme_json.dart';
import '../../wallets/support/xelis_test_fakes.dart';

class SendPrefs extends ConfirmationPrefs {
  @override
  bool get enableCoinControl => false;
  @override
  AmountUnit amountUnit(CryptoCurrency coin) => AmountUnit.normal;
  @override
  int maxDecimals(CryptoCurrency coin) => coin.fractionDigits;
}

void main() {
  testWidgets('Xelis mobile form shows deferred fees without a fee selector', (
    tester,
  ) async {
    // This exercises SendView (the mobile form) on the host test runner.
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final previousThemesDir = StackFileSystem.themesDir;
    addTearDown(() => StackFileSystem.themesDir = previousThemesDir);
    StackFileSystem.themesDir = Directory('test/sample_data').absolute;

    final wallet = TestWallet(FakeNative());
    final coin = wallet.cryptoCurrency;
    const walletId = 'xelis-send-form';
    final info = WalletInfo(
      walletId: walletId,
      name: 'Xelis test wallet',
      mainAddressType: AddressType.xelis,
      coinName: coin.identifier,
    );
    final theme = StackTheme.fromJson(json: lightThemeJsonMap);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pWallets.overrideWithValue(ConfirmationWallets(wallet)),
          pWalletInfo(walletId).overrideWithValue(info),
          pWalletCoin(walletId).overrideWithValue(coin),
          pWalletName(walletId).overrideWithValue(info.name),
          pWalletBalance(walletId)
              .overrideWithValue(Balance.zeroFor(currency: coin)),
          prefsChangeNotifierProvider.overrideWithValue(SendPrefs()),
          themeProvider.overrideWithProvider(StateProvider((ref) => theme)),
          coinIconProvider(coin).overrideWithValue(
            File('test/sample_data/light/assets/dummy.svg').absolute.path,
          ),
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
          home: SendView(walletId: walletId, coin: coin),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final feeLabel = find.text('Calculated when reviewing');
    expect(feeLabel, findsOneWidget);
    expect(find.text('Transaction fee'), findsOneWidget);
    expect(find.text('Transaction fee (estimated)'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('amountInputFieldCryptoTextFieldKey')),
      '0.12345678',
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(feeLabel, findsOneWidget);

    await tester.ensureVisible(feeLabel);
    await tester.tap(feeLabel);
    await tester.pumpAndSettle();
    expect(find.byType(TransactionFeeSelectionSheet), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
