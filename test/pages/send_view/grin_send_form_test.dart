import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:platform/platform.dart' as platform;
import 'package:stackwallet/models/balance.dart';
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
import 'package:stackwallet/utilities/enums/slatepack_method.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';

import '../../sample_data/theme_json.dart';
import '../../wallets/support/grin_fakes.dart';
import '../../wallets/support/xelis_test_fakes.dart';

class _Locale extends LocaleService {
  @override
  String get locale => 'en_US';
}

class _Prefs extends ConfirmationPrefs {
  @override
  bool get enableCoinControl => false;
  @override
  bool get externalCalls => true;
  @override
  AmountUnit amountUnit(CryptoCurrency coin) => AmountUnit.normal;
  @override
  int maxDecimals(CryptoCurrency coin) => coin.fractionDigits;
}

class _Price extends PriceService {
  _Price() : super('USD');
  @override
  ({Decimal value, double change24h})? getPrice(CryptoCurrency coin) =>
      (value: Decimal.one, change24h: 0);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dataRoot;
  late Directory isarRoot;
  late Isar isar;
  late GrinHarness h;

  setUpAll(() async => dataRoot = await setUpGrinTests());
  tearDownAll(() => dataRoot.delete(recursive: true));
  setUp(() async {
    isarRoot = await Directory.systemTemp.createTemp('stack_grin_isar_');
    isar = await openTestIsar(isarRoot);
    h = await GrinHarness.create();
  });
  tearDown(() async {
    await h.dispose();
    await isar.close();
    await isarRoot.delete(recursive: true);
  });

  Future<void> mount(WidgetTester tester, {required bool desktop}) async {
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
    final wallet = h.wallet;
    final walletId = h.walletId;
    final coin = wallet.cryptoCurrency;
    final theme = StackTheme.fromJson(json: lightThemeJsonMap);
    final amount = Amount(
      rawValue: BigInt.from(1000000000),
      fractionDigits: coin.fractionDigits,
    );
    final zero = Amount.zeroWith(fractionDigits: coin.fractionDigits);
    final child = desktop
        ? DesktopSend(walletId: walletId)
        : SendView(walletId: walletId, coin: coin);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pWallets.overrideWithValue(ConfirmationWallets(wallet)),
          pWalletInfo(walletId).overrideWithValue(wallet.info),
          pWalletCoin(walletId).overrideWithValue(coin),
          pWalletName(walletId).overrideWithValue(wallet.info.name),
          pWalletBalance(walletId).overrideWithValue(
            Balance(
              total: amount,
              spendable: amount,
              blockedTotal: zero,
              pendingSpendable: zero,
            ),
          ),
          prefsChangeNotifierProvider.overrideWithValue(_Prefs()),
          localeServiceChangeNotifierProvider.overrideWithValue(_Locale()),
          priceAnd24hChangeNotifierProvider.overrideWithValue(_Price()),
          themeProvider.overrideWithProvider(StateProvider((ref) => theme)),
          coinIconProvider(coin).overrideWithValue(
            File('test/sample_data/light/assets/dummy.svg').absolute.path,
          ),
        ],
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
  }

  for (final desktop in [true, false]) {
    testWidgets('manual Slatepack creation does not promise a fee review, '
        'desktop=$desktop', (tester) async {
      await mount(tester, desktop: desktop);

      expect(find.textContaining('Transaction fee'), findsNothing);
      expect(find.text('Calculated when reviewing'), findsNothing);
    });

    testWidgets('clearing the send form clears the Slatepack recipient, '
        'desktop=$desktop', (tester) async {
      await mount(tester, desktop: desktop);
      final field = find.byKey(const Key('slatepackRecipientFieldKey'));
      await tester.ensureVisible(field);
      await tester.enterText(field, 'grin1previousrecipient');
      await tester.pump();

      // What a finished send calls.
      final form = tester.state(find.byType(desktop ? DesktopSend : SendView));
      // ignore: avoid_dynamic_calls
      (form as dynamic).clearSendForm();
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(field).controller!.text,
        isEmpty,
        reason: 'the next Slatepack would be encrypted to the last recipient',
      );
    });

    testWidgets('editing a receiver address keeps the cursor in place, '
        'desktop=$desktop', (tester) async {
      await mount(tester, desktop: desktop);
      final form = find.byType(desktop ? DesktopSend : SendView);
      ProviderScope.containerOf(tester.element(form))
              .read(pSelectedSlatepackMethod(h.walletId).notifier)
              .state =
          SlatepackMethod.http;
      await tester.pumpAndSettle();
      final field = find.byKey(const Key('sendViewAddressFieldKey'));
      await tester.ensureVisible(field);
      await tester.showKeyboard(field);

      Future<void> type(String text, int cursor) async {
        tester.testTextInput.updateEditingValue(
          TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: cursor),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      await type('https://receiver.example:3415', 29);
      // Then an insertion in the middle of it.
      const edited = 'https://my-receiver.example:3415';
      await type(edited, 'https://my-'.length);

      final controller = tester.widget<TextField>(field).controller!;
      expect(controller.text, edited);
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 'https://my-'.length),
      );
    });

    testWidgets('a Grin address on the Address tab creates a Slatepack, '
        'desktop=$desktop', (tester) async {
      await mount(tester, desktop: desktop);
      final form = find.byType(desktop ? DesktopSend : SendView);
      ProviderScope.containerOf(tester.element(form))
              .read(pSelectedSlatepackMethod(h.walletId).notifier)
              .state =
          SlatepackMethod.http;
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('sendViewAddressFieldKey')),
        'grin1recipient',
      );
      await tester.enterText(
        find.byKey(const Key('amountInputFieldCryptoTextFieldKey')),
        '0.1',
      );
      await tester.pumpAndSettle();

      expect(find.text('Create slatepack'), findsOneWidget);
      expect(find.textContaining('Transaction fee'), findsNothing);
      expect(find.text('Calculated when reviewing'), findsNothing);
      expect(
        h.wallet.manualSlatepackRecipientForAddress('grin1recipient'),
        'grin1recipient',
      );
      expect(tester.takeException(), isNull);
    });
  }
}
