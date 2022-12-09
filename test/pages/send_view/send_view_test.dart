import 'package:epicmobile/models/send_view_auto_fill_data.dart';
import 'package:epicmobile/pages/send_view/send_view.dart';
import 'package:epicmobile/providers/providers.dart';
import 'package:epicmobile/services/coins/coin_service.dart';
import 'package:epicmobile/services/coins/epiccash/epiccash_wallet.dart';
import 'package:epicmobile/services/coins/manager.dart';
import 'package:epicmobile/services/locale_service.dart';
import 'package:epicmobile/services/node_service.dart';
import 'package:epicmobile/services/wallets.dart';
import 'package:epicmobile/services/wallets_service.dart';
import 'package:epicmobile/utilities/enums/coin_enum.dart';
import 'package:epicmobile/utilities/prefs.dart';
import 'package:epicmobile/utilities/theme/light_colors.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'send_view_test.mocks.dart';

@GenerateMocks([
  Wallets,
  WalletsService,
  NodeService,
  EpicCashWallet,
  LocaleService,
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
    final CoinServiceAPI wallet = MockEpiccashWallet();
    final mockLocaleService = MockLocaleService();
    final mockPrefs = MockPrefs();

    when(wallet.coin).thenAnswer((_) => Coin.epicCash);
    when(wallet.walletName).thenAnswer((_) => "some wallet");
    when(wallet.walletId).thenAnswer((_) => "wallet id");

    final manager = Manager(wallet);
    when(mockWallets.getManagerProvider("wallet id")).thenAnswer(
        (realInvocation) => ChangeNotifierProvider((ref) => manager));
    when(mockWallets.getManager("wallet id"))
        .thenAnswer((realInvocation) => manager);

    when(mockLocaleService.locale).thenAnswer((_) => "en_US");
    when(mockPrefs.currency).thenAnswer((_) => "USD");
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
          // previewTxButtonStateProvider
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(
                LightColors(),
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
    when(wallet.validateAddress("send to address"))
        .thenAnswer((realInvocation) => false);

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
          // previewTxButtonStateProvider
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(
                LightColors(),
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

    expect(find.text("Send to"), findsOneWidget);
    expect(find.text("Amount"), findsOneWidget);
    expect(find.text("Note (optional)"), findsOneWidget);
    expect(find.text("Transaction fee (estimated)"), findsOneWidget);
    expect(find.text("Invalid address"), findsOneWidget);
    verify(manager.validateAddress("send to address")).called(1);
  });
}
