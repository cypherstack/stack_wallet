import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/transaction_details_view.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/coins/firo/firo_wallet.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/services/locale_service.dart';
import 'package:stackwallet/services/notes_service.dart';
import 'package:stackwallet/services/price_service.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/utilities/theme/light_colors.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/transaction_card.dart';
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
      timestamp: 1648595998,
      type: TransactionType.outgoing,
      amount: 100000000,
      fee: 3794,
      height: 450123,
      subType: TransactionSubType.none,
      isCancelled: false,
      walletId: '',
      isLelantus: null,
      slateId: '',
      otherData: '',
      inputs: [],
      outputs: [],
    )..address.value = Address(
        walletId: "walletId",
        value: "",
        publicKey: [],
        derivationIndex: 0,
        type: AddressType.p2pkh,
        subType: AddressSubType.receiving);

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

    when(wallet.storedChainHeight).thenAnswer((_) => 6000000);
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
    final amount = Util.isDesktop
        ? find.text("-1.00000000 FIRO")
        : find.text("1.00000000 FIRO");

    final icon = find.byIcon(FeatherIcons.arrowUp);

    expect(title, findsOneWidget);
    // expect(price1, findsOneWidget);
    expect(amount, findsOneWidget);
    // expect(icon, findsOneWidget);
    //
    await tester.pumpAndSettle(const Duration(seconds: 2));
    //
    // final price2 = find.text("\$10.00");
    // expect(price2, findsOneWidget);
    //
    // verify(mockManager.addListener(any)).called(1);
    verify(mockLocaleService.addListener(any)).called(1);

    verify(mockPrefs.currency).called(1);
    verify(mockPriceService.getPrice(Coin.firo)).called(1);
    verify(wallet.coin.ticker).called(2);

    verify(mockLocaleService.locale).called(1);

    verifyNoMoreInteractions(mockManager);
    verifyNoMoreInteractions(mockLocaleService);
  });

  testWidgets("Anonymized confirmed tx displays correctly", (tester) async {
    final mockManager = MockManager();
    final mockLocaleService = MockLocaleService();
    final wallets = MockWallets();
    final mockPrefs = MockPrefs();
    final mockPriceService = MockPriceService();

    final tx = Transaction(
      txid: "some txid",
      timestamp: 1648595998,
      type: TransactionType.outgoing,
      amount: 9659,
      fee: 3794,
      height: 450123,
      subType: TransactionSubType.mint,
      isCancelled: false,
      walletId: '',
      isLelantus: null,
      slateId: '',
      otherData: '',
      inputs: [],
      outputs: [],
    )..address.value = Address(
        walletId: "walletId",
        value: "",
        publicKey: [],
        derivationIndex: 0,
        type: AddressType.p2pkh,
        subType: AddressSubType.receiving);

    final CoinServiceAPI wallet = MockFiroWallet();

    when(wallet.coin.ticker).thenAnswer((_) => "FIRO");
    when(mockLocaleService.locale).thenAnswer((_) => "en_US");
    when(mockPrefs.currency).thenAnswer((_) => "USD");
    when(mockPrefs.externalCalls).thenAnswer((_) => true);
    when(mockPriceService.getPrice(Coin.firo))
        .thenAnswer((realInvocation) => Tuple2(Decimal.ten, 0.00));

    when(wallet.coin).thenAnswer((_) => Coin.firo);
    when(wallet.storedChainHeight).thenAnswer((_) => 6000000);

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
    final title = find.text("Anonymized");
    // final price1 = find.text("0.00 USD");
    final amount = find.text("-0.00009659 FIRO");

    final icon = find.byIcon(FeatherIcons.arrowUp);

    expect(title, findsOneWidget);
    // expect(price1, findsOneWidget);
    expect(amount, findsOneWidget);
    // expect(icon, findsOneWidget);
    //
    await tester.pumpAndSettle(const Duration(seconds: 2));
    //
    // final price2 = find.text("\$10.00");
    // expect(price2, findsOneWidget);
    //
    // verify(mockManager.addListener(any)).called(1);
    verify(mockLocaleService.addListener(any)).called(1);

    verify(mockPrefs.currency).called(1);
    verify(mockPriceService.getPrice(Coin.firo)).called(1);
    verify(wallet.coin.ticker).called(2);

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
      timestamp: 1648595998,
      type: TransactionType.incoming,
      amount: 100000000,
      fee: 3794,
      height: 450123,
      subType: TransactionSubType.none,
      isCancelled: false,
      walletId: '',
      isLelantus: null,
      slateId: '',
      otherData: '',
      inputs: [],
      outputs: [],
    )..address.value = Address(
        walletId: "walletId",
        value: "",
        publicKey: [],
        derivationIndex: 0,
        type: AddressType.p2pkh,
        subType: AddressSubType.receiving);

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

    when(wallet.storedChainHeight).thenAnswer((_) => 6000000);

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

    final title = find.text("Received");
    final amount = Util.isDesktop
        ? find.text("+1.00000000 FIRO")
        : find.text("1.00000000 FIRO");

    expect(title, findsOneWidget);
    expect(amount, findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 2));

    verify(mockLocaleService.addListener(any)).called(1);

    verify(mockPrefs.currency).called(1);
    verify(mockPriceService.getPrice(Coin.firo)).called(1);
    verify(wallet.coin.ticker).called(2);

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
      timestamp: 1648595998,
      type: TransactionType.outgoing,
      amount: 100000000,
      fee: 3794,
      height: 450123,
      subType: TransactionSubType.none,
      isCancelled: false,
      walletId: '',
      isLelantus: null,
      slateId: '',
      otherData: '',
      inputs: [],
      outputs: [],
    )..address.value = Address(
        walletId: "walletId",
        value: "",
        publicKey: [],
        derivationIndex: 0,
        type: AddressType.p2pkh,
        subType: AddressSubType.receiving);

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

    when(wallet.storedChainHeight).thenAnswer((_) => 6000000);

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

    verify(mockPrefs.currency).called(2);
    verify(mockLocaleService.locale).called(4);
    verify(wallet.coin.ticker).called(2);
    verify(wallet.storedChainHeight).called(2);

    verifyNoMoreInteractions(wallet);
    verifyNoMoreInteractions(mockLocaleService);

    if (Util.isDesktop) {
      expect(find.byType(TransactionDetailsView), findsOneWidget);
    } else {
      mockingjay
          .verify(() => navigator.pushNamed("/transactionDetails",
              arguments: Tuple3(tx, Coin.firo, "wallet id")))
          .called(1);
    }
  });
}
