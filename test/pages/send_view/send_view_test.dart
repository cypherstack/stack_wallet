import 'package:mockito/annotations.dart';
import 'package:stackwallet/services/locale_service.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/themes/theme_service.dart';
import 'package:stackwallet/utilities/prefs.dart';

@GenerateMocks([
  Wallets,
  NodeService,
  LocaleService,
  ThemeService,
  Prefs,
], customMocks: [])
void main() {
  // testWidgets("Send to valid address", (widgetTester) async {
  //   final mockWallets = MockWallets();
  //   final mockWalletsService = MockWalletsService();
  //   final mockNodeService = MockNodeService();
  //   final CoinServiceAPI wallet = MockBitcoinWallet();
  //   final mockLocaleService = MockLocaleService();
  //   final mockThemeService = MockThemeService();
  //   final mockPrefs = MockPrefs();
  //
  //   when(wallet.coin).thenAnswer((_) => Coin.bitcoin);
  //   when(wallet.walletName).thenAnswer((_) => "some wallet");
  //   when(wallet.walletId).thenAnswer((_) => "wallet id");
  //
  //   final wallet =  Manager(wallet);
  //   when(mockWallets.getManagerProvider("wallet id")).thenAnswer(
  //       (realInvocation) => ChangeNotifierProvider((ref) => manager));
  //   when(mockWallets.getWallet"wallet id"))
  //       .thenAnswer((realInvocation) => manager);
  //
  //   when(mockLocaleService.locale).thenAnswer((_) => "en_US");
  //   when(mockThemeService.getTheme(themeId: "light")).thenAnswer(
  //     (_) => StackTheme.fromJson(
  //       json: lightThemeJsonMap,
  //     ),
  //   );
  //   when(mockPrefs.currency).thenAnswer((_) => "USD");
  //   when(mockPrefs.enableCoinControl).thenAnswer((_) => false);
  //   when(mockPrefs.amountUnit(Coin.bitcoin)).thenAnswer(
  //     (_) => AmountUnit.normal,
  //   );
  //   when(wallet.validateAddress("send to address"))
  //       .thenAnswer((realInvocation) => true);
  //
  //   await widgetTester.pumpWidget(
  //     ProviderScope(
  //       overrides: [
  //         pWallets.overrideWithValue(mockWallets),
  //         walletsServiceChangeNotifierProvider
  //             .overrideWithValue(mockWalletsService),
  //         nodeServiceChangeNotifierProvider.overrideWithValue(mockNodeService),
  //         localeServiceChangeNotifierProvider
  //             .overrideWithValue(mockLocaleService),
  //         prefsChangeNotifierProvider.overrideWithValue(mockPrefs),
  //         pThemeService.overrideWithValue(mockThemeService),
  //         coinIconProvider.overrideWithProvider(
  //           (argument) => Provider<String>((_) =>
  //               "${Directory.current.path}/test/sample_data/light/assets/dummy.svg"),
  //         ),
  //         // previewTxButtonStateProvider
  //       ],
  //       child: MaterialApp(
  //         theme: ThemeData(
  //           extensions: [
  //             StackColors.fromStackColorTheme(
  //               StackTheme.fromJson(
  //                 json: lightThemeJsonMap,
  //               ),
  //             ),
  //           ],
  //         ),
  //         home: SendView(
  //           walletId: "wallet id",
  //           coin: Coin.bitcoin,
  //           autoFillData: SendViewAutoFillData(
  //               address: "send to address", contactLabel: "contact label"),
  //         ),
  //       ),
  //     ),
  //   );
  //
  //   await widgetTester.pumpAndSettle();
  //
  //   expect(find.text("Send to"), findsOneWidget);
  //   expect(find.text("Amount"), findsOneWidget);
  //   expect(find.text("Note (optional)"), findsOneWidget);
  //   expect(find.text("Transaction fee (estimated)"), findsOneWidget);
  //   verify(manager.validateAddress("send to address")).called(1);
  // });
  //
  // testWidgets("Send to invalid address", (widgetTester) async {
  //   final mockWallets = MockWallets();
  //   final mockWalletsService = MockWalletsService();
  //   final mockNodeService = MockNodeService();
  //   final CoinServiceAPI wallet = MockBitcoinWallet();
  //   final mockLocaleService = MockLocaleService();
  //   final mockPrefs = MockPrefs();
  //   final mockThemeService = MockThemeService();
  //
  //   when(wallet.coin).thenAnswer((_) => Coin.bitcoin);
  //   when(wallet.walletName).thenAnswer((_) => "some wallet");
  //   when(wallet.walletId).thenAnswer((_) => "wallet id");
  //
  //   final wallet =  Manager(wallet);
  //   when(mockWallets.getManagerProvider("wallet id")).thenAnswer(
  //       (realInvocation) => ChangeNotifierProvider((ref) => manager));
  //   when(mockWallets.getWallet"wallet id"))
  //       .thenAnswer((realInvocation) => manager);
  //
  //   when(mockLocaleService.locale).thenAnswer((_) => "en_US");
  //   when(mockPrefs.currency).thenAnswer((_) => "USD");
  //   when(mockPrefs.enableCoinControl).thenAnswer((_) => false);
  //   when(mockPrefs.amountUnit(Coin.bitcoin)).thenAnswer(
  //     (_) => AmountUnit.normal,
  //   );
  //   when(wallet.validateAddress("send to address"))
  //       .thenAnswer((realInvocation) => false);
  //   when(mockThemeService.getTheme(themeId: "light")).thenAnswer(
  //     (_) => StackTheme.fromJson(
  //       json: lightThemeJsonMap,
  //     ),
  //   );
  //
  //   // when(manager.isOwnAddress("send to address"))
  //   //     .thenAnswer((realInvocation) => Future(() => true));
  //
  //   await widgetTester.pumpWidget(
  //     ProviderScope(
  //       overrides: [
  //         pWallets.overrideWithValue(mockWallets),
  //         walletsServiceChangeNotifierProvider
  //             .overrideWithValue(mockWalletsService),
  //         nodeServiceChangeNotifierProvider.overrideWithValue(mockNodeService),
  //         localeServiceChangeNotifierProvider
  //             .overrideWithValue(mockLocaleService),
  //         prefsChangeNotifierProvider.overrideWithValue(mockPrefs),
  //         pThemeService.overrideWithValue(mockThemeService),
  //         coinIconProvider.overrideWithProvider(
  //           (argument) => Provider<String>((_) =>
  //               "${Directory.current.path}/test/sample_data/light/assets/dummy.svg"),
  //         ),
  //         // previewTxButtonStateProvider
  //       ],
  //       child: MaterialApp(
  //         theme: ThemeData(
  //           extensions: [
  //             StackColors.fromStackColorTheme(
  //               StackTheme.fromJson(
  //                 json: lightThemeJsonMap,
  //               ),
  //             ),
  //           ],
  //         ),
  //         home: SendView(
  //           walletId: "wallet id",
  //           coin: Coin.bitcoin,
  //           autoFillData: SendViewAutoFillData(
  //               address: "send to address", contactLabel: "contact label"),
  //         ),
  //       ),
  //     ),
  //   );
  //
  //   await widgetTester.pumpAndSettle();
  //
  //   expect(find.text("Send to"), findsOneWidget);
  //   expect(find.text("Amount"), findsOneWidget);
  //   expect(find.text("Note (optional)"), findsOneWidget);
  //   expect(find.text("Transaction fee (estimated)"), findsOneWidget);
  //   expect(find.text("Invalid address"), findsOneWidget);
  //   verify(manager.validateAddress("send to address")).called(1);
  // });
}
