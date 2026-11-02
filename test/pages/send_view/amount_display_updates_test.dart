import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart' as platform;
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/send_view/send_view.dart';
import 'package:stackwallet/pages/salvium_stake/salvium_create_stake_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_send.dart';
import 'package:stackwallet/providers/global/locale_provider.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/providers/ui/preview_tx_button_state_provider.dart';
import 'package:stackwallet/services/locale_service.dart';
import 'package:stackwallet/themes/coin_icon_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';

import '../../sample_data/theme_json.dart';
import '../../wallets/support/xelis_test_fakes.dart';

class _Locale extends LocaleService {
  String value = 'en_US';
  @override
  String get locale => value;
  void change(String next) {
    value = next;
    notifyListeners();
  }
}

class _Prefs extends ConfirmationPrefs {
  @override
  bool get enableCoinControl => false;
  AmountUnit selectedUnit = AmountUnit.normal;
  @override
  AmountUnit amountUnit(CryptoCurrency coin) => selectedUnit;
  @override
  int maxDecimals(CryptoCurrency coin) => coin.fractionDigits;
  void changeUnit(AmountUnit next) {
    selectedUnit = next;
    notifyListeners();
  }
}

void main() {
  const walletId = 'provider-audit-wallet';
  void setupLayout(WidgetTester tester, bool desktop) {
    final oldPlatform = Util.layoutPlatform;
    final oldThemesDir = StackFileSystem.themesDir;
    Util.layoutPlatform = platform.FakePlatform(
      operatingSystem: desktop ? 'linux' : 'android',
    );
    StackFileSystem.themesDir = Directory('test/sample_data').absolute;
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      Util.layoutPlatform = oldPlatform;
      StackFileSystem.themesDir = oldThemesDir;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Future<void> pump(
    WidgetTester tester,
    ProviderContainer container,
    Widget child,
  ) async {
    final theme = StackTheme.fromJson(json: lightThemeJsonMap);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData(
            extensions: [StackColors.fromStackColorTheme(theme)],
          ),
          home: Util.isDesktop
              ? Scaffold(body: SingleChildScrollView(child: child))
              : child,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  for (final desktop in [false, true]) {
    testWidgets('normal send preserves amount on locale change ($desktop)', (
      tester,
    ) async {
      setupLayout(tester, desktop);
      final wallet = TestWallet(FakeNative());
      final coin = wallet.cryptoCurrency;
      final info = WalletInfo(
        walletId: walletId,
        name: 'Audit wallet',
        mainAddressType: AddressType.xelis,
        coinName: coin.identifier,
      );
      final locale = _Locale();
      final prefs = _Prefs();
      final theme = StackTheme.fromJson(json: lightThemeJsonMap);
      final container = ProviderContainer(
        overrides: [
          pWallets.overrideWithValue(ConfirmationWallets(wallet)),
          pWalletInfo(walletId).overrideWithValue(info),
          pWalletCoin(walletId).overrideWithValue(coin),
          pWalletName(walletId).overrideWithValue(info.name),
          pWalletBalance(walletId)
              .overrideWithValue(Balance.zeroFor(currency: coin)),
          prefsChangeNotifierProvider.overrideWithValue(prefs),
          localeServiceChangeNotifierProvider.overrideWithValue(locale),
          themeProvider.overrideWithProvider(StateProvider((ref) => theme)),
          coinIconProvider(coin).overrideWithValue(
            File('test/sample_data/light/assets/dummy.svg').absolute.path,
          ),
        ],
      );
      addTearDown(container.dispose);
      await pump(
        tester,
        container,
        desktop
            ? const DesktopSend(walletId: walletId)
            : SendView(walletId: walletId, coin: coin),
      );
      final field = find.byKey(const Key('amountInputFieldCryptoTextFieldKey'));
      await tester.enterText(field, '1.25');
      await tester.pump(const Duration(milliseconds: 600));
      final expected = container.read(pSendAmount);
      expect(
        expected,
        Amount(
          rawValue: BigInt.from(125000000),
          fractionDigits: coin.fractionDigits,
        ),
      );
      locale.change('de_DE');
      await tester.pump(const Duration(milliseconds: 600));
      final actual = container.read(pSendAmount);
      final text = tester.widget<TextField>(field).controller!.text;
      expect(text, '1,25');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(
        actual,
        expected,
        reason: 'Locale change must preserve the canonical send amount',
      );
    });
    testWidgets('Salvium stake keeps amount and unit consistent ($desktop)', (
      tester,
    ) async {
      setupLayout(tester, desktop);
      final coin = Salvium(CryptoCurrencyNetwork.main);
      final prefs = _Prefs();
      final container = ProviderContainer(
        overrides: [
          pWalletCoin(walletId).overrideWithValue(coin),
          themeProvider.overrideWithProvider(
            StateProvider(
              (ref) => StackTheme.fromJson(json: lightThemeJsonMap),
            ),
          ),
          prefsChangeNotifierProvider.overrideWithValue(prefs),
          localeServiceChangeNotifierProvider.overrideWithValue(_Locale()),
        ],
      );
      addTearDown(container.dispose);
      await pump(
        tester,
        container,
        const SalviumCreateStakeView(walletId: walletId),
      );
      final field = find.byType(TextField).first;
      await tester.enterText(field, '1.25');
      await tester.pump();
      prefs.changeUnit(AmountUnit.milli);
      await tester.pump();
      final text = tester.widget<TextField>(field).controller!.text;
      final preview = find.widgetWithText(PrimaryButton, 'Preview');
      expect(tester.widget<PrimaryButton>(preview).enabled, true);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(text, '1250', reason: '1.25 SAL must display as 1250 mSAL');
    });
    testWidgets('Salvium stake preserves amount on locale change ($desktop)', (
      tester,
    ) async {
      setupLayout(tester, desktop);
      final coin = Salvium(CryptoCurrencyNetwork.main);
      final locale = _Locale();
      final container = ProviderContainer(
        overrides: [
          pWalletCoin(walletId).overrideWithValue(coin),
          themeProvider.overrideWithProvider(
            StateProvider(
              (ref) => StackTheme.fromJson(json: lightThemeJsonMap),
            ),
          ),
          prefsChangeNotifierProvider.overrideWithValue(_Prefs()),
          localeServiceChangeNotifierProvider.overrideWithValue(locale),
        ],
      );
      addTearDown(container.dispose);
      await pump(
        tester,
        container,
        const SalviumCreateStakeView(walletId: walletId),
      );
      final field = find.byType(TextField).first;
      await tester.enterText(field, '1.25');
      await tester.pump();
      final preview = find.widgetWithText(PrimaryButton, 'Preview');
      expect(tester.widget<PrimaryButton>(preview).enabled, true);
      locale.change('de_DE');
      await tester.pump();
      final enabled = tester.widget<PrimaryButton>(preview).enabled;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(
        enabled,
        true,
        reason: 'Relocalizing the stake must preserve the valid amount',
      );
    });
  }
}
