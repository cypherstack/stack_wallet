import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/send_view/send_view.dart';
import 'package:stackwallet/providers/global/barcode_scanner_provider.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/themes/coin_icon_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/amount/amount_formatter.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/utilities/barcode_scanner_interface.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';
import 'package:stackwallet/wallets/wallet/impl/epiccash_wallet.dart';

import '../../sample_data/theme_json.dart';
import '../../wallets/support/xelis_test_fakes.dart';

class _SendPrefs extends ConfirmationPrefs {
  @override
  bool get enableCoinControl => false;
  @override
  AmountUnit amountUnit(CryptoCurrency coin) => AmountUnit.normal;
  @override
  int maxDecimals(CryptoCurrency coin) => coin.fractionDigits;
}

class _TestWallet extends EpiccashWallet {
  _TestWallet() : super(CryptoCurrencyNetwork.main);

  @override
  Future<Amount> estimateFeeFor(Amount amount, BigInt feeRate) async =>
      Amount.zeroWith(fractionDigits: cryptoCurrency.fractionDigits);
}

class _FakeScanner implements BarcodeScannerInterface {
  _FakeScanner(this.rawContent);

  final String rawContent;

  @override
  Future<ScanResult> scan({required BuildContext context}) async =>
      ScanResult(rawContent: rawContent);
}

void main() {
  Future<void> pumpSendView(WidgetTester tester, [String scanned = '']) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final previousThemesDir = StackFileSystem.themesDir;
    addTearDown(() => StackFileSystem.themesDir = previousThemesDir);
    StackFileSystem.themesDir = Directory('test/sample_data').absolute;

    final wallet = _TestWallet();
    final coin = wallet.cryptoCurrency;
    const walletId = 'epic-send-form';
    final info = WalletInfo(
      walletId: walletId,
      name: 'Epic Cash test wallet',
      mainAddressType: AddressType.mimbleWimble,
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
          prefsChangeNotifierProvider.overrideWithValue(_SendPrefs()),
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
          pBarcodeScanner.overrideWithValue(_FakeScanner(scanned)),
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
  }

  String addressField(WidgetTester tester) => tester
      .widget<TextField>(find.byKey(const Key('sendViewAddressFieldKey')))
      .controller!
      .text;

  TextSelection addressSelection(WidgetTester tester) => tester
      .widget<TextField>(find.byKey(const Key('sendViewAddressFieldKey')))
      .controller!
      .selection;

  Future<void> type(WidgetTester tester, String text, int cursor) async {
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: cursor),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  Future<void> scan(WidgetTester tester) async {
    final button = find.byKey(const Key('sendViewScanQrButtonKey'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }

  testWidgets('a scanned Epicbox address loses its https prefix and slash', (
    tester,
  ) async {
    await pumpSendView(tester, 'https://user@epicbox.example/\nsecond line');

    await scan(tester);

    expect(addressField(tester), 'user@epicbox.example');
    await dispose(tester);
  });

  testWidgets('a scanned mailto Epicbox address loses its prefix', (
    tester,
  ) async {
    await pumpSendView(tester, 'mailto:user@epicbox.example');

    await scan(tester);

    expect(addressField(tester), 'user@epicbox.example');
    await dispose(tester);
  });

  testWidgets('a scanned http receiver address is kept as it is', (
    tester,
  ) async {
    await pumpSendView(tester, 'https://receiver.example:3415');

    await scan(tester);

    expect(addressField(tester), 'https://receiver.example:3415');
    await dispose(tester);
  });

  testWidgets('typing an http receiver address keeps the cursor in place', (
    tester,
  ) async {
    await pumpSendView(tester);
    const address = 'https://receiver.example:3415';
    await tester.showKeyboard(find.byKey(const Key('sendViewAddressFieldKey')));

    for (var i = 1; i <= address.length; i++) {
      await type(tester, address.substring(0, i), i);

      expect(addressField(tester), address.substring(0, i));
      expect(addressSelection(tester), TextSelection.collapsed(offset: i));
    }

    // An edit in the middle of the address.
    const edited = 'https://my-receiver.example:3415';
    await type(tester, edited, 'https://my-'.length);

    expect(addressField(tester), edited);
    expect(
      addressSelection(tester),
      const TextSelection.collapsed(offset: 'https://my-'.length),
    );
    await dispose(tester);
  });
}
