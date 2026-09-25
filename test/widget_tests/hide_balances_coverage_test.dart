import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/wallet_view/sub_widgets/wallet_balance_toggle_sheet.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/themes/coin_icon_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/amount/amount_formatter.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';
import 'package:stackwallet/widgets/hideable_balance.dart';
import 'package:stackwallet/widgets/managed_favorite.dart';
import 'package:stackwallet/widgets/wallet_info_row/sub_widgets/wallet_info_row_balance.dart';

import '../sample_data/theme_json.dart';

void main() {
  const walletId = "some-wallet-id";
  final coin = Bitcoin(CryptoCurrencyNetwork.main);

  final total = Amount(
    rawValue: BigInt.from(123456789),
    fractionDigits: coin.fractionDigits,
  );

  final formatter = AmountFormatter(
    unit: AmountUnit.normal,
    locale: "en_US",
    coin: coin,
    maxDecimals: 8,
  );

  final formatted = formatter.format(total);

  final balance = Balance(
    total: total,
    spendable: total,
    blockedTotal: Amount.zeroWith(fractionDigits: coin.fractionDigits),
    pendingSpendable: total,
  );

  final theme = StackTheme.fromJson(json: lightThemeJsonMap);

  Widget app({required bool hidden, required Widget child}) {
    return ProviderScope(
      overrides: [
        hideBalancesProvider.overrideWithValue(hidden),
        pAmountFormatter(coin).overrideWithValue(formatter),
        themeProvider.overrideWithProvider(StateProvider((_) => theme)),
        coinIconProvider.overrideWithProvider(
          (_) => Provider<String>(
            (_) =>
                "${Directory.current.path}/test/sample_data/light/assets/dummy.svg",
          ),
        ),
        pWalletInfo(walletId).overrideWithValue(
          WalletInfo(
            walletId: walletId,
            name: "some wallet",
            mainAddressType: AddressType.p2wpkh,
            coinName: coin.identifier,
            cachedBalanceString: balance.toJsonIgnoreCoin(),
          ),
        ),
        pWalletName(walletId).overrideWithValue("some wallet"),
        pWalletCoin(walletId).overrideWithValue(coin),
        pWalletBalance(walletId).overrideWithValue(balance),
        pWalletIsFavourite(walletId).overrideWithValue(false),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: [StackColors.fromStackColorTheme(theme)]),
        home: Scaffold(body: child),
      ),
    );
  }

  Future<void> expectMasking(
    WidgetTester tester,
    Widget Function() build,
    Finder balance,
  ) async {
    await tester.pumpWidget(app(hidden: true, child: build()));
    await tester.pump();
    expect(balance, findsNothing);
    expect(find.byType(HideableBalance), findsWidgets);

    await tester.pumpWidget(app(hidden: false, child: build()));
    await tester.pump();
    expect(balance, findsWidgets);
  }

  testWidgets("wallet list rows mask their balance", (tester) async {
    await expectMasking(
      tester,
      () => const WalletInfoRowBalance(walletId: walletId),
      find.text(formatted),
    );
  });

  testWidgets("the balance toggle sheet masks its balances", (tester) async {
    await expectMasking(
      tester,
      () => BalanceSelector<int>(
        title: "Available balance",
        coin: coin,
        balance: total,
        onPressed: () {},
        onChanged: (_) {},
        value: 0,
        groupValue: 0,
      ),
      find.text(formatted),
    );
  });

  testWidgets("manage favorites masks wallet balances", (tester) async {
    await expectMasking(
      tester,
      () => const ManagedFavorite(walletId: walletId),
      find.text(formatted),
    );
  });
}
