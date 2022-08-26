// import 'package:decimal/decimal.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_feather_icons/flutter_feather_icons.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
// import 'package:stackwallet/models/models.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/services/locale_service.dart';
import 'package:stackwallet/services/notes_service.dart';
// import 'package:stackwallet/widgets/transaction_card.dart';

// import 'transaction_card_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<Manager>(returnNullOnMissingStub: true),
  MockSpec<NotesService>(returnNullOnMissingStub: true),
  MockSpec<LocaleService>(returnNullOnMissingStub: true),
])
void main() {
  // testWidgets("Sent confirmed tx displays correctly", (tester) async {
  //   final mockManager = MockManager();
  //   final mockNotesService = MockNotesService();
  //   final mockLocaleService = MockLocaleService();
  //
  //   final tx = Transaction(
  //     txid: "some txid",
  //     confirmedStatus: true,
  //     timestamp: 1648595998,
  //     txType: "Sent",
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
  //     height: 450123,
  //     subType: "mint",
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
  //   final title = find.text("Sent");
  //   final price1 = find.text("0.00");
  //   final amount = find.text("1.00000000 FIRO");
  //
  //   final icon = find.byIcon(FeatherIcons.arrowUp);
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
  // testWidgets("Received unconfirmed tx displays correctly", (tester) async {
  //   final mockManager = MockManager();
  //   final mockNotesService = MockNotesService();
  //   final mockLocaleService = MockLocaleService();
  //
  //   final tx = Transaction(
  //     txid: "some txid",
  //     confirmedStatus: false,
  //     timestamp: 1648595998,
  //     txType: "Received",
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
  //   final title = find.text("Receiving");
  //   final price1 = find.text("0.00");
  //   final amount = find.text("1.00000000 FIRO");
  //
  //   final icon = find.byIcon(FeatherIcons.arrowDown);
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
  // testWidgets("Tap gesture", (tester) async {
  //   final mockManager = MockManager();
  //   final mockNotesService = MockNotesService();
  //   final mockLocaleService = MockLocaleService();
  //   final navigator = mockingjay.MockNavigator();
  //
  //   final tx = Transaction(
  //     txid: "some txid",
  //     confirmedStatus: false,
  //     timestamp: 1648595998,
  //     txType: "Received",
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
  //   when(mockNotesService.getNoteFor(txid: "some txid"))
  //       .thenAnswer((_) async => "some note");
  //
  //   when(mockManager.coinTicker).thenAnswer((_) => "FIRO");
  //   when(mockManager.fiatPrice).thenAnswer((_) async => Decimal.ten);
  //   when(mockManager.fiatCurrency).thenAnswer((_) => "USD");
  //
  //   when(mockLocaleService.locale).thenAnswer((_) => "en_US");
  //
  //   mockingjay
  //       .when(() => navigator.push(mockingjay.any(
  //           that: mockingjay.isRoute(
  //               whereName: equals("/transactiondetailsview")))))
  //       .thenAnswer((_) async => {});
  //
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: mockingjay.MockNavigatorProvider(
  //         navigator: navigator,
  //         child: MultiProvider(
  //           providers: [
  //             ChangeNotifierProvider<NotesService>(
  //               create: (context) => mockNotesService,
  //             ),
  //             ChangeNotifierProvider<Manager>(
  //               create: (context) => mockManager,
  //             ),
  //             ChangeNotifierProvider<LocaleService>(
  //               create: (context) => mockLocaleService,
  //             ),
  //           ],
  //           child: TransactionCard(transaction: tx),
  //         ),
  //       ),
  //     ),
  //   );
  //
  //   expect(find.byType(GestureDetector), findsOneWidget);
  //
  //   await tester.tap(find.byType(GestureDetector));
  //   await tester.pump();
  //
  //   verify(mockManager.addListener(any)).called(1);
  //   verify(mockLocaleService.addListener(any)).called(1);
  //   verify(mockNotesService.addListener(any)).called(1);
  //
  //   verify(mockNotesService.getNoteFor(txid: "some txid")).called(1);
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
  //
  //   mockingjay
  //       .verify(() => navigator.push(mockingjay.any(
  //           that: mockingjay.isRoute(
  //               whereName: equals("/transactiondetailsview")))))
  //       .called(1);
  //
  //   mockingjay.verifyNoMoreInteractions(navigator);
  // });
}
