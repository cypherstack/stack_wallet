import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/coins/firo/firo_wallet.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/services/locale_service.dart';
import 'package:stackwallet/services/notes_service.dart';
import 'package:stackwallet/services/price_service.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/themes/theme_service.dart';
import 'package:stackwallet/utilities/prefs.dart';

@GenerateMocks([
  Wallets,
  Manager,
  CoinServiceAPI,
  FiroWallet,
  LocaleService,
  Prefs,
  PriceService,
  NotesService,
  ThemeService,
], customMocks: [])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // testWidgets("Sent confirmed tx displays correctly", (tester) async {
  //   final mockManager = MockManager();
  //   final mockLocaleService = MockLocaleService();
  //   final wallets = MockWallets();
  //   final mockPrefs = MockPrefs();
  //   final mockPriceService = MockPriceService();
  //   final mockThemeService = MockThemeService();
  //
  //   final tx = Transaction(
  //     txid: "some txid",
  //     timestamp: 1648595998,
  //     type: TransactionType.outgoing,
  //     amount: 100000000,
  //     amountString: Amount(
  //       rawValue: BigInt.from(100000000),
  //       fractionDigits: Coin.firo.decimals,
  //     ).toJsonString(),
  //     fee: 3794,
  //     height: 450123,
  //     subType: TransactionSubType.none,
  //     isCancelled: false,
  //     walletId: '',
  //     isLelantus: null,
  //     slateId: '',
  //     otherData: '',
  //     nonce: null,
  //     inputs: [],
  //     outputs: [],
  //     numberOfMessages: null,
  //   )..address.value = Address(
  //       walletId: "walletId",
  //       value: "",
  //       publicKey: [],
  //       derivationIndex: 0,
  //       derivationPath: null,
  //       type: AddressType.p2pkh,
  //       subType: AddressSubType.receiving);
  //
  //   final CoinServiceAPI wallet = MockFiroWallet();
  //
  //   when(mockThemeService.getTheme(themeId: "light")).thenAnswer(
  //     (_) => StackTheme.fromJson(
  //       json: lightThemeJsonMap,
  //       applicationThemesDirectoryPath: "test",
  //     ),
  //   );
  //   when(wallet.coin.ticker).thenAnswer((_) => "FIRO");
  //   when(mockLocaleService.locale).thenAnswer((_) => "en_US");
  //   when(mockPrefs.currency).thenAnswer((_) => "USD");
  //   when(mockPrefs.externalCalls).thenAnswer((_) => true);
  //   when(mockPriceService.getPrice(Coin.firo))
  //       .thenAnswer((realInvocation) => Tuple2(Decimal.ten, 0.00));
  //
  //   when(wallet.coin).thenAnswer((_) => Coin.firo);
  //
  //   when(wallets.getManager("wallet-id"))
  //       .thenAnswer((realInvocation) => Manager(wallet));
  //
  //   when(wallet.storedChainHeight).thenAnswer((_) => 6000000);
  //   //
  //   await tester.pumpWidget(
  //     ProviderScope(
  //       overrides: [
  //         walletsChangeNotifierProvider.overrideWithValue(wallets),
  //         localeServiceChangeNotifierProvider
  //             .overrideWithValue(mockLocaleService),
  //         pThemeService.overrideWithValue(mockThemeService),
  //         prefsChangeNotifierProvider.overrideWithValue(mockPrefs),
  //         priceAnd24hChangeNotifierProvider.overrideWithValue(mockPriceService)
  //       ],
  //       child: MaterialApp(
  //         theme: ThemeData(
  //           extensions: [
  //             StackColors.fromStackColorTheme(
  //               StackTheme.fromJson(
  //                 json: lightThemeJsonMap,
  //                 applicationThemesDirectoryPath: "test",
  //               ),
  //             ),
  //           ],
  //         ),
  //         home: TransactionCard(transaction: tx, walletId: "wallet-id"),
  //       ),
  //     ),
  //   );
  //
  //   //
  //   final title = find.text("Sent");
  //   // final price1 = find.text("0.00 USD");
  //   final amount = Util.isDesktop
  //       ? find.text("-1.00000000 FIRO")
  //       : find.text("1.00000000 FIRO");
  //
  //   final icon = find.byIcon(FeatherIcons.arrowUp);
  //
  //   expect(title, findsOneWidget);
  //   // expect(price1, findsOneWidget);
  //   expect(amount, findsOneWidget);
  //   // expect(icon, findsOneWidget);
  //   //
  //   await tester.pumpAndSettle(const Duration(seconds: 2));
  //   //
  //   // final price2 = find.text("\$10.00");
  //   // expect(price2, findsOneWidget);
  //   //
  //   // verify(mockManager.addListener(any)).called(1);
  //   verify(mockLocaleService.addListener(any)).called(1);
  //
  //   verify(mockPrefs.currency).called(1);
  //   verify(mockPriceService.getPrice(Coin.firo)).called(1);
  //   verify(wallet.coin.ticker).called(1);
  //
  //   verify(mockLocaleService.locale).called(1);
  //
  //   verifyNoMoreInteractions(mockManager);
  //   verifyNoMoreInteractions(mockLocaleService);
  // });

  // testWidgets("Anonymized confirmed tx displays correctly", (tester) async {
  //   final mockManager = MockManager();
  //   final mockLocaleService = MockLocaleService();
  //   final wallets = MockWallets();
  //   final mockPrefs = MockPrefs();
  //   final mockPriceService = MockPriceService();
  //   final mockThemeService = MockThemeService();
  //
  //   final tx = Transaction(
  //     txid: "some txid",
  //     timestamp: 1648595998,
  //     type: TransactionType.outgoing,
  //     amount: 9659,
  //     amountString: Amount(
  //       rawValue: BigInt.from(9659),
  //       fractionDigits: Coin.firo.decimals,
  //     ).toJsonString(),
  //     fee: 3794,
  //     height: 450123,
  //     subType: TransactionSubType.mint,
  //     isCancelled: false,
  //     walletId: '',
  //     isLelantus: null,
  //     slateId: '',
  //     otherData: '',
  //     nonce: null,
  //     inputs: [],
  //     outputs: [],
  //     numberOfMessages: null,
  //   )..address.value = Address(
  //       walletId: "walletId",
  //       value: "",
  //       publicKey: [],
  //       derivationIndex: 0,
  //       derivationPath: null,
  //       type: AddressType.p2pkh,
  //       subType: AddressSubType.receiving);
  //
  //   final CoinServiceAPI wallet = MockFiroWallet();
  //
  //   when(mockThemeService.getTheme(themeId: "light")).thenAnswer(
  //     (_) => StackTheme.fromJson(
  //       json: lightThemeJsonMap,
  //       applicationThemesDirectoryPath: "test",
  //     ),
  //   );
  //   when(wallet.coin.ticker).thenAnswer((_) => "FIRO");
  //   when(mockLocaleService.locale).thenAnswer((_) => "en_US");
  //   when(mockPrefs.currency).thenAnswer((_) => "USD");
  //   when(mockPrefs.externalCalls).thenAnswer((_) => true);
  //   when(mockPriceService.getPrice(Coin.firo))
  //       .thenAnswer((realInvocation) => Tuple2(Decimal.ten, 0.00));
  //
  //   when(wallet.coin).thenAnswer((_) => Coin.firo);
  //   when(wallet.storedChainHeight).thenAnswer((_) => 6000000);
  //
  //   when(wallets.getManager("wallet-id"))
  //       .thenAnswer((realInvocation) => Manager(wallet));
  //   //
  //   await tester.pumpWidget(
  //     ProviderScope(
  //       overrides: [
  //         walletsChangeNotifierProvider.overrideWithValue(wallets),
  //         localeServiceChangeNotifierProvider
  //             .overrideWithValue(mockLocaleService),
  //         prefsChangeNotifierProvider.overrideWithValue(mockPrefs),
  //         pThemeService.overrideWithValue(mockThemeService),
  //         priceAnd24hChangeNotifierProvider.overrideWithValue(mockPriceService)
  //       ],
  //       child: MaterialApp(
  //         theme: ThemeData(
  //           extensions: [
  //             StackColors.fromStackColorTheme(
  //               StackTheme.fromJson(
  //                 json: lightThemeJsonMap,
  //                 applicationThemesDirectoryPath: "test",
  //               ),
  //             ),
  //           ],
  //         ),
  //         home: TransactionCard(transaction: tx, walletId: "wallet-id"),
  //       ),
  //     ),
  //   );
  //
  //   //
  //   final title = find.text("Anonymized");
  //   // final price1 = find.text("0.00 USD");
  //   final amount = find.text("-0.00009659 FIRO");
  //
  //   final icon = find.byIcon(FeatherIcons.arrowUp);
  //
  //   expect(title, findsOneWidget);
  //   // expect(price1, findsOneWidget);
  //   expect(amount, findsOneWidget);
  //   // expect(icon, findsOneWidget);
  //   //
  //   await tester.pumpAndSettle(const Duration(seconds: 2));
  //   //
  //   // final price2 = find.text("\$10.00");
  //   // expect(price2, findsOneWidget);
  //   //
  //   // verify(mockManager.addListener(any)).called(1);
  //   verify(mockLocaleService.addListener(any)).called(1);
  //
  //   verify(mockPrefs.currency).called(1);
  //   verify(mockPriceService.getPrice(Coin.firo)).called(1);
  //   verify(wallet.coin.ticker).called(1);
  //
  //   verify(mockLocaleService.locale).called(1);
  //
  //   verifyNoMoreInteractions(mockManager);
  //   verifyNoMoreInteractions(mockLocaleService);
  // });

  // testWidgets("Received unconfirmed tx displays correctly", (tester) async {
  //   final mockManager = MockManager();
  //   final mockLocaleService = MockLocaleService();
  //   final wallets = MockWallets();
  //   final mockPrefs = MockPrefs();
  //   final mockPriceService = MockPriceService();
  //   final mockThemeService = MockThemeService();
  //
  //   final tx = Transaction(
  //     txid: "some txid",
  //     timestamp: 1648595998,
  //     type: TransactionType.incoming,
  //     amount: 100000000,
  //     amountString: Amount(
  //       rawValue: BigInt.from(100000000),
  //       fractionDigits: Coin.firo.decimals,
  //     ).toJsonString(),
  //     fee: 3794,
  //     height: 450123,
  //     subType: TransactionSubType.none,
  //     isCancelled: false,
  //     walletId: '',
  //     isLelantus: null,
  //     slateId: '',
  //     otherData: '',
  //     nonce: null,
  //     inputs: [],
  //     outputs: [],
  //     numberOfMessages: null,
  //   )..address.value = Address(
  //       walletId: "walletId",
  //       value: "",
  //       publicKey: [],
  //       derivationIndex: 0,
  //       derivationPath: null,
  //       type: AddressType.p2pkh,
  //       subType: AddressSubType.receiving);
  //
  //   final CoinServiceAPI wallet = MockFiroWallet();
  //
  //   when(mockThemeService.getTheme(themeId: "light")).thenAnswer(
  //     (_) => StackTheme.fromJson(
  //       json: lightThemeJsonMap,
  //       applicationThemesDirectoryPath: "test",
  //     ),
  //   );
  //   when(wallet.coin.ticker).thenAnswer((_) => "FIRO");
  //   when(mockLocaleService.locale).thenAnswer((_) => "en_US");
  //   when(mockPrefs.currency).thenAnswer((_) => "USD");
  //   when(mockPrefs.externalCalls).thenAnswer((_) => true);
  //   when(mockPriceService.getPrice(Coin.firo))
  //       .thenAnswer((realInvocation) => Tuple2(Decimal.ten, 0.00));
  //
  //   when(wallet.coin).thenAnswer((_) => Coin.firo);
  //
  //   when(wallets.getManager("wallet-id"))
  //       .thenAnswer((realInvocation) => Manager(wallet));
  //
  //   when(wallet.storedChainHeight).thenAnswer((_) => 6000000);
  //
  //   await tester.pumpWidget(
  //     ProviderScope(
  //       overrides: [
  //         walletsChangeNotifierProvider.overrideWithValue(wallets),
  //         localeServiceChangeNotifierProvider
  //             .overrideWithValue(mockLocaleService),
  //         prefsChangeNotifierProvider.overrideWithValue(mockPrefs),
  //         pThemeService.overrideWithValue(mockThemeService),
  //         priceAnd24hChangeNotifierProvider.overrideWithValue(mockPriceService)
  //       ],
  //       child: MaterialApp(
  //         theme: ThemeData(
  //           extensions: [
  //             StackColors.fromStackColorTheme(
  //               StackTheme.fromJson(
  //                 json: lightThemeJsonMap,
  //                 applicationThemesDirectoryPath: "test",
  //               ),
  //             ),
  //           ],
  //         ),
  //         home: TransactionCard(transaction: tx, walletId: "wallet-id"),
  //       ),
  //     ),
  //   );
  //
  //   final title = find.text("Received");
  //   final amount = Util.isDesktop
  //       ? find.text("+1.00000000 FIRO")
  //       : find.text("1.00000000 FIRO");
  //
  //   expect(title, findsOneWidget);
  //   expect(amount, findsOneWidget);
  //
  //   await tester.pumpAndSettle(const Duration(seconds: 2));
  //
  //   verify(mockLocaleService.addListener(any)).called(1);
  //
  //   verify(mockPrefs.currency).called(1);
  //   verify(mockPriceService.getPrice(Coin.firo)).called(1);
  //   verify(wallet.coin.ticker).called(1);
  //
  //   verify(mockLocaleService.locale).called(1);
  //
  //   verifyNoMoreInteractions(mockManager);
  //   verifyNoMoreInteractions(mockLocaleService);
  // });

  // testWidgets("Tap gesture", (tester) async {
  //   final mockManager = MockManager();
  //   final mockLocaleService = MockLocaleService();
  //   final wallets = MockWallets();
  //   final mockPrefs = MockPrefs();
  //   final mockPriceService = MockPriceService();
  //   final mockThemeService = MockThemeService();
  //   final navigator = mockingjay.MockNavigator();
  //
  //   final tx = Transaction(
  //     txid: "some txid",
  //     timestamp: 1648595998,
  //     type: TransactionType.outgoing,
  //     amount: 100000000,
  //     amountString: Amount(
  //       rawValue: BigInt.from(100000000),
  //       fractionDigits: Coin.firo.decimals,
  //     ).toJsonString(),
  //     fee: 3794,
  //     height: 450123,
  //     subType: TransactionSubType.none,
  //     isCancelled: false,
  //     walletId: '',
  //     isLelantus: null,
  //     slateId: '',
  //     otherData: '',
  //     nonce: null,
  //     inputs: [],
  //     outputs: [],
  //     numberOfMessages: null,
  //   )..address.value = Address(
  //       walletId: "walletId",
  //       value: "",
  //       publicKey: [],
  //       derivationIndex: 0,
  //       derivationPath: null,
  //       type: AddressType.p2pkh,
  //       subType: AddressSubType.receiving);
  //
  //   final CoinServiceAPI wallet = MockFiroWallet();
  //
  //   when(mockThemeService.getTheme(themeId: "light")).thenAnswer(
  //     (_) => StackTheme.fromJson(
  //       json: lightThemeJsonMap,
  //       applicationThemesDirectoryPath: "test",
  //     ),
  //   );
  //   when(wallet.coin.ticker).thenAnswer((_) => "FIRO");
  //   when(mockLocaleService.locale).thenAnswer((_) => "en_US");
  //   when(mockPrefs.currency).thenAnswer((_) => "USD");
  //   when(mockPrefs.externalCalls).thenAnswer((_) => true);
  //   when(mockPriceService.getPrice(Coin.firo))
  //       .thenAnswer((realInvocation) => Tuple2(Decimal.ten, 0.00));
  //
  //   when(wallet.coin).thenAnswer((_) => Coin.firo);
  //
  //   when(wallets.getManager("wallet id"))
  //       .thenAnswer((realInvocation) => Manager(wallet));
  //
  //   when(wallet.storedChainHeight).thenAnswer((_) => 6000000);
  //
  //   mockingjay
  //       .when(() => navigator.pushNamed("/transactionDetails",
  //           arguments: Tuple3(tx, Coin.firo, "wallet id")))
  //       .thenAnswer((_) async => {});
  //
  //   await tester.pumpWidget(
  //     ProviderScope(
  //       overrides: [
  //         walletsChangeNotifierProvider.overrideWithValue(wallets),
  //         localeServiceChangeNotifierProvider
  //             .overrideWithValue(mockLocaleService),
  //         prefsChangeNotifierProvider.overrideWithValue(mockPrefs),
  //         pThemeService.overrideWithValue(mockThemeService),
  //         priceAnd24hChangeNotifierProvider.overrideWithValue(mockPriceService)
  //       ],
  //       child: MaterialApp(
  //         theme: ThemeData(
  //           extensions: [
  //             StackColors.fromStackColorTheme(
  //               StackTheme.fromJson(
  //                 json: lightThemeJsonMap,
  //                 applicationThemesDirectoryPath: "test",
  //               ),
  //             ),
  //           ],
  //         ),
  //         home: mockingjay.MockNavigatorProvider(
  //             navigator: navigator,
  //             child: TransactionCard(transaction: tx, walletId: "wallet id")),
  //       ),
  //     ),
  //   );
  //
  //   expect(find.byType(GestureDetector), findsOneWidget);
  //
  //   await tester.tap(find.byType(GestureDetector));
  //   await tester.pump();
  //
  //   verify(mockLocaleService.addListener(any)).called(1);
  //
  //   verify(mockPrefs.currency).called(2);
  //   verify(mockLocaleService.locale).called(4);
  //   verify(wallet.coin.ticker).called(1);
  //   verify(wallet.storedChainHeight).called(2);
  //
  //   verifyNoMoreInteractions(wallet);
  //   verifyNoMoreInteractions(mockLocaleService);
  //
  //   if (Util.isDesktop) {
  //     expect(find.byType(TransactionDetailsView), findsOneWidget);
  //   } else {
  //     mockingjay
  //         .verify(() => navigator.pushNamed("/transactionDetails",
  //             arguments: Tuple3(tx, Coin.firo, "wallet id")))
  //         .called(1);
  //   }
  // });
}
