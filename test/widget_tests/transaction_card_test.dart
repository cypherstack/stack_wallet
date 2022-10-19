import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/models/models.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/coins/firo/firo_wallet.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/services/locale_service.dart';
import 'package:stackwallet/services/notes_service.dart';
import 'package:stackwallet/services/price_service.dart';
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
    when(mockPrefs.externalCalls).thenAnswer((_) => true);
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
    // final price1 = find.text("0.00 USD");
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
    when(mockPrefs.externalCalls).thenAnswer((_) => true);
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
    final amount = find.text("1.00000000 FIRO");

    expect(title, findsOneWidget);
    expect(amount, findsOneWidget);

    await tester.pumpAndSettle(Duration(seconds: 2));

    verify(mockLocaleService.addListener(any)).called(1);

    verify(mockPrefs.currency).called(1);
    verify(mockPriceService.getPrice(Coin.firo)).called(1);
    verify(wallet.coin.ticker).called(1);

    verify(mockLocaleService.locale).called(1);

    verifyNoMoreInteractions(mockManager);
    verifyNoMoreInteractions(mockLocaleService);
  });

  testWidgets("Tap gesture", (tester) async {
    final mockManager = MockManager();
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

    final CoinServiceAPI wallet = MockFiroWallet();

    when(wallet.coin.ticker).thenAnswer((_) => "FIRO");
    when(mockLocaleService.locale).thenAnswer((_) => "en_US");
    when(mockPrefs.currency).thenAnswer((_) => "USD");
    when(mockPrefs.externalCalls).thenAnswer((_) => true);
    when(mockPriceService.getPrice(Coin.firo))
        .thenAnswer((realInvocation) => Tuple2(Decimal.ten, 0.00));

    when(wallet.coin).thenAnswer((_) => Coin.firo);

    when(wallets.getManager("wallet id"))
        .thenAnswer((realInvocation) => Manager(wallet));

    mockingjay
        .when(() => navigator.pushNamed("/transactionDetails",
            arguments: Tuple3(tx, Coin.firo, "wallet id")))
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
              child: TransactionCard(transaction: tx, walletId: "wallet id")),
        ),
      ),
    );

    expect(find.byType(GestureDetector), findsOneWidget);

    await tester.tap(find.byType(GestureDetector));
    await tester.pump();

    verify(mockLocaleService.addListener(any)).called(1);

    verify(mockPrefs.currency).called(1);
    verify(mockLocaleService.locale).called(1);
    verify(wallet.coin.ticker).called(1);

    verifyNoMoreInteractions(wallet);
    verifyNoMoreInteractions(mockLocaleService);

    mockingjay
        .verify(() => navigator.pushNamed("/transactionDetails",
            arguments: Tuple3(tx, Coin.firo, "wallet id")))
        .called(1);
  });
}
