import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart' as platform;
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/send_view/send_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_send.dart';
import 'package:stackwallet/providers/global/locale_provider.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/price_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/providers/ui/preview_tx_button_state_provider.dart';
import 'package:stackwallet/services/locale_service.dart';
import 'package:stackwallet/services/price_service.dart';
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
import 'package:stackwallet/wallets/models/tx_data.dart';
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
  @override
  bool get externalCalls => true;
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

class _Price extends PriceService {
  _Price() : super('USD');
  @override
  ({Decimal value, double change24h})? getPrice(CryptoCurrency coin) =>
      (value: Decimal.one, change24h: 0);
}

class _ValidXelis extends Xelis {
  _ValidXelis() : super(CryptoCurrencyNetwork.test);
  @override
  bool validateAddress(String address) => address.isNotEmpty;
}

class _CaptureWallet extends TestWallet {
  _CaptureWallet() : super(FakeNative());
  final _coin = _ValidXelis();
  @override
  Xelis get cryptoCurrency => _coin;
  late WalletInfo testInfo;
  TxData? captured;
  @override
  WalletInfo get info => testInfo;
  @override
  Future<TxData> prepareSend({required TxData txData, String? assetId}) async {
    captured = txData;
    throw StateError('captured test transaction');
  }
}

void main() {
  const walletId = 'review-wallet';
  Future<ProviderContainer> mount(
    WidgetTester tester,
    bool desktop,
    _CaptureWallet wallet,
    _Prefs prefs,
    _Locale locale,
  ) async {
    final oldPlatform = Util.layoutPlatform;
    final oldThemes = StackFileSystem.themesDir;
    Util.layoutPlatform = platform.FakePlatform(
      operatingSystem: desktop ? 'linux' : 'android',
    );
    StackFileSystem.themesDir = Directory('test/sample_data').absolute;
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      Util.layoutPlatform = oldPlatform;
      StackFileSystem.themesDir = oldThemes;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final coin = wallet.cryptoCurrency;
    final info = WalletInfo(
      walletId: walletId,
      name: 'Test wallet',
      mainAddressType: AddressType.xelis,
      coinName: coin.identifier,
    );
    wallet.testInfo = info;
    final theme = StackTheme.fromJson(json: lightThemeJsonMap);
    final amount = Amount(
      rawValue: BigInt.from(1000000000),
      fractionDigits: coin.fractionDigits,
    );
    final zero = Amount.zeroWith(fractionDigits: coin.fractionDigits);
    final balance = Balance(
      total: amount,
      spendable: amount,
      blockedTotal: zero,
      pendingSpendable: zero,
    );
    final container = ProviderContainer(
      overrides: [
        pWallets.overrideWithValue(ConfirmationWallets(wallet)),
        pWalletInfo(walletId).overrideWithValue(info),
        pWalletCoin(walletId).overrideWithValue(coin),
        pWalletName(walletId).overrideWithValue(info.name),
        pWalletBalance(walletId).overrideWithValue(balance),
        prefsChangeNotifierProvider.overrideWithValue(prefs),
        localeServiceChangeNotifierProvider.overrideWithValue(locale),
        priceAnd24hChangeNotifierProvider.overrideWithValue(_Price()),
        themeProvider.overrideWithProvider(StateProvider((ref) => theme)),
        coinIconProvider(coin).overrideWithValue(
          File('test/sample_data/light/assets/dummy.svg').absolute.path,
        ),
      ],
    );
    addTearDown(container.dispose);
    final child = desktop
        ? const DesktopSend(walletId: walletId)
        : SendView(walletId: walletId, coin: coin);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData(
            extensions: [StackColors.fromStackColorTheme(theme)],
          ),
          home: desktop
              ? Scaffold(body: SingleChildScrollView(child: child))
              : child,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
    return container;
  }

  for (final desktop in [false, true]) {
    for (final unitFirst in [false, true]) {
      testWidgets(
        'same frame locale and unit desktop=$desktop unitFirst=$unitFirst',
        (tester) async {
          final prefs = _Prefs();
          final locale = _Locale();
          final container = await mount(
            tester,
            desktop,
            _CaptureWallet(),
            prefs,
            locale,
          );
          final field = find.byKey(
            const Key('amountInputFieldCryptoTextFieldKey'),
          );
          await tester.enterText(field, '1.2501');
          await tester.pump(const Duration(milliseconds: 600));
          final expected = container.read(pSendAmount);
          if (unitFirst) {
            prefs.changeUnit(AmountUnit.milli);
            locale.change('de_DE');
          } else {
            locale.change('de_DE');
            prefs.changeUnit(AmountUnit.milli);
          }
          await tester.pump(const Duration(milliseconds: 600));
          expect(container.read(pSendAmount), expected);
          expect(tester.widget<TextField>(field).controller!.text, '1250,1');
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        },
      );
    }
    testWidgets('fiat input clears send all desktop=$desktop', (tester) async {
      final prefs = _Prefs();
      final locale = _Locale();
      final wallet = _CaptureWallet();
      final container = await mount(tester, desktop, wallet, prefs, locale);
      final sendAll = find.textContaining('Send all', findRichText: true);
      if (sendAll.evaluate().isEmpty) {
        expect(find.textContaining('Send all'), findsOneWidget);
      }
      final sendAllActual = sendAll.evaluate().isEmpty
          ? find.textContaining('Send all')
          : sendAll;
      await tester.ensureVisible(sendAllActual);
      await tester.tap(sendAllActual);
      await tester.pump();
      expect(container.read(pSendAmount)!.decimal, Decimal.fromInt(10));
      final fiat = find.byKey(const Key('amountInputFieldFiatTextFieldKey'));
      expect(fiat, findsOneWidget);
      await tester.enterText(fiat, '1');
      await tester.pump(const Duration(milliseconds: 600));
      expect(container.read(pSendAmount)!.decimal, Decimal.one);
      final address = find.byKey(const Key('sendViewAddressFieldKey'));
      await tester.enterText(address, 'some-address');
      await tester.pump();
      // Trigger the current preview callback without relying on scroll position.
      if (desktop) {
        final preview = tester.widget<PrimaryButton>(
          find.widgetWithText(PrimaryButton, 'Preview send'),
        );
        expect(preview.enabled, true);
        preview.onPressed!();
      } else {
        final preview = tester.widget<TextButton>(
          find.widgetWithText(TextButton, 'Preview'),
        );
        expect(preview.onPressed, isNotNull);
        preview.onPressed!();
      }
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 2600));
      expect(wallet.captured, isNotNull);
      expect(wallet.captured!.recipients!.single.amount.decimal, Decimal.one);
      expect(
        wallet.captured!.xelisSendAll,
        false,
        reason: 'Editing the fiat amount must cancel send-all intent',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}
