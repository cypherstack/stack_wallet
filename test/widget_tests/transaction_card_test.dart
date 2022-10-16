import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/hive/db.dart';
import 'package:stackwallet/models/models.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/coins/bitcoin/bitcoin_wallet.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/coins/firo/firo_wallet.dart';
// import 'package:mockito/mockito.dart';
// import 'package:stackwallet/models/models.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/services/locale_service.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/notes_service.dart';
import 'package:stackwallet/services/price_service.dart';
import 'package:stackwallet/services/transaction_notification_tracker.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/listenable_map.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/widgets/transaction_card.dart';
import 'package:stackwallet/utilities/theme/light_colors.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:tuple/tuple.dart';

import 'transaction_card_test.mocks.dart';

@GenerateMocks([
  Wallets,
  Manager,
  CoinServiceAPI,
  FiroWallet,
  LocaleService,
  Prefs,
  PriceService,
  NotesService
], customMocks: [])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets("Sent confirmed tx displays correctly", (tester) async {
    final mockManager = MockManager();
    final mockLocaleService = MockLocaleService();
    final wallets = MockWallets();
    final mockPrefs = MockPrefs();
    final mockPriceService = MockPriceService();

    final tx = Transaction(
        txid: "some txid",
        confirmedStatus: true,
        timestamp: 1648595998,
        txType: "Sent",
        amount: 100000000,
        aliens: [],
        worthNow: "0.01",
        worthAtBlockTimestamp: "0.01",
        fees: 3794,
        inputSize: 1,
        outputSize: 1,
        inputs: [],
        outputs: [],
        address: "",
        height: 450123,
        subType: "",
        confirmations: 10,
        isCancelled: false);

    final CoinServiceAPI wallet = MockFiroWallet();

    when(wallet.coin.ticker).thenAnswer((_) => "FIRO");
    when(mockLocaleService.locale).thenAnswer((_) => "en_US");
    when(mockPrefs.currency).thenAnswer((_) => "USD");
    when(mockPriceService.getPrice(Coin.firo))
        .thenAnswer((realInvocation) => Tuple2(Decimal.ten, 0.00));

    when(wallet.coin).thenAnswer((_) => Coin.firo);

    when(wallets.getManager("wallet-id"))
        .thenAnswer((realInvocation) => Manager(wallet));
    //
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletsChangeNotifierProvider.overrideWithValue(wallets),
          localeServiceChangeNotifierProvider
              .overrideWithValue(mockLocaleService),
          prefsChangeNotifierProvider.overrideWithValue(mockPrefs),
          priceAnd24hChangeNotifierProvider.overrideWithValue(mockPriceService)
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(
                LightColors(),
              ),
            ],
          ),
          home: TransactionCard(transaction: tx, walletId: "wallet-id"),
        ),
      ),
    );

    //
    final title = find.text("Sent");
    // final price1 = find.text("0.00");
    final amount = find.text("1.00000000 FIRO");

    final icon = find.byIcon(FeatherIcons.arrowUp);

    expect(title, findsOneWidget);
    // expect(price1, findsOneWidget);
    expect(amount, findsOneWidget);
    // expect(icon, findsOneWidget);
    //
    await tester.pumpAndSettle(Duration(seconds: 2));
    //
    // final price2 = find.text("\$10.00");
    // expect(price2, findsOneWidget);
    //
    // verify(mockManager.addListener(any)).called(1);
    verify(mockLocaleService.addListener(any)).called(1);

    verify(mockPrefs.currency).called(1);
    verify(mockPriceService.getPrice(Coin.firo)).called(1);
    verify(wallet.coin.ticker).called(1);

    verify(mockLocaleService.locale).called(1);

    verifyNoMoreInteractions(mockManager);
    verifyNoMoreInteractions(mockLocaleService);
  });

  testWidgets("Received unconfirmed tx displays correctly", (tester) async {
    final mockManager = MockManager();
    final mockLocaleService = MockLocaleService();
    final wallets = MockWallets();
    final mockPrefs = MockPrefs();
    final mockPriceService = MockPriceService();

    final tx = Transaction(
      txid: "some txid",
      confirmedStatus: false,
      timestamp: 1648595998,
      txType: "Received",
      amount: 100000000,
      aliens: [],
      worthNow: "0.01",
      worthAtBlockTimestamp: "0.01",
      fees: 3794,
      inputSize: 1,
      outputSize: 1,
      inputs: [],
      outputs: [],
      address: "",
      height: 0,
      subType: "",
      confirmations: 0,
    );

    final CoinServiceAPI wallet = MockFiroWallet();

    when(wallet.coin.ticker).thenAnswer((_) => "FIRO");
    when(mockLocaleService.locale).thenAnswer((_) => "en_US");
    when(mockPrefs.currency).thenAnswer((_) => "USD");
    when(mockPriceService.getPrice(Coin.firo))
        .thenAnswer((realInvocation) => Tuple2(Decimal.ten, 0.00));

    when(wallet.coin).thenAnswer((_) => Coin.firo);

    when(wallets.getManager("wallet-id"))
        .thenAnswer((realInvocation) => Manager(wallet));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletsChangeNotifierProvider.overrideWithValue(wallets),
          localeServiceChangeNotifierProvider
              .overrideWithValue(mockLocaleService),
          prefsChangeNotifierProvider.overrideWithValue(mockPrefs),
          priceAnd24hChangeNotifierProvider.overrideWithValue(mockPriceService)
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(
                LightColors(),
              ),
            ],
          ),
          home: TransactionCard(transaction: tx, walletId: "wallet-id"),
        ),
      ),
    );

    final title = find.text("Receiving");
    // final price1 = find.text("0.00");
    final amount = find.text("1.00000000 FIRO");
    //
    // final icon = find.byIcon(FeatherIcons.arrowDown);
    //
    expect(title, findsOneWidget);
    // expect(price1, findsOneWidget);
    expect(amount, findsOneWidget);
    // expect(icon, findsOneWidget);
    //
    await tester.pumpAndSettle(Duration(seconds: 2));
    //
    // final price2 = find.text("\$10.00");
    // expect(price2, findsOneWidget);

    verify(mockLocaleService.addListener(any)).called(1);

    verify(mockPrefs.currency).called(1);
    verify(mockPriceService.getPrice(Coin.firo)).called(1);
    verify(wallet.coin.ticker).called(1);

    verify(mockLocaleService.locale).called(1);

    verifyNoMoreInteractions(mockManager);
    verifyNoMoreInteractions(mockLocaleService);
  });

  // testWidgets("bad tx displays correctly", (tester) async {
  //   final mockManager = MockManager();
  //   final mockNotesService = MockNotesService();
  //   final mockLocaleService = MockLocaleService();
  //
  //   final tx = Transaction(
  //     txid: "some txid",
  //     confirmedStatus: false,
  //     timestamp: 1648595998,
  //     txType: "ahhhhhh",
  //     amount: 100000000,
  //     aliens: [],
  //     worthNow: "0.01",
  //     worthAtBlockTimestamp: "0.01",
  //     fees: 3794,
  //     inputSize: 1,
  //     outputSize: 1,
  //     inputs: [],
  //     outputs: [],
  //     address: "",
  //     height: null,
  //     subType: null,
  //   );
  //
  //   when(mockManager.coinTicker).thenAnswer((_) => "FIRO");
  //   when(mockManager.fiatPrice).thenAnswer((_) async => Decimal.ten);
  //   when(mockManager.fiatCurrency).thenAnswer((_) => "USD");
  //
  //   when(mockLocaleService.locale).thenAnswer((_) => "en_US");
  //
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: MultiProvider(
  //         providers: [
  //           ChangeNotifierProvider<NotesService>(
  //             create: (context) => mockNotesService,
  //           ),
  //           ChangeNotifierProvider<Manager>(
  //             create: (context) => mockManager,
  //           ),
  //           ChangeNotifierProvider<LocaleService>(
  //             create: (context) => mockLocaleService,
  //           ),
  //         ],
  //         child: TransactionCard(transaction: tx),
  //       ),
  //     ),
  //   );
  //
  //   final title = find.text("Unknown");
  //   final price1 = find.text("0.00");
  //   final amount = find.text("1.00000000 FIRO");
  //
  //   final icon = find.byIcon(Icons.warning_rounded);
  //
  //   expect(title, findsOneWidget);
  //   expect(price1, findsOneWidget);
  //   expect(amount, findsOneWidget);
  //   expect(icon, findsOneWidget);
  //
  //   await tester.pumpAndSettle(Duration(seconds: 2));
  //
  //   final price2 = find.text("\$10.00");
  //   expect(price2, findsOneWidget);
  //
  //   verify(mockManager.addListener(any)).called(1);
  //   verify(mockLocaleService.addListener(any)).called(1);
  //   verify(mockNotesService.addListener(any)).called(1);
  //
  //   verify(mockManager.fiatCurrency).called(1);
  //   verify(mockManager.fiatPrice).called(1);
  //   verify(mockManager.coinTicker).called(1);
  //
  //   verify(mockLocaleService.locale).called(2);
  //
  //   verifyNoMoreInteractions(mockNotesService);
  //   verifyNoMoreInteractions(mockManager);
  //   verifyNoMoreInteractions(mockLocaleService);
  // });
  //
  testWidgets("Tap gesture", (tester) async {
    final mockManager = MockManager();
    final mockNotesService = MockNotesService();
    final mockLocaleService = MockLocaleService();
    final wallets = MockWallets();
    final mockPrefs = MockPrefs();
    final mockPriceService = MockPriceService();
    final navigator = mockingjay.MockNavigator();

    final tx = Transaction(
      txid: "some txid",
      confirmedStatus: false,
      timestamp: 1648595998,
      txType: "Received",
      amount: 100000000,
      aliens: [],
      worthNow: "0.01",
      worthAtBlockTimestamp: "0.01",
      fees: 3794,
      inputSize: 1,
      outputSize: 1,
      inputs: [],
      outputs: [],
      address: "",
      height: 250,
      subType: "",
      confirmations: 10,
    );

    when(mockNotesService.getNoteFor(txid: "some txid"))
        .thenAnswer((_) async => "some note");

    final CoinServiceAPI wallet = MockFiroWallet();

    when(wallet.coin.ticker).thenAnswer((_) => "FIRO");
    when(mockLocaleService.locale).thenAnswer((_) => "en_US");
    when(mockPrefs.currency).thenAnswer((_) => "USD");
    when(mockPriceService.getPrice(Coin.firo))
        .thenAnswer((realInvocation) => Tuple2(Decimal.ten, 0.00));

    when(wallet.coin).thenAnswer((_) => Coin.firo);

    when(wallets.getManager("wallet-id"))
        .thenAnswer((realInvocation) => Manager(wallet));

    mockingjay
        .when(() => navigator.push(mockingjay.any(
            that: mockingjay.isRoute(
                whereName: equals("/transactiondetailsview")))))
        .thenAnswer((_) async => {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletsChangeNotifierProvider.overrideWithValue(wallets),
          localeServiceChangeNotifierProvider
              .overrideWithValue(mockLocaleService),
          prefsChangeNotifierProvider.overrideWithValue(mockPrefs),
          priceAnd24hChangeNotifierProvider.overrideWithValue(mockPriceService)
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(LightColors()),
            ],
          ),
          home: mockingjay.MockNavigatorProvider(
              navigator: navigator,
              child: TransactionCard(transaction: tx, walletId: "wallet-id")),
        ),
      ),
    );

    expect(find.byType(GestureDetector), findsOneWidget);

    await tester.tap(find.byType(GestureDetector));
    await tester.pump();
    //
    // verify(mockManager.addListener(any)).called(1);
    // verify(mockLocaleService.addListener(any)).called(1);
    // verify(mockNotesService.addListener(any)).called(1);
    //
    // verify(mockNotesService.getNoteFor(txid: "some txid")).called(1);
    //
    // verify(mockManager.fiatCurrency).called(1);
    // verify(mockManager.fiatPrice).called(1);
    // verify(mockManager.coinTicker).called(1);
    //
    // verify(mockLocaleService.locale).called(2);
    //
    // verifyNoMoreInteractions(mockNotesService);
    // verifyNoMoreInteractions(mockManager);
    // verifyNoMoreInteractions(mockLocaleService);
    //
    // mockingjay
    //     .verify(() => navigator.push(mockingjay.any(
    //         that: mockingjay.isRoute(
    //             whereName: equals("/transactiondetailsview")))))
    //     .called(1);
    //
    // mockingjay.verifyNoMoreInteractions(navigator);
  });
}
