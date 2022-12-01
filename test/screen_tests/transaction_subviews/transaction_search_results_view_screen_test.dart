// import 'package:decimal/decimal.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
// import 'package:epicmobile/pages/transaction_subviews/transaction_search_results_view.dart';
import 'package:epicmobile/services/coins/manager.dart';
import 'package:epicmobile/services/locale_service.dart';
import 'package:epicmobile/services/notes_service.dart';
// import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
// import 'package:epicmobile/widgets/transaction_card.dart';
// import 'package:provider/provider.dart';
//
// import '../../sample_data/transaction_data_samples.dart';
// import 'transaction_search_results_view_screen_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<Manager>(returnNullOnMissingStub: true),
  MockSpec<NotesService>(returnNullOnMissingStub: true),
  MockSpec<LocaleService>(returnNullOnMissingStub: true),
])
void main() {
//   testWidgets(
//       "TransactionSearchResultsView builds correctly without any transactions",
//       (tester) async {
//     final manager = MockManager();
//
//     when(manager.transactionData)
//         .thenAnswer((_) async => transactionDataFromJsonChunks);
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<Manager>(
//               create: (_) => manager,
//             ),
//           ],
//           child: TransactionSearchResultsView(
//             start: DateTime(2022, 4),
//             end: DateTime(2022, 5),
//             received: true,
//             sent: false,
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(Text), findsNWidgets(4));
//     expect(find.byType(SvgPicture), findsNWidgets(2));
//
//     expect(find.text("Search results"), findsOneWidget);
//     expect(find.text("Received"), findsOneWidget);
//     expect(find.text("04/01/22-05/01/22"), findsOneWidget);
//     expect(find.text("NO MATCHING TRANSACTIONS FOUND"), findsOneWidget);
//
//     verify(manager.transactionData).called(1);
//     verify(manager.addListener(any)).called(1);
//
//     verifyNoMoreInteractions(manager);
//   });
//
//   testWidgets("TransactionSearchResultsView builds correctly with two results",
//       (tester) async {
//     final manager = MockManager();
//     final notesService = MockNotesService();
//     final localeService = MockLocaleService();
//
//     when(localeService.locale).thenAnswer((_) => "en_US");
//
//     when(manager.transactionData)
//         .thenAnswer((_) async => transactionDataFromJsonChunks);
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//     when(manager.fiatPrice).thenAnswer((_) async => Decimal.one);
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<Manager>(
//               create: (_) => manager,
//             ),
//             ChangeNotifierProvider<NotesService>(
//               create: (_) => notesService,
//             ),
//             ChangeNotifierProvider<LocaleService>(
//               create: (_) => localeService,
//             ),
//           ],
//           child: TransactionSearchResultsView(
//             start: DateTime(2021, 2),
//             end: DateTime(2022, 4),
//             sent: true,
//             received: false,
//             keyword: "99",
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(Text), findsNWidgets(12));
//     expect(find.byType(SvgPicture), findsNWidgets(1));
//     expect(find.byType(TransactionCard), findsNWidgets(2));
//
//     expect(find.text("Search results"), findsOneWidget);
//     expect(find.text("Sent"), findsNWidgets(3));
//     expect(find.text("99"), findsOneWidget);
//     expect(find.text("02/01/21-04/01/22"), findsOneWidget);
//     expect(find.text("NO MATCHING TRANSACTIONS FOUND"), findsNothing);
//
//     verify(manager.transactionData).called(1);
//     verify(manager.fiatPrice).called(2);
//     verify(manager.coinTicker).called(2);
//     verify(manager.fiatCurrency).called(2);
//     verify(manager.addListener(any)).called(1);
//
//     verify(notesService.addListener(any)).called(1);
//
//     verify(localeService.addListener(any)).called(1);
//     verify(localeService.locale).called(4);
//
//     verifyNoMoreInteractions(localeService);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(notesService);
//   });
//
//   testWidgets("tap back", (tester) async {
//     final manager = MockManager();
//     final notesService = MockNotesService();
//     final navigator = mockingjay.MockNavigator();
//     final localeService = MockLocaleService();
//
//     when(localeService.locale).thenAnswer((_) => "en_US");
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) {});
//
//     when(manager.transactionData)
//         .thenAnswer((_) async => transactionDataFromJsonChunks);
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//     when(manager.fiatPrice).thenAnswer((_) async => Decimal.one);
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//               ChangeNotifierProvider<NotesService>(
//                 create: (_) => notesService,
//               ),
//               ChangeNotifierProvider<LocaleService>(
//                 create: (_) => localeService,
//               ),
//             ],
//             child: TransactionSearchResultsView(
//               start: DateTime(2021, 2),
//               end: DateTime(2022, 4),
//               sent: true,
//               received: false,
//               keyword: "99",
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byType(AppBarIconButton));
//     await tester.pump(Duration(milliseconds: 100));
//
//     verify(manager.transactionData).called(2);
//     verify(manager.fiatPrice).called(2);
//     verify(manager.coinTicker).called(2);
//     verify(manager.fiatCurrency).called(2);
//     verify(manager.addListener(any)).called(1);
//
//     verify(notesService.addListener(any)).called(1);
//
//     verify(localeService.addListener(any)).called(1);
//     verify(localeService.locale).called(4);
//
//     verifyNoMoreInteractions(localeService);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(notesService);
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("TransactionSearchResultsView builds correctly with one result",
//       (tester) async {
//     final manager = MockManager();
//     final notesService = MockNotesService();
//     final localeService = MockLocaleService();
//
//     when(localeService.locale).thenAnswer((_) => "en_US");
//
//     when(manager.transactionData)
//         .thenAnswer((_) async => transactionDataFromJsonChunks);
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//     when(manager.fiatPrice).thenAnswer((_) async => Decimal.one);
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<Manager>(
//               create: (_) => manager,
//             ),
//             ChangeNotifierProvider<NotesService>(
//               create: (_) => notesService,
//             ),
//             ChangeNotifierProvider<LocaleService>(
//               create: (_) => localeService,
//             ),
//           ],
//           child: TransactionSearchResultsView(
//             start: DateTime(2021, 2),
//             end: DateTime(2022, 4),
//             sent: true,
//             received: false,
//             keyword: "99",
//             amountString: "0.00000843",
//             amount: Decimal.parse("0.00000843"),
//             notes: {},
//             contacts: {},
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(Text), findsNWidgets(9));
//     expect(find.byType(SvgPicture), findsNWidgets(1));
//     expect(find.byType(TransactionCard), findsNWidgets(1));
//
//     expect(find.text("Search results"), findsOneWidget);
//     expect(find.text("Sent"), findsNWidgets(2));
//     expect(find.text("0.00000843 FIRO"), findsNWidgets(2));
//     expect(find.text("99"), findsOneWidget);
//     expect(find.text("02/01/21-04/01/22"), findsOneWidget);
//     expect(find.text("NO MATCHING TRANSACTIONS FOUND"), findsNothing);
//
//     verify(manager.transactionData).called(1);
//     verify(manager.fiatPrice).called(1);
//     verify(manager.coinTicker).called(2);
//     verify(manager.fiatCurrency).called(1);
//     verify(manager.addListener(any)).called(1);
//
//     verify(notesService.addListener(any)).called(1);
//
//     verify(localeService.addListener(any)).called(1);
//     verify(localeService.locale).called(2);
//
//     verifyNoMoreInteractions(localeService);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(notesService);
//   });
//
//   testWidgets("TransactionSearchResultsView builds correctly with zero results",
//       (tester) async {
//     final manager = MockManager();
//
//     when(manager.transactionData)
//         .thenAnswer((_) async => transactionDataFromJsonChunks);
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<Manager>(
//               create: (_) => manager,
//             ),
//           ],
//           child: TransactionSearchResultsView(
//             start: DateTime(2022, 4),
//             end: DateTime(2022, 5),
//             sent: true,
//             received: true,
//             keyword: "99999999",
//             amountString: "0.999",
//             amount: Decimal.parse("0.999"),
//             notes: {},
//             contacts: {},
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(Text), findsNWidgets(7));
//     expect(find.byType(SvgPicture), findsNWidgets(2));
//
//     expect(find.byType(TransactionCard), findsNWidgets(0));
//
//     expect(find.text("Search results"), findsOneWidget);
//     expect(find.text("04/01/22-05/01/22"), findsOneWidget);
//     expect(find.text("NO MATCHING TRANSACTIONS FOUND"), findsOneWidget);
//
//     verify(manager.transactionData).called(1);
//     verify(manager.coinTicker).called(1);
//     verify(manager.addListener(any)).called(1);
//
//     verifyNoMoreInteractions(manager);
//   });
}
