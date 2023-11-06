import 'package:decimal/decimal.dart';
import 'package:mockito/annotations.dart';
import 'package:stackwallet/services/coins/bitcoin/bitcoin_wallet.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/locale_service.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/services/wallets_service.dart';
import 'package:stackwallet/themes/theme_service.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/prefs.dart';

/// quick amount constructor wrapper. Using an int is bad practice but for
/// testing with small amounts this should be fine
Amount _a(int i) => Amount.fromDecimal(
      Decimal.fromInt(i),
      fractionDigits: 8,
    );

@GenerateMocks([
  Wallets,
  WalletsService,
  BitcoinWallet,
  ThemeService,
  Prefs,
  LocaleService
], customMocks: [
  MockSpec<NodeService>(returnNullOnMissingStub: true),
  MockSpec<CoinServiceAPI>(returnNullOnMissingStub: true),
])
void main() {
  // testWidgets("Test wallet info row displays correctly", (widgetTester) async {
  //   final wallets = MockWallets();
  //   final CoinServiceAPI wallet = MockBitcoinWallet();
  //   final mockThemeService = MockThemeService();
  //   final mockPrefs = MockPrefs();
  //
  //   when(mockThemeService.getTheme(themeId: "light")).thenAnswer(
  //     (_) => StackTheme.fromJson(
  //       json: lightThemeJsonMap,
  //     ),
  //   );
  //   when(wallet.coin).thenAnswer((_) => Coin.bitcoin);
  //   when(wallet.walletName).thenAnswer((_) => "some wallet");
  //   when(wallet.walletId).thenAnswer((_) => "some wallet id");
  //
  //   when(mockPrefs.amountUnit(Coin.bitcoin)).thenAnswer(
  //     (_) => AmountUnit.normal,
  //   );
  //   when(mockPrefs.maxDecimals(Coin.bitcoin)).thenAnswer(
  //     (_) => 8,
  //   );
  //
  //   final wallet =  Manager(wallet);
  //   when(wallets.getWallet"some wallet id"))
  //       .thenAnswer((realInvocation) => manager);
  //   when(manager.balance).thenAnswer(
  //     (realInvocation) => Balance(
  //       total: _a(10),
  //       spendable: _a(10),
  //       blockedTotal: _a(0),
  //       pendingSpendable: _a(0),
  //     ),
  //   );
  //
  //   when(manager.isFavorite).thenAnswer((realInvocation) => false);
  //   final key = UniqueKey();
  //   // const managedFavorite = ManagedFavorite(walletId: "some wallet id", key: key,);
  //   await widgetTester.pumpWidget(
  //     ProviderScope(
  //       overrides: [
  //         pWallets.overrideWithValue(wallets),
  //         pThemeService.overrideWithValue(mockThemeService),
  //         prefsChangeNotifierProvider.overrideWithValue(mockPrefs),
  //         coinIconProvider.overrideWithProvider(
  //           (argument) => Provider<String>((_) =>
  //               "${Directory.current.path}/test/sample_data/light/assets/dummy.svg"),
  //         ),
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
  //         home: Material(
  //           child: ManagedFavorite(
  //             walletId: "some wallet id",
  //             key: key,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  //
  //   expect(find.byType(ManagedFavorite), findsOneWidget);
  // });
  //
  // testWidgets("Button Pressed - wallet unfavorite", (widgetTester) async {
  //   final wallets = MockWallets();
  //   final CoinServiceAPI wallet = MockBitcoinWallet();
  //   final mockLocaleService = MockLocaleService();
  //   final mockWalletsService = MockWalletsService();
  //   final mockThemeService = MockThemeService();
  //   final mockPrefs = MockPrefs();
  //
  //   when(mockThemeService.getTheme(themeId: "light")).thenAnswer(
  //     (_) => StackTheme.fromJson(
  //       json: lightThemeJsonMap,
  //     ),
  //   );
  //   when(wallet.coin).thenAnswer((_) => Coin.bitcoin);
  //   when(wallet.walletName).thenAnswer((_) => "some wallet");
  //   when(wallet.walletId).thenAnswer((_) => "some wallet id");
  //   when(mockPrefs.amountUnit(Coin.bitcoin)).thenAnswer(
  //     (_) => AmountUnit.normal,
  //   );
  //
  //   final wallet =  Manager(wallet);
  //
  //   when(wallets.getWallet"some wallet id"))
  //       .thenAnswer((realInvocation) => manager);
  //   when(manager.balance).thenAnswer(
  //     (realInvocation) => Balance(
  //       total: _a(10),
  //       spendable: _a(10),
  //       blockedTotal: _a(0),
  //       pendingSpendable: _a(0),
  //     ),
  //   );
  //
  //   when(manager.isFavorite).thenAnswer((realInvocation) => false);
  //
  //   when(mockPrefs.maxDecimals(Coin.bitcoin)).thenAnswer(
  //     (_) => 8,
  //   );
  //
  //   when(mockLocaleService.locale).thenAnswer((_) => "en_US");
  //
  //   when(wallets.getManagerProvider("some wallet id")).thenAnswer(
  //       (realInvocation) => ChangeNotifierProvider((ref) => manager));
  //
  //   const managedFavorite = ManagedFavorite(walletId: "some wallet id");
  //
  //   final ListenableList<ChangeNotifierProvider<Manager>> favorites =
  //       ListenableList();
  //
  //   final ListenableList<ChangeNotifierProvider<Manager>> nonfavorites =
  //       ListenableList();
  //   await widgetTester.pumpWidget(
  //     ProviderScope(
  //       overrides: [
  //         pWallets.overrideWithValue(wallets),
  //         localeServiceChangeNotifierProvider
  //             .overrideWithValue(mockLocaleService),
  //         favoritesProvider.overrideWithValue(favorites),
  //         nonFavoritesProvider.overrideWithValue(nonfavorites),
  //         pThemeService.overrideWithValue(mockThemeService),
  //         walletsServiceChangeNotifierProvider
  //             .overrideWithValue(mockWalletsService),
  //         prefsChangeNotifierProvider.overrideWithValue(mockPrefs),
  //         coinIconProvider.overrideWithProvider(
  //           (argument) => Provider<String>((_) =>
  //               "${Directory.current.path}/test/sample_data/light/assets/dummy.svg"),
  //         ),
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
  //         home: const Material(
  //           child: managedFavorite,
  //         ),
  //       ),
  //     ),
  //   );
  //
  //   expect(find.byType(RawMaterialButton), findsOneWidget);
  //   await widgetTester.tap(find.byType(RawMaterialButton));
  //   await widgetTester.pump();
  // });
  //
  // testWidgets("Button Pressed - wallet is favorite", (widgetTester) async {
  //   final wallets = MockWallets();
  //   final CoinServiceAPI wallet = MockBitcoinWallet();
  //   final mockLocaleService = MockLocaleService();
  //   final mockWalletsService = MockWalletsService();
  //   final mockThemeService = MockThemeService();
  //   final mockPrefs = MockPrefs();
  //
  //   when(mockThemeService.getTheme(themeId: "light")).thenAnswer(
  //     (_) => StackTheme.fromJson(
  //       json: lightThemeJsonMap,
  //     ),
  //   );
  //   when(wallet.coin).thenAnswer((_) => Coin.bitcoin);
  //   when(wallet.walletName).thenAnswer((_) => "some wallet");
  //   when(wallet.walletId).thenAnswer((_) => "some wallet id");
  //
  //   when(mockPrefs.maxDecimals(Coin.bitcoin)).thenAnswer(
  //     (_) => 8,
  //   );
  //
  //   final wallet =  Manager(wallet);
  //
  //   when(wallets.getWallet"some wallet id"))
  //       .thenAnswer((realInvocation) => manager);
  //
  //   when(manager.isFavorite).thenAnswer((realInvocation) => true);
  //   when(manager.balance).thenAnswer(
  //     (realInvocation) => Balance(
  //       total: _a(10),
  //       spendable: _a(10),
  //       blockedTotal: _a(0),
  //       pendingSpendable: _a(0),
  //     ),
  //   );
  //   when(mockPrefs.amountUnit(Coin.bitcoin)).thenAnswer(
  //     (_) => AmountUnit.normal,
  //   );
  //
  //   when(mockLocaleService.locale).thenAnswer((_) => "en_US");
  //
  //   when(wallets.getManagerProvider("some wallet id")).thenAnswer(
  //       (realInvocation) => ChangeNotifierProvider((ref) => manager));
  //
  //   const managedFavorite = ManagedFavorite(walletId: "some wallet id");
  //
  //   final ListenableList<ChangeNotifierProvider<Manager>> favorites =
  //       ListenableList();
  //
  //   final ListenableList<ChangeNotifierProvider<Manager>> nonfavorites =
  //       ListenableList();
  //   await widgetTester.pumpWidget(
  //     ProviderScope(
  //       overrides: [
  //         pWallets.overrideWithValue(wallets),
  //         localeServiceChangeNotifierProvider
  //             .overrideWithValue(mockLocaleService),
  //         favoritesProvider.overrideWithValue(favorites),
  //         nonFavoritesProvider.overrideWithValue(nonfavorites),
  //         pThemeService.overrideWithValue(mockThemeService),
  //         prefsChangeNotifierProvider.overrideWithValue(mockPrefs),
  //         walletsServiceChangeNotifierProvider
  //             .overrideWithValue(mockWalletsService),
  //         coinIconProvider.overrideWithProvider(
  //           (argument) => Provider<String>((_) =>
  //               "${Directory.current.path}/test/sample_data/light/assets/dummy.svg"),
  //         ),
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
  //         home: const Material(
  //           child: managedFavorite,
  //         ),
  //       ),
  //     ),
  //   );
  //
  //   expect(find.byType(RawMaterialButton), findsOneWidget);
  //   await widgetTester.tap(find.byType(RawMaterialButton));
  //   await widgetTester.pump();
  // });
}
