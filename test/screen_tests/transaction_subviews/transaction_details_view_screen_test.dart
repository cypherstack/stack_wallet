// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
// import 'package:epicmobile/models/models.dart';
// import 'package:epicmobile/pages/transaction_subviews/transaction_details_view.dart';
import 'package:epicmobile/services/address_book_service.dart';
import 'package:epicmobile/services/locale_service.dart';
import 'package:epicmobile/services/notes_service.dart';
// import 'package:epicmobile/utilities/shared_utilities.dart';
// import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
// import 'package:provider/provider.dart';
//
// import 'transaction_details_view_screen_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<NotesService>(returnNullOnMissingStub: true),
  MockSpec<AddressBookService>(returnNullOnMissingStub: true),
  MockSpec<LocaleService>(returnNullOnMissingStub: true),
])
void main() {
//   final transactionA = Transaction(
//     txid: "some txid",
//     confirmedStatus: true,
//     timestamp: 1639364004,
//     txType: "Sent",
//     amount: 10000000,
//     aliens: [],
//     worthNow: "10.00",
//     worthAtBlockTimestamp: "10.00",
//     fees: 3974,
//     address: "some address",
//     inputs: [],
//     inputSize: 0,
//     outputs: [],
//     outputSize: 0,
//     height: 450345,
//     subType: "mint",
//   );
//
//   final transactionB = Transaction(
//     txid: "some txid",
//     confirmedStatus: true,
//     timestamp: 1639364004,
//     txType: "Received",
//     amount: 10000000,
//     aliens: [],
//     worthNow: "10.00",
//     worthAtBlockTimestamp: "10.00",
//     fees: 3974,
//     address: "some address",
//     inputs: [],
//     inputSize: 0,
//     outputs: [],
//     outputSize: 0,
//     height: 450345,
//     subType: "mint",
//   );
//
//   final transactionC = Transaction(
//     txid: "some txid",
//     confirmedStatus: false,
//     timestamp: 1639364004,
//     txType: "Received",
//     amount: 10000000,
//     aliens: [],
//     worthNow: "10.00",
//     worthAtBlockTimestamp: "10.00",
//     fees: 3974,
//     address: "some address",
//   );
//
//   final transactionD = Transaction(
//     txid: "some txid",
//     confirmedStatus: false,
//     timestamp: 1639364004,
//     txType: "Sent",
//     amount: 10000000,
//     aliens: [],
//     worthNow: "10.00",
//     worthAtBlockTimestamp: "10.00",
//     fees: 3974,
//     address: "some address",
//   );
//
//   testWidgets(
//       "TransactionDetailsView builds Sent tx correctly without address book entries",
//       (tester) async {
//     final addressBookService = MockAddressBookService();
//     final localeService = MockLocaleService();
//
//     when(localeService.locale).thenAnswer((_) => "en_US");
//
//     when(addressBookService.addressBookEntries)
//         .thenAnswer((_) async => <String, String>{});
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<AddressBookService>(
//               create: (_) => addressBookService,
//             ),
//             ChangeNotifierProvider<LocaleService>(
//               create: (_) => localeService,
//             ),
//           ],
//           child: TransactionDetailsView(
//             transaction: transactionA,
//             note: "some note",
//           ),
//         ),
//       ),
//     );
//
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(SingleChildScrollView), findsOneWidget);
//     expect(find.byType(TextField), findsOneWidget);
//     expect(find.byType(SvgPicture), findsOneWidget);
//     expect(find.byType(Text, skipOffstage: false), findsNWidgets(10));
//     expect(find.byType(SelectableText, skipOffstage: false), findsNWidgets(6));
//     expect(
//         find.byWidgetPredicate((widget) =>
//             widget is Container && widget.color == Color(0xFFF0F3FA)),
//         findsNWidgets(6));
//
//     expect(find.text("Type something..."), findsOneWidget);
//     expect(find.text("Transaction Details"), findsOneWidget);
//     expect(find.text("Sent"), findsOneWidget);
//     expect(find.text("Note:"), findsOneWidget);
//     expect(find.text("some note"), findsOneWidget);
//     expect(find.text("Sent to:"), findsOneWidget);
//     expect(find.text("some address"), findsOneWidget);
//     expect(find.text("Amount:"), findsOneWidget);
//     expect(find.text("0.10000000"), findsOneWidget);
//     expect(find.text("Fee:"), findsOneWidget);
//     expect(find.text("0.00003974"), findsOneWidget);
//     expect(find.text("Date:"), findsOneWidget);
//     expect(find.text(Utilities.extractDateFrom(1639364004)), findsOneWidget);
//     expect(find.text("Transaction ID:"), findsOneWidget);
//     expect(find.text("some txid"), findsOneWidget);
//     expect(find.text("Block Height:"), findsOneWidget);
//     expect(find.text("450345"), findsOneWidget);
//
//     expect((find.text("Sent").evaluate().single.widget as Text).style!.color,
//         Color(0xFFF94167));
//
//     verify(addressBookService.addListener(any)).called(1);
//     verify(addressBookService.addressBookEntries).called(1);
//
//     verify(localeService.addListener(any)).called(1);
//     verify(localeService.locale).called(1);
//
//     verifyNoMoreInteractions(localeService);
//     verifyNoMoreInteractions(addressBookService);
//   });
//
//   testWidgets("TransactionDetailsView builds Received tx correctly",
//       (tester) async {
//     final addressBookService = MockAddressBookService();
//     final localeService = MockLocaleService();
//
//     when(localeService.locale).thenAnswer((_) => "en_US");
//
//     when(addressBookService.addressBookEntries)
//         .thenAnswer((_) async => <String, String>{});
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<AddressBookService>(
//               create: (_) => addressBookService,
//             ),
//             ChangeNotifierProvider<LocaleService>(
//               create: (_) => localeService,
//             ),
//           ],
//           child: TransactionDetailsView(
//             transaction: transactionB,
//             note: "some note",
//           ),
//         ),
//       ),
//     );
//
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(SingleChildScrollView), findsOneWidget);
//     expect(find.byType(TextField), findsOneWidget);
//     expect(find.byType(SvgPicture), findsOneWidget);
//     expect(find.byType(Text, skipOffstage: false), findsNWidgets(10));
//     expect(find.byType(SelectableText, skipOffstage: false), findsNWidgets(6));
//     expect(
//         find.byWidgetPredicate((widget) =>
//             widget is Container && widget.color == Color(0xFFF0F3FA)),
//         findsNWidgets(6));
//
//     expect(find.text("Type something..."), findsOneWidget);
//     expect(find.text("Transaction Details"), findsOneWidget);
//     expect(find.text("Received"), findsOneWidget);
//     expect(find.text("Note:"), findsOneWidget);
//     expect(find.text("some note"), findsOneWidget);
//     expect(find.text("Received on:"), findsOneWidget);
//     expect(find.text("some address"), findsOneWidget);
//     expect(find.text("Amount:"), findsOneWidget);
//     expect(find.text("0.10000000"), findsOneWidget);
//     expect(find.text("Fee:"), findsOneWidget);
//     expect(find.text("0.00003974"), findsOneWidget);
//     expect(find.text("Date:"), findsOneWidget);
//     expect(find.text(Utilities.extractDateFrom(1639364004)), findsOneWidget);
//     expect(find.text("Transaction ID:"), findsOneWidget);
//     expect(find.text("some txid"), findsOneWidget);
//     expect(find.text("Block Height:"), findsOneWidget);
//     expect(find.text("450345"), findsOneWidget);
//
//     expect((find.text("Received").evaluate().single.widget as Text).style!.color,
//         Color(0xFF5BB192));
//
//     verify(localeService.addListener(any)).called(1);
//     verify(localeService.locale).called(1);
//
//     verifyNoMoreInteractions(localeService);
//     verifyNoMoreInteractions(addressBookService);
//   });
//
//   testWidgets("TransactionDetailsView builds received pending tx correctly",
//       (tester) async {
//     final addressBookService = MockAddressBookService();
//     final localeService = MockLocaleService();
//
//     when(localeService.locale).thenAnswer((_) => "en_US");
//
//     when(addressBookService.addressBookEntries)
//         .thenAnswer((_) async => <String, String>{});
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<AddressBookService>(
//               create: (_) => addressBookService,
//             ),
//             ChangeNotifierProvider<LocaleService>(
//               create: (_) => localeService,
//             ),
//           ],
//           child: TransactionDetailsView(
//             transaction: transactionC,
//             note: "some note",
//           ),
//         ),
//       ),
//     );
//
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(SingleChildScrollView), findsOneWidget);
//     expect(find.byType(TextField), findsOneWidget);
//     expect(find.byType(SvgPicture), findsOneWidget);
//     expect(find.byType(Text, skipOffstage: false), findsNWidgets(10));
//     expect(find.byType(SelectableText, skipOffstage: false), findsNWidgets(6));
//     expect(
//         find.byWidgetPredicate((widget) =>
//             widget is Container && widget.color == Color(0xFFF0F3FA)),
//         findsNWidgets(6));
//
//     expect(find.text("Type something..."), findsOneWidget);
//     expect(find.text("Transaction Details"), findsOneWidget);
//     expect(find.text("Receiving (~10 min)"), findsOneWidget);
//     expect(find.text("Note:"), findsOneWidget);
//     expect(find.text("some note"), findsOneWidget);
//     expect(find.text("Received on:"), findsOneWidget);
//     expect(find.text("some address"), findsOneWidget);
//     expect(find.text("Amount:"), findsOneWidget);
//     expect(find.text("0.10000000"), findsOneWidget);
//     expect(find.text("Fee:"), findsOneWidget);
//     expect(find.text("Pending"), findsNWidgets(2));
//     expect(find.text("Date:"), findsOneWidget);
//     expect(find.text(Utilities.extractDateFrom(1639364004)), findsOneWidget);
//     expect(find.text("Transaction ID:"), findsOneWidget);
//     expect(find.text("some txid"), findsOneWidget);
//     expect(find.text("Block Height:"), findsOneWidget);
//     expect(find.text("450345"), findsNothing);
//
//     expect(
//         (find.text("Receiving (~10 min)").evaluate().single.widget as Text)
//             .style!
//             .color,
//         Color(0xFF5BB192));
//
//     verify(localeService.addListener(any)).called(1);
//     verify(localeService.locale).called(1);
//
//     verifyNoMoreInteractions(localeService);
//     verifyNoMoreInteractions(addressBookService);
//   });
//
//   testWidgets("TransactionDetailsView builds sent pending tx correctly",
//       (tester) async {
//     final addressBookService = MockAddressBookService();
//     final localeService = MockLocaleService();
//
//     when(localeService.locale).thenAnswer((_) => "en_US");
//
//     when(addressBookService.addressBookEntries)
//         .thenAnswer((_) async => <String, String>{});
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<AddressBookService>(
//               create: (_) => addressBookService,
//             ),
//             ChangeNotifierProvider<LocaleService>(
//               create: (_) => localeService,
//             ),
//           ],
//           child: TransactionDetailsView(
//             transaction: transactionD,
//             note: "some note",
//           ),
//         ),
//       ),
//     );
//
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(SingleChildScrollView), findsOneWidget);
//     expect(find.byType(TextField), findsOneWidget);
//     expect(find.byType(SvgPicture), findsOneWidget);
//     expect(find.byType(Text, skipOffstage: false), findsNWidgets(10));
//     expect(find.byType(SelectableText, skipOffstage: false), findsNWidgets(6));
//     expect(
//         find.byWidgetPredicate((widget) =>
//             widget is Container && widget.color == Color(0xFFF0F3FA)),
//         findsNWidgets(6));
//
//     expect(find.text("Type something..."), findsOneWidget);
//     expect(find.text("Transaction Details"), findsOneWidget);
//     expect(find.text("Sending (~10 min)"), findsOneWidget);
//     expect(find.text("Note:"), findsOneWidget);
//     expect(find.text("some note"), findsOneWidget);
//     expect(find.text("Sent to:"), findsOneWidget);
//     expect(find.text("some address"), findsOneWidget);
//     expect(find.text("Amount:"), findsOneWidget);
//     expect(find.text("0.10000000"), findsOneWidget);
//     expect(find.text("Fee:"), findsOneWidget);
//     expect(find.text("Pending"), findsNWidgets(2));
//     expect(find.text("Date:"), findsOneWidget);
//     expect(find.text(Utilities.extractDateFrom(1639364004)), findsOneWidget);
//     expect(find.text("Transaction ID:"), findsOneWidget);
//     expect(find.text("some txid"), findsOneWidget);
//     expect(find.text("Block Height:"), findsOneWidget);
//     expect(find.text("450345"), findsNothing);
//
//     expect(
//         (find.text("Sending (~10 min)").evaluate().single.widget as Text)
//             .style!
//             .color,
//         Color(0xFFF94167));
//
//     verify(addressBookService.addListener(any)).called(1);
//     verify(addressBookService.addressBookEntries).called(1);
//
//     verify(localeService.addListener(any)).called(1);
//     verify(localeService.locale).called(1);
//
//     verifyNoMoreInteractions(localeService);
//     verifyNoMoreInteractions(addressBookService);
//   });
//
//   testWidgets(
//       "TransactionDetailsView builds correctly with an address book entry",
//       (tester) async {
//     final addressBookService = MockAddressBookService();
//     final localeService = MockLocaleService();
//
//     when(localeService.locale).thenAnswer((_) => "en_US");
//
//     when(addressBookService.addressBookEntries)
//         .thenAnswer((_) async => <String, String>{"some address": "john doe"});
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<AddressBookService>(
//               create: (_) => addressBookService,
//             ),
//             ChangeNotifierProvider<LocaleService>(
//               create: (_) => localeService,
//             ),
//           ],
//           child: TransactionDetailsView(
//             transaction: transactionA,
//             note: "some note",
//           ),
//         ),
//       ),
//     );
//
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(SingleChildScrollView), findsOneWidget);
//     expect(find.byType(TextField), findsOneWidget);
//     expect(find.byType(SvgPicture), findsOneWidget);
//     expect(find.byType(Text, skipOffstage: false), findsNWidgets(10));
//     expect(find.byType(SelectableText, skipOffstage: false), findsNWidgets(6));
//     expect(
//         find.byWidgetPredicate((widget) =>
//             widget is Container && widget.color == Color(0xFFF0F3FA)),
//         findsNWidgets(6));
//
//     expect(find.text("Type something..."), findsOneWidget);
//     expect(find.text("Transaction Details"), findsOneWidget);
//     expect(find.text("Sent"), findsOneWidget);
//     expect(find.text("Note:"), findsOneWidget);
//     expect(find.text("some note"), findsOneWidget);
//     expect(find.text("Sent to:"), findsOneWidget);
//     expect(find.text("john doe"), findsOneWidget);
//     expect(find.text("Amount:"), findsOneWidget);
//     expect(find.text("0.10000000"), findsOneWidget);
//     expect(find.text("Fee:"), findsOneWidget);
//     expect(find.text("0.00003974"), findsOneWidget);
//     expect(find.text("Date:"), findsOneWidget);
//     expect(find.text(Utilities.extractDateFrom(1639364004)), findsOneWidget);
//     expect(find.text("Transaction ID:"), findsOneWidget);
//     expect(find.text("some txid"), findsOneWidget);
//     expect(find.text("Block Height:"), findsOneWidget);
//     expect(find.text("450345"), findsOneWidget);
//
//     verify(addressBookService.addListener(any)).called(1);
//     verify(addressBookService.addressBookEntries).called(1);
//
//     verify(localeService.addListener(any)).called(1);
//     verify(localeService.locale).called(1);
//
//     verifyNoMoreInteractions(localeService);
//     verifyNoMoreInteractions(addressBookService);
//   });
//
//   testWidgets("tap back", (tester) async {
//     final addressBookService = MockAddressBookService();
//     final localeService = MockLocaleService();
//
//     when(localeService.locale).thenAnswer((_) => "en_US");
//     final navigator = mockingjay.MockNavigator();
//
//     when(addressBookService.addressBookEntries)
//         .thenAnswer((_) async => <String, String>{"some address": "john doe"});
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) {});
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<AddressBookService>(
//                 create: (_) => addressBookService,
//               ),
//               ChangeNotifierProvider<LocaleService>(
//                 create: (_) => localeService,
//               ),
//             ],
//             child: TransactionDetailsView(
//               transaction: transactionA,
//               note: "some note",
//             ),
//           ),
//         ),
//       ),
//     );
//
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byType(AppBarIconButton));
//     await tester.pump(Duration(milliseconds: 200));
//
//     verify(addressBookService.addListener(any)).called(1);
//     verify(addressBookService.addressBookEntries).called(2);
//
//     verify(localeService.addListener(any)).called(1);
//     verify(localeService.locale).called(2);
//
//     verifyNoMoreInteractions(localeService);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("modify note to new value", (tester) async {
//     final addressBookService = MockAddressBookService();
//     final notesService = MockNotesService();
//     final navigator = mockingjay.MockNavigator();
//     final localeService = MockLocaleService();
//
//     when(localeService.locale).thenAnswer((_) => "en_US");
//
//     when(addressBookService.addressBookEntries)
//         .thenAnswer((_) async => <String, String>{"some address": "john doe"});
//
//     when(notesService.editOrAddNote(txid: "some txid", note: "some new note"))
//         .thenAnswer((_) async {});
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<AddressBookService>(
//                 create: (_) => addressBookService,
//               ),
//               ChangeNotifierProvider<NotesService>(
//                 create: (_) => notesService,
//               ),
//               ChangeNotifierProvider<LocaleService>(
//                 create: (_) => localeService,
//               ),
//             ],
//             child: TransactionDetailsView(
//               transaction: transactionA,
//               note: "some note",
//             ),
//           ),
//         ),
//       ),
//     );
//
//     await tester.pumpAndSettle();
//
//     await tester.enterText(find.byType(TextField), "some new note");
//     (find.byType(TextField).evaluate().single.widget as TextField)
//         .focusNode!
//         .unfocus();
//     await tester.pumpAndSettle();
//
//     expect(find.text("some note"), findsNothing);
//     expect(find.text("some new note"), findsOneWidget);
//
//     verify(addressBookService.addListener(any)).called(1);
//     verify(addressBookService.addressBookEntries).called(1);
//
//     verify(notesService.addListener(any)).called(1);
//     verify(notesService.editOrAddNote(txid: "some txid", note: "some new note"))
//         .called(1);
//
//     verify(localeService.addListener(any)).called(1);
//     verify(localeService.locale).called(1);
//
//     verifyNoMoreInteractions(localeService);
//     verifyNoMoreInteractions(notesService);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("modify note but keep original value", (tester) async {
//     final addressBookService = MockAddressBookService();
//     final notesService = MockNotesService();
//     final navigator = mockingjay.MockNavigator();
//     final localeService = MockLocaleService();
//
//     when(localeService.locale).thenAnswer((_) => "en_US");
//
//     when(addressBookService.addressBookEntries)
//         .thenAnswer((_) async => <String, String>{"some address": "john doe"});
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<AddressBookService>(
//                 create: (_) => addressBookService,
//               ),
//               ChangeNotifierProvider<NotesService>(
//                 create: (_) => notesService,
//               ),
//               ChangeNotifierProvider<LocaleService>(
//                 create: (_) => localeService,
//               ),
//             ],
//             child: TransactionDetailsView(
//               transaction: transactionA,
//               note: "some note",
//             ),
//           ),
//         ),
//       ),
//     );
//
//     await tester.pumpAndSettle();
//
//     await tester.enterText(find.byType(TextField), "some note");
//     (find.byType(TextField).evaluate().single.widget as TextField)
//         .focusNode!
//         .unfocus();
//
//     await tester.pumpAndSettle();
//
//     expect(find.text("some note"), findsOneWidget);
//
//     verify(addressBookService.addListener(any)).called(1);
//     verify(addressBookService.addressBookEntries).called(1);
//
//     verify(localeService.addListener(any)).called(1);
//     verify(localeService.locale).called(1);
//
//     verifyNoMoreInteractions(localeService);
//     verifyNoMoreInteractions(notesService);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
}
