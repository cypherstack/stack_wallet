import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/models/send_view_auto_fill_data.dart';
import 'package:stackwallet/pages/send_view/send_view.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/coins/bitcoin/bitcoin_wallet.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/services/locale_service.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/services/wallets_service.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_service.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/prefs.dart';

import '../../sample_data/theme_json.dart';
import 'send_view_test.mocks.dart';

@GenerateMocks([
  Wallets,
  WalletsService,
  NodeService,
  BitcoinWallet,
  LocaleService,
  ThemeService,
  Prefs,
], customMocks: [
  MockSpec<Manager>(returnNullOnMissingStub: true),
  MockSpec<CoinServiceAPI>(returnNullOnMissingStub: true),
])
void main() {
  testWidgets("Send to valid address", (widgetTester) async {
    final mockWallets = MockWallets();
    final mockWalletsService = MockWalletsService();
    final mockNodeService = MockNodeService();
    final CoinServiceAPI wallet = MockBitcoinWallet();
    final mockLocaleService = MockLocaleService();
    final mockThemeService = MockThemeService();
    final mockPrefs = MockPrefs();

    when(wallet.coin).thenAnswer((_) => Coin.bitcoin);
    when(wallet.walletName).thenAnswer((_) => "some wallet");
    when(wallet.walletId).thenAnswer((_) => "wallet id");

    final manager = Manager(wallet);
    when(mockWallets.getManagerProvider("wallet id")).thenAnswer(
        (realInvocation) => ChangeNotifierProvider((ref) => manager));
    when(mockWallets.getManager("wallet id"))
        .thenAnswer((realInvocation) => manager);

    when(mockLocaleService.locale).thenAnswer((_) => "en_US");
    when(mockThemeService.getTheme(themeId: "light")).thenAnswer(
      (_) => StackTheme.fromJson(
        json: lightThemeJsonMap,
      ),
    );
    when(mockPrefs.currency).thenAnswer((_) => "USD");
    when(mockPrefs.enableCoinControl).thenAnswer((_) => false);
    when(mockPrefs.amountUnit(Coin.bitcoin)).thenAnswer(
      (_) => AmountUnit.normal,
    );
    when(wallet.validateAddress("send to address"))
        .thenAnswer((realInvocation) => true);

    await widgetTester.pumpWidget(
      ProviderScope(
        overrides: [
          walletsChangeNotifierProvider.overrideWithValue(mockWallets),
          walletsServiceChangeNotifierProvider
              .overrideWithValue(mockWalletsService),
          nodeServiceChangeNotifierProvider.overrideWithValue(mockNodeService),
          localeServiceChangeNotifierProvider
              .overrideWithValue(mockLocaleService),
          prefsChangeNotifierProvider.overrideWithValue(mockPrefs),
          pThemeService.overrideWithValue(mockThemeService),
          // previewTxButtonStateProvider
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(
                StackTheme.fromJson(
                  json: lightThemeJsonMap,
                ),
              ),
            ],
          ),
          home: SendView(
            walletId: "wallet id",
            coin: Coin.bitcoin,
            autoFillData: SendViewAutoFillData(
                address: "send to address", contactLabel: "contact label"),
          ),
        ),
      ),
    );

    await widgetTester.pumpAndSettle();

    expect(find.text("Send to"), findsOneWidget);
    expect(find.text("Amount"), findsOneWidget);
    expect(find.text("Note (optional)"), findsOneWidget);
    expect(find.text("Transaction fee (estimated)"), findsOneWidget);
    verify(manager.validateAddress("send to address")).called(1);
  });

  testWidgets("Send to invalid address", (widgetTester) async {
    final mockWallets = MockWallets();
    final mockWalletsService = MockWalletsService();
    final mockNodeService = MockNodeService();
    final CoinServiceAPI wallet = MockBitcoinWallet();
    final mockLocaleService = MockLocaleService();
    final mockPrefs = MockPrefs();
    final mockThemeService = MockThemeService();

    when(wallet.coin).thenAnswer((_) => Coin.bitcoin);
    when(wallet.walletName).thenAnswer((_) => "some wallet");
    when(wallet.walletId).thenAnswer((_) => "wallet id");

    final manager = Manager(wallet);
    when(mockWallets.getManagerProvider("wallet id")).thenAnswer(
        (realInvocation) => ChangeNotifierProvider((ref) => manager));
    when(mockWallets.getManager("wallet id"))
        .thenAnswer((realInvocation) => manager);

    when(mockLocaleService.locale).thenAnswer((_) => "en_US");
    when(mockPrefs.currency).thenAnswer((_) => "USD");
    when(mockPrefs.enableCoinControl).thenAnswer((_) => false);
    when(mockPrefs.amountUnit(Coin.bitcoin)).thenAnswer(
      (_) => AmountUnit.normal,
    );
    when(wallet.validateAddress("send to address"))
        .thenAnswer((realInvocation) => false);
    when(mockThemeService.getTheme(themeId: "light")).thenAnswer(
      (_) => StackTheme.fromJson(
        json: lightThemeJsonMap,
      ),
    );

    // when(manager.isOwnAddress("send to address"))
    //     .thenAnswer((realInvocation) => Future(() => true));

    await widgetTester.pumpWidget(
      ProviderScope(
        overrides: [
          walletsChangeNotifierProvider.overrideWithValue(mockWallets),
          walletsServiceChangeNotifierProvider
              .overrideWithValue(mockWalletsService),
          nodeServiceChangeNotifierProvider.overrideWithValue(mockNodeService),
          localeServiceChangeNotifierProvider
              .overrideWithValue(mockLocaleService),
          prefsChangeNotifierProvider.overrideWithValue(mockPrefs),
          pThemeService.overrideWithValue(mockThemeService)
          // previewTxButtonStateProvider
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(
                StackTheme.fromJson(
                  json: lightThemeJsonMap,
                ),
              ),
            ],
          ),
          home: SendView(
            walletId: "wallet id",
            coin: Coin.bitcoin,
            autoFillData: SendViewAutoFillData(
                address: "send to address", contactLabel: "contact label"),
          ),
        ),
      ),
    );

    await widgetTester.pumpAndSettle();

    expect(find.text("Send to"), findsOneWidget);
    expect(find.text("Amount"), findsOneWidget);
    expect(find.text("Note (optional)"), findsOneWidget);
    expect(find.text("Transaction fee (estimated)"), findsOneWidget);
    expect(find.text("Invalid address"), findsOneWidget);
    verify(manager.validateAddress("send to address")).called(1);
  });
}
