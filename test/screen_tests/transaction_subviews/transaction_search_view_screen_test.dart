// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
// import 'package:epicmobile/pages/transaction_subviews/transaction_search_view.dart';
import 'package:epicmobile/services/address_book_service.dart';
import 'package:epicmobile/services/notes_service.dart';
// import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
// import 'package:epicmobile/widgets/custom_buttons/gradient_button.dart';
// import 'package:epicmobile/widgets/custom_buttons/simple_button.dart';
// import 'package:provider/provider.dart';
//
// import 'transaction_search_view_screen_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<AddressBookService>(returnNullOnMissingStub: true),
  MockSpec<NotesService>(returnNullOnMissingStub: true),
])
void main() {
//   testWidgets("TransactionSearchView builds correctly", (tester) async {
//     final addressBookService = MockAddressBookService();
//     final notesService = MockNotesService();
//     final navigator = mockingjay.MockNavigator();
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
//             ],
//             child: TransactionSearchView(
//               coinTicker: "FIRO",
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(Text), findsNWidgets(11));
//     expect(find.byType(SvgPicture), findsNWidgets(3));
//     expect(find.byType(TextField), findsNWidgets(2));
//     expect(find.byWidgetPredicate((widget) {
//       if (widget is Container) {
//         if (widget.decoration is BoxDecoration) {
//           if ((widget.decoration as BoxDecoration).color == Color(0xFFF0F3FA)) {
//             return true;
//           }
//         }
//       }
//       return false;
//     }), findsNWidgets(2));
//     expect(find.byType(SimpleButton), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//
//     expect(find.text("Transaction Search"), findsOneWidget);
//     expect(find.text("Transactions"), findsOneWidget);
//     expect(find.text("Received"), findsOneWidget);
//     expect(find.text("Sent"), findsOneWidget);
//     expect(find.text("Date"), findsOneWidget);
//     expect(find.text("from..."), findsOneWidget);
//     expect(find.text("to..."), findsOneWidget);
//     expect(find.text("Amount (FIRO)"), findsOneWidget);
//     expect(find.text("Keyword"), findsOneWidget);
//     expect(find.text("Cancel"), findsOneWidget);
//     expect(find.text("Apply"), findsOneWidget);
//
//     verifyNoMoreInteractions(addressBookService);
//     verifyNoMoreInteractions(notesService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap close", (tester) async {
//     final addressBookService = MockAddressBookService();
//     final notesService = MockNotesService();
//     final navigator = mockingjay.MockNavigator();
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
//               ChangeNotifierProvider<NotesService>(
//                 create: (_) => notesService,
//               ),
//             ],
//             child: TransactionSearchView(
//               coinTicker: "FIRO",
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
//     verifyNoMoreInteractions(addressBookService);
//     verifyNoMoreInteractions(notesService);
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap cancel", (tester) async {
//     final addressBookService = MockAddressBookService();
//     final notesService = MockNotesService();
//     final navigator = mockingjay.MockNavigator();
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
//               ChangeNotifierProvider<NotesService>(
//                 create: (_) => notesService,
//               ),
//             ],
//             child: TransactionSearchView(
//               coinTicker: "FIRO",
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byType(SimpleButton));
//     await tester.pump(Duration(milliseconds: 100));
//
//     verifyNoMoreInteractions(addressBookService);
//     verifyNoMoreInteractions(notesService);
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("checkboxes", (tester) async {
//     final addressBookService = MockAddressBookService();
//     final notesService = MockNotesService();
//     final navigator = mockingjay.MockNavigator();
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
//             ],
//             child: TransactionSearchView(
//               coinTicker: "FIRO",
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     var receivedCheckbox = find
//         .byKey(Key("transactionSearchViewReceivedCheckboxKey"))
//         .evaluate()
//         .single
//         .widget as Checkbox;
//     var sentCheckbox = find
//         .byKey(Key("transactionSearchViewSentCheckboxKey"))
//         .evaluate()
//         .single
//         .widget as Checkbox;
//
//     expect(receivedCheckbox.value, false);
//     expect(sentCheckbox.value, false);
//
//     await tester.tap(find.byWidget(receivedCheckbox));
//     await tester.pumpAndSettle();
//
//     receivedCheckbox = find
//         .byKey(Key("transactionSearchViewReceivedCheckboxKey"))
//         .evaluate()
//         .single
//         .widget as Checkbox;
//     sentCheckbox = find
//         .byKey(Key("transactionSearchViewSentCheckboxKey"))
//         .evaluate()
//         .single
//         .widget as Checkbox;
//
//     expect(receivedCheckbox.value, true);
//     expect(sentCheckbox.value, false);
//
//     await tester.tap(find.byWidget(sentCheckbox));
//     await tester.pumpAndSettle();
//
//     receivedCheckbox = find
//         .byKey(Key("transactionSearchViewReceivedCheckboxKey"))
//         .evaluate()
//         .single
//         .widget as Checkbox;
//     sentCheckbox = find
//         .byKey(Key("transactionSearchViewSentCheckboxKey"))
//         .evaluate()
//         .single
//         .widget as Checkbox;
//
//     expect(receivedCheckbox.value, true);
//     expect(sentCheckbox.value, true);
//
//     await tester.tap(find.byWidget(sentCheckbox));
//     await tester.tap(find.byWidget(receivedCheckbox));
//     await tester.pumpAndSettle();
//
//     receivedCheckbox = find
//         .byKey(Key("transactionSearchViewReceivedCheckboxKey"))
//         .evaluate()
//         .single
//         .widget as Checkbox;
//     sentCheckbox = find
//         .byKey(Key("transactionSearchViewSentCheckboxKey"))
//         .evaluate()
//         .single
//         .widget as Checkbox;
//
//     expect(receivedCheckbox.value, false);
//     expect(sentCheckbox.value, false);
//
//     verifyNoMoreInteractions(addressBookService);
//     verifyNoMoreInteractions(notesService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("basic date selection", (tester) async {
//     final addressBookService = MockAddressBookService();
//     final notesService = MockNotesService();
//     final navigator = mockingjay.MockNavigator();
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
//             ],
//             child: TransactionSearchView(
//               coinTicker: "FIRO",
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byKey(Key("transactionSearchViewFromDatePickerKey")));
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.text("1"));
//     await tester.pumpAndSettle();
//     await tester.tap(find.text("SELECT"));
//     await tester.pumpAndSettle();
//
//     final today = DateTime.now();
//     final month = today.month < 10 ? "0${today.month}" : "${today.month}";
//     final year = today.year % 100;
//
//     expect(find.text("from..."), findsNothing);
//     expect(find.text("$month/01/$year"), findsOneWidget);
//
//     await tester.tap(find.byKey(Key("transactionSearchViewToDatePickerKey")));
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.text("1"));
//     await tester.pumpAndSettle();
//     await tester.tap(find.text("SELECT"));
//     await tester.pumpAndSettle();
//
//     expect(find.text("to..."), findsNothing);
//     expect(find.text("$month/01/$year"), findsNWidgets(2));
//
//     verifyNoMoreInteractions(addressBookService);
//     verifyNoMoreInteractions(notesService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("select a 'to' date that is before the 'from' date",
//       (tester) async {
//     final addressBookService = MockAddressBookService();
//     final notesService = MockNotesService();
//     final navigator = mockingjay.MockNavigator();
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
//             ],
//             child: TransactionSearchView(
//               coinTicker: "FIRO",
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byKey(Key("transactionSearchViewFromDatePickerKey")));
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.text("1"));
//     await tester.pumpAndSettle();
//     await tester.tap(find.text("SELECT"));
//     await tester.pumpAndSettle();
//
//     final today = DateTime.now();
//     final month = today.month < 10 ? "0${today.month}" : "${today.month}";
//     final year = today.year % 100;
//
//     expect(find.text("from..."), findsNothing);
//     expect(find.text("$month/01/$year"), findsOneWidget);
//
//     await tester.tap(find.byKey(Key("transactionSearchViewToDatePickerKey")));
//     await tester.pumpAndSettle();
//
//     final prevYear = today.year - 1;
//
//     await tester.tap(find.text("${today.year}"));
//     await tester.pumpAndSettle();
//     await tester.tap(find.text("$prevYear"));
//     await tester.pumpAndSettle();
//     await tester.tap(find.text("1"));
//     await tester.pumpAndSettle();
//     await tester.tap(find.text("SELECT"));
//     await tester.pumpAndSettle();
//
//     expect(find.text("to..."), findsNothing);
//     expect(find.text("$month/01/${prevYear % 100}"), findsNWidgets(2));
//     expect(find.text("from..."), findsNothing);
//     expect(find.text("$month/01/$year"), findsNothing);
//
//     verifyNoMoreInteractions(addressBookService);
//     verifyNoMoreInteractions(notesService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("enter a firo amount", (tester) async {
//     final addressBookService = MockAddressBookService();
//     final notesService = MockNotesService();
//     final navigator = mockingjay.MockNavigator();
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
//             ],
//             child: TransactionSearchView(
//               coinTicker: "FIRO",
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.enterText(
//         find.byKey(Key("transactionSearchViewAmountFieldKey")), "10.001");
//     await tester.pumpAndSettle();
//
//     expect(find.text("10.001"), findsOneWidget);
//
//     await tester.enterText(
//         find.byKey(Key("transactionSearchViewAmountFieldKey")), "0,00100000");
//     await tester.pumpAndSettle();
//
//     expect(find.text("0,00100000"), findsOneWidget);
//
//     await tester.enterText(
//         find.byKey(Key("transactionSearchViewAmountFieldKey")),
//         "0,0010.000000");
//     await tester.pumpAndSettle();
//
//     expect(find.text("0,00100000"), findsOneWidget);
//
//     await tester.enterText(
//         find.byKey(Key("transactionSearchViewAmountFieldKey")), "100.,.");
//     await tester.pumpAndSettle();
//
//     expect(find.text("0,00100000"), findsOneWidget);
//
//     verifyNoMoreInteractions(addressBookService);
//     verifyNoMoreInteractions(notesService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("fill out and apply", (tester) async {
//     final addressBookService = MockAddressBookService();
//     final notesService = MockNotesService();
//     final navigator = mockingjay.MockNavigator();
//
//     when(addressBookService.addressBookEntries).thenAnswer((_) async => {});
//     when(notesService.notes).thenAnswer((_) async => {});
//
//     mockingjay
//         .when(() => navigator.push(mockingjay.any(
//             that: mockingjay.isRoute(
//                 whereName: equals("/transactionsearchresultsview")))))
//         .thenAnswer((_) async => {});
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
//             ],
//             child: TransactionSearchView(
//               coinTicker: "FIRO",
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.enterText(
//         find.byKey(Key("transactionSearchViewAmountFieldKey")), "10.001");
//     await tester.enterText(
//         find.byKey(Key("transactionSearchViewKeywordFieldKey")),
//         "some keyword");
//     await tester.pumpAndSettle();
//
//     expect(find.text("10.001"), findsOneWidget);
//     expect(find.text("some keyword"), findsOneWidget);
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pump();
//
//     verify(notesService.addListener(any)).called(1);
//     verify(notesService.notes).called(1);
//
//     verify(addressBookService.addListener(any)).called(1);
//     verify(addressBookService.addressBookEntries).called(1);
//
//     verifyNoMoreInteractions(addressBookService);
//     verifyNoMoreInteractions(notesService);
//
//     mockingjay
//         .verify(() => navigator.push(mockingjay.any(
//             that: mockingjay.isRoute(
//                 whereName: equals("/transactionsearchresultsview")))))
//         .called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
}
