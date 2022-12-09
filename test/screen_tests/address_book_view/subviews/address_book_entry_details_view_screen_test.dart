// import 'dart:async';
//
// import 'package:decimal/decimal.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
// import 'package:epicmobile/models/models.dart';
// import 'package:epicmobile/pages/address_book_view/subviews/address_book_entry_details_view.dart';
import 'package:epicmobile/services/address_book_service.dart';
import 'package:epicmobile/services/coins/manager.dart';
import 'package:epicmobile/services/locale_service.dart';
import 'package:epicmobile/services/notes_service.dart';
// import 'package:epicmobile/utilities/clipboard_interface.dart';
// import 'package:epicmobile/widgets/custom_buttons/gradient_button.dart';
// import 'package:epicmobile/widgets/transaction_card.dart';
// import 'package:provider/provider.dart';
//
// import '../../../sample_data/transaction_data_samples.dart';
// import 'address_book_entry_details_view_screen_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<AddressBookService>(returnNullOnMissingStub: true),
  MockSpec<Manager>(returnNullOnMissingStub: true),
  MockSpec<NotesService>(returnNullOnMissingStub: true),
  MockSpec<LocaleService>(returnNullOnMissingStub: true),
])
void main() {
//   testWidgets("AddressBookDetailsView builds correctly", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final navigator = mockingjay.MockNavigator();
//
//     when(manager.transactionData).thenAnswer(Future<TransactionData>(() {
//       FutureOr<TransactionData> bob = TransactionData();
//       return bob;
//     }) as Future<TransactionData> Function(Invocation));
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
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//             ],
//             child: AddressBookEntryDetailsView(
//                 name: "john doe",
//                 address: "aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"),
//           ),
//         ),
//       ),
//     );
//
//     expect(find.text("john doe"), findsOneWidget);
//     expect(find.text("Address"), findsOneWidget);
//     expect(find.text("aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"), findsOneWidget);
//     expect(find.text("SEND"), findsOneWidget);
//     expect(find.text("Transaction History"), findsOneWidget);
//
//     expect(find.byKey(Key("addressBookEntryDetailsCopyAddressButtonKey")),
//         findsOneWidget);
//     expect(find.byKey(Key("addressBookEntryDetailsEditEntryButtonKey")),
//         findsOneWidget);
//
//     expect(find.byType(SvgPicture), findsNWidgets(4));
//     expect(find.byType(TextField), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SpinKitThreeBounce), findsOneWidget);
//
//     verify(manager.transactionData).called(1);
//     verify(manager.addListener(any)).called(1);
//
//     verify(addressBookService.addListener(any)).called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets(
//       "AddressBookDetailsView loads correctly with three matching wallet transactions history",
//       (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final notesService = MockNotesService();
//     final localeService = MockLocaleService();
//     final navigator = mockingjay.MockNavigator();
//
//     when(manager.transactionData)
//         .thenAnswer((_) async => transactionDataFromJsonChunks);
//
//     when(localeService.locale).thenAnswer((_) => "en_US");
//
//     when(manager.fiatPrice).thenAnswer((_) async => Decimal.one);
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
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
//             child: AddressBookEntryDetailsView(
//                 name: "john doe",
//                 address: "aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"),
//           ),
//         ),
//       ),
//     );
//     await tester.pump();
//
//     expect(find.text("john doe"), findsOneWidget);
//     expect(find.text("Address"), findsOneWidget);
//     expect(find.text("aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"), findsOneWidget);
//     expect(find.text("SEND"), findsOneWidget);
//     expect(find.text("Transaction History"), findsOneWidget);
//
//     expect(find.byKey(Key("addressBookEntryDetailsCopyAddressButtonKey")),
//         findsOneWidget);
//     expect(find.byKey(Key("addressBookEntryDetailsEditEntryButtonKey")),
//         findsOneWidget);
//
//     expect(find.byType(SvgPicture), findsNWidgets(4));
//     expect(find.byType(TransactionCard), findsNWidgets(3));
//     expect(find.byType(TextField), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.transactionData).called(1);
//     verify(manager.fiatPrice).called(3);
//     verify(manager.coinTicker).called(3);
//
//     verify(notesService.addListener(any)).called(1);
//
//     verify(addressBookService.addListener(any)).called(1);
//
//     verify(localeService.addListener(any)).called(1);
//     verify(localeService.locale).called(6);
//
//     verifyNoMoreInteractions(localeService);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(notesService);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets(
//       "AddressBookDetailsView loads correctly with no wallet transaction history",
//       (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final navigator = mockingjay.MockNavigator();
//
//     when(manager.transactionData).thenAnswer(
//         ((_) async => null) as Future<TransactionData> Function(Invocation));
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
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//             ],
//             child: AddressBookEntryDetailsView(
//                 name: "john doe",
//                 address: "aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"),
//           ),
//         ),
//       ),
//     );
//     await tester.pump();
//
//     expect(find.text("john doe"), findsOneWidget);
//     expect(find.text("Address"), findsOneWidget);
//     expect(find.text("aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"), findsOneWidget);
//     expect(find.text("SEND"), findsOneWidget);
//     expect(find.text("Transaction History"), findsOneWidget);
//     expect(find.text("NO TRANSACTIONS FOUND"), findsOneWidget);
//
//     expect(find.byKey(Key("addressBookEntryDetailsCopyAddressButtonKey")),
//         findsOneWidget);
//     expect(find.byKey(Key("addressBookEntryDetailsEditEntryButtonKey")),
//         findsOneWidget);
//
//     expect(find.byType(SvgPicture), findsNWidgets(5));
//     expect(find.byType(TextField), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.transactionData).called(1);
//
//     verify(addressBookService.addListener(any)).called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap back", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final notesService = MockNotesService();
//     final localeService = MockLocaleService();
//     final navigator = mockingjay.MockNavigator();
//
//     when(manager.transactionData)
//         .thenAnswer((_) async => transactionDataFromJsonChunks);
//
//     when(localeService.locale).thenAnswer((_) => "en_US");
//
//     when(manager.fiatPrice).thenAnswer((_) async => Decimal.one);
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
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
//             child: AddressBookEntryDetailsView(
//                 name: "john doe",
//                 address: "aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"),
//           ),
//         ),
//       ),
//     );
//     await tester.pump();
//
//     expect(find.text("john doe"), findsOneWidget);
//     expect(find.text("Address"), findsOneWidget);
//     expect(find.text("aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"), findsOneWidget);
//     expect(find.text("SEND"), findsOneWidget);
//     expect(find.text("Transaction History"), findsOneWidget);
//
//     expect(find.byKey(Key("addressBookEntryDetailsCopyAddressButtonKey")),
//         findsOneWidget);
//     expect(find.byKey(Key("addressBookEntryDetailsEditEntryButtonKey")),
//         findsOneWidget);
//
//     expect(find.byType(SvgPicture), findsNWidgets(4));
//     expect(find.byType(TransactionCard), findsNWidgets(3));
//     expect(find.byType(TextField), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//
//     await tester.tap(find.byKey(Key("addressBookDetailsBackButtonKey")));
//     await tester.pump(Duration(milliseconds: 100));
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.transactionData).called(2);
//     verify(manager.fiatPrice).called(3);
//     verify(manager.coinTicker).called(3);
//
//     verify(notesService.addListener(any)).called(1);
//
//     verify(addressBookService.addListener(any)).called(1);
//
//     verify(localeService.addListener(any)).called(1);
//     verify(localeService.locale).called(6);
//
//     verifyNoMoreInteractions(localeService);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(notesService);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap options then tap anywhere but the context menu",
//       (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final notesService = MockNotesService();
//     final localeService = MockLocaleService();
//     final navigator = mockingjay.MockNavigator();
//
//     when(manager.transactionData)
//         .thenAnswer((_) async => transactionDataFromJsonChunks);
//
//     when(localeService.locale).thenAnswer((_) => "en_US");
//
//     when(manager.fiatPrice).thenAnswer((_) async => Decimal.one);
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
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
//             child: AddressBookEntryDetailsView(
//                 name: "john doe",
//                 address: "aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"),
//           ),
//         ),
//       ),
//     );
//     await tester.pump();
//
//     expect(find.text("john doe"), findsOneWidget);
//     expect(find.text("Address"), findsOneWidget);
//     expect(find.text("aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"), findsOneWidget);
//     expect(find.text("SEND"), findsOneWidget);
//     expect(find.text("Transaction History"), findsOneWidget);
//
//     expect(find.byKey(Key("addressBookEntryDetailsCopyAddressButtonKey")),
//         findsOneWidget);
//     expect(find.byKey(Key("addressBookEntryDetailsEditEntryButtonKey")),
//         findsOneWidget);
//
//     expect(find.byType(SvgPicture), findsNWidgets(4));
//     expect(find.byType(TransactionCard), findsNWidgets(3));
//     expect(find.byType(TextField), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//
//     await tester.tap(find.byKey(Key("addressBookDetailsDeleteButtonKey")));
//     await tester.pump(Duration(milliseconds: 100));
//
//     expect(find.text("Delete address"), findsOneWidget);
//
//     await tester.tapAt(Offset(10, 300));
//     await tester.pump(Duration(milliseconds: 100));
//     expect(find.text("Delete address"), findsNothing);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.transactionData).called(2);
//     verify(manager.fiatPrice).called(6);
//     verify(manager.coinTicker).called(6);
//
//     verify(notesService.addListener(any)).called(1);
//
//     verify(addressBookService.addListener(any)).called(1);
//
//     verify(localeService.addListener(any)).called(1);
//     verify(localeService.locale).called(12);
//
//     verifyNoMoreInteractions(localeService);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(notesService);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap options then tap delete", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final notesService = MockNotesService();
//     final localeService = MockLocaleService();
//     final navigator = mockingjay.MockNavigator();
//
//     when(localeService.locale).thenAnswer((_) => "en_US");
//
//     when(manager.transactionData)
//         .thenAnswer((_) async => transactionDataFromJsonChunks);
//
//     when(manager.fiatPrice).thenAnswer((_) async => Decimal.one);
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
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
//             child: AddressBookEntryDetailsView(
//                 name: "john doe",
//                 address: "aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"),
//           ),
//         ),
//       ),
//     );
//     await tester.pump();
//
//     expect(find.text("john doe"), findsOneWidget);
//     expect(find.text("Address"), findsOneWidget);
//     expect(find.text("aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"), findsOneWidget);
//     expect(find.text("SEND"), findsOneWidget);
//     expect(find.text("Transaction History"), findsOneWidget);
//
//     expect(find.byKey(Key("addressBookEntryDetailsCopyAddressButtonKey")),
//         findsOneWidget);
//     expect(find.byKey(Key("addressBookEntryDetailsEditEntryButtonKey")),
//         findsOneWidget);
//
//     expect(find.byType(SvgPicture), findsNWidgets(4));
//     expect(find.byType(TransactionCard), findsNWidgets(3));
//     expect(find.byType(TextField), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//
//     await tester.tap(find.byKey(Key("addressBookDetailsDeleteButtonKey")));
//     await tester.pump(Duration(milliseconds: 100));
//
//     expect(find.text("Delete address"), findsOneWidget);
//
//     await tester
//         .tap(find.byKey(Key("addressBookDetailsContextMenuDeleteButtonKey")));
//     await tester.pump(Duration(milliseconds: 100));
//     expect(find.text("Do you want to delete john doe?"), findsOneWidget);
//     expect(find.text("CANCEL"), findsOneWidget);
//     expect(find.text("DELETE"), findsOneWidget);
//     expect(find.byType(DeleteContactConfirmationDialog), findsOneWidget);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.transactionData).called(2);
//     verify(manager.fiatPrice).called(6);
//     verify(manager.coinTicker).called(6);
//
//     verify(notesService.addListener(any)).called(1);
//
//     verify(addressBookService.addListener(any)).called(1);
//
//     verify(localeService.addListener(any)).called(1);
//     verify(localeService.locale).called(12);
//
//     verifyNoMoreInteractions(localeService);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(notesService);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("cancel delete", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final notesService = MockNotesService();
//     final localeService = MockLocaleService();
//     final navigator = mockingjay.MockNavigator();
//
//     when(localeService.locale).thenAnswer((_) => "en_US");
//
//     when(manager.transactionData)
//         .thenAnswer((_) async => transactionDataFromJsonChunks);
//
//     when(manager.fiatPrice).thenAnswer((_) async => Decimal.one);
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
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
//             child: AddressBookEntryDetailsView(
//                 name: "john doe",
//                 address: "aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"),
//           ),
//         ),
//       ),
//     );
//     await tester.pump();
//
//     expect(find.text("john doe"), findsOneWidget);
//     expect(find.text("Address"), findsOneWidget);
//     expect(find.text("aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"), findsOneWidget);
//     expect(find.text("SEND"), findsOneWidget);
//     expect(find.text("Transaction History"), findsOneWidget);
//
//     expect(find.byKey(Key("addressBookEntryDetailsCopyAddressButtonKey")),
//         findsOneWidget);
//     expect(find.byKey(Key("addressBookEntryDetailsEditEntryButtonKey")),
//         findsOneWidget);
//
//     expect(find.byType(SvgPicture), findsNWidgets(4));
//     expect(find.byType(TransactionCard), findsNWidgets(3));
//     expect(find.byType(TextField), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//
//     await tester.tap(find.byKey(Key("addressBookDetailsDeleteButtonKey")));
//     await tester.pump(Duration(milliseconds: 100));
//
//     expect(find.text("Delete address"), findsOneWidget);
//
//     await tester
//         .tap(find.byKey(Key("addressBookDetailsContextMenuDeleteButtonKey")));
//     await tester.pump(Duration(milliseconds: 100));
//     expect(find.text("Do you want to delete john doe?"), findsOneWidget);
//     expect(find.text("CANCEL"), findsOneWidget);
//     expect(find.text("DELETE"), findsOneWidget);
//     expect(find.byType(DeleteContactConfirmationDialog), findsOneWidget);
//
//     await tester
//         .tap(find.byKey(Key("deleteContactConfirmationDialogCancelButtonKey")));
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.transactionData).called(2);
//     verify(manager.fiatPrice).called(6);
//     verify(manager.coinTicker).called(6);
//
//     verify(notesService.addListener(any)).called(1);
//
//     verify(addressBookService.addListener(any)).called(1);
//
//     verify(localeService.addListener(any)).called(1);
//     verify(localeService.locale).called(12);
//
//     verifyNoMoreInteractions(localeService);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(notesService);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("confirm delete", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final notesService = MockNotesService();
//     final localeService = MockLocaleService();
//     final navigator = mockingjay.MockNavigator();
//
//     when(localeService.locale).thenAnswer((_) => "en_US");
//
//     when(manager.transactionData)
//         .thenAnswer((_) async => transactionDataFromJsonChunks);
//
//     when(manager.fiatPrice).thenAnswer((_) async => Decimal.one);
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
//
//     when(addressBookService
//             .removeAddressBookEntry("aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"))
//         .thenAnswer((_) async {});
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
//             child: AddressBookEntryDetailsView(
//                 name: "john doe",
//                 address: "aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"),
//           ),
//         ),
//       ),
//     );
//     await tester.pump();
//
//     expect(find.text("john doe"), findsOneWidget);
//     expect(find.text("Address"), findsOneWidget);
//     expect(find.text("aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"), findsOneWidget);
//     expect(find.text("SEND"), findsOneWidget);
//     expect(find.text("Transaction History"), findsOneWidget);
//
//     expect(find.byKey(Key("addressBookEntryDetailsCopyAddressButtonKey")),
//         findsOneWidget);
//     expect(find.byKey(Key("addressBookEntryDetailsEditEntryButtonKey")),
//         findsOneWidget);
//
//     expect(find.byType(SvgPicture), findsNWidgets(4));
//     expect(find.byType(TransactionCard), findsNWidgets(3));
//     expect(find.byType(TextField), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//
//     await tester.tap(find.byKey(Key("addressBookDetailsDeleteButtonKey")));
//     await tester.pump(Duration(milliseconds: 100));
//
//     expect(find.text("Delete address"), findsOneWidget);
//
//     await tester
//         .tap(find.byKey(Key("addressBookDetailsContextMenuDeleteButtonKey")));
//     await tester.pump(Duration(milliseconds: 100));
//     expect(find.text("Do you want to delete john doe?"), findsOneWidget);
//     expect(find.text("CANCEL"), findsOneWidget);
//     expect(find.text("DELETE"), findsOneWidget);
//     expect(find.byType(DeleteContactConfirmationDialog), findsOneWidget);
//
//     await tester
//         .tap(find.byKey(Key("deleteContactConfirmationDialogDeleteButtonKey")));
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.transactionData).called(2);
//     verify(manager.fiatPrice).called(6);
//     verify(manager.coinTicker).called(6);
//
//     verify(notesService.addListener(any)).called(1);
//
//     verify(addressBookService.addListener(any)).called(1);
//     verify(addressBookService
//             .removeAddressBookEntry("aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"))
//         .called(1);
//
//     verify(localeService.addListener(any)).called(1);
//     verify(localeService.locale).called(12);
//
//     verifyNoMoreInteractions(localeService);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(notesService);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap copy address", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final notesService = MockNotesService();
//     final localeService = MockLocaleService();
//     final navigator = mockingjay.MockNavigator();
//     final clipboard = FakeClipboard();
//
//     when(manager.transactionData)
//         .thenAnswer((_) async => transactionDataFromJsonChunks);
//
//     when(localeService.locale).thenAnswer((_) => "en_US");
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
//             child: AddressBookEntryDetailsView(
//                 clipboard: clipboard,
//                 name: "john doe",
//                 address: "aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"),
//           ),
//         ),
//       ),
//     );
//     await tester.pump();
//
//     expect(find.text("john doe"), findsOneWidget);
//     expect(find.text("Address"), findsOneWidget);
//     expect(find.text("aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"), findsOneWidget);
//     expect(find.text("SEND"), findsOneWidget);
//     expect(find.text("Transaction History"), findsOneWidget);
//
//     expect(find.byKey(Key("addressBookEntryDetailsCopyAddressButtonKey")),
//         findsOneWidget);
//     expect(find.byKey(Key("addressBookEntryDetailsEditEntryButtonKey")),
//         findsOneWidget);
//
//     expect(find.byType(SvgPicture), findsNWidgets(4));
//     expect(find.byType(TransactionCard), findsNWidgets(3));
//     expect(find.byType(TextField), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//
//     await tester
//         .tap(find.byKey(Key("addressBookEntryDetailsCopyAddressButtonKey")));
//     await tester.pump(Duration(milliseconds: 100));
//
//     expect(find.text("Address copied to clipboard"), findsOneWidget);
//     await tester.pump(Duration(seconds: 2));
//
//     expect(find.text("Address copied to clipboard"), findsNothing);
//     expect((await clipboard.getData(Clipboard.kTextPlain)).text,
//         "aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E");
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.transactionData).called(1);
//     verify(manager.fiatPrice).called(3);
//     verify(manager.coinTicker).called(3);
//
//     verify(notesService.addListener(any)).called(1);
//
//     verify(addressBookService.addListener(any)).called(1);
//
//     verify(localeService.addListener(any)).called(1);
//     verify(localeService.locale).called(6);
//
//     verifyNoMoreInteractions(localeService);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(notesService);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap edit/pencil icon", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final notesService = MockNotesService();
//     final localeService = MockLocaleService();
//     final navigator = mockingjay.MockNavigator();
//     final clipboard = FakeClipboard();
//
//     when(manager.transactionData)
//         .thenAnswer((_) async => transactionDataFromJsonChunks);
//
//     when(localeService.locale).thenAnswer((_) => "en_US");
//
//     mockingjay
//         .when(() => navigator.push(mockingjay.any()))
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
//             child: AddressBookEntryDetailsView(
//                 clipboard: clipboard,
//                 name: "john doe",
//                 address: "aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"),
//           ),
//         ),
//       ),
//     );
//     await tester.pump();
//
//     expect(find.text("john doe"), findsOneWidget);
//     expect(find.text("Address"), findsOneWidget);
//     expect(find.text("aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"), findsOneWidget);
//     expect(find.text("SEND"), findsOneWidget);
//     expect(find.text("Transaction History"), findsOneWidget);
//
//     expect(find.byKey(Key("addressBookEntryDetailsCopyAddressButtonKey")),
//         findsOneWidget);
//     expect(find.byKey(Key("addressBookEntryDetailsEditEntryButtonKey")),
//         findsOneWidget);
//
//     expect(find.byType(SvgPicture), findsNWidgets(4));
//     expect(find.byType(TransactionCard), findsNWidgets(3));
//     expect(find.byType(TextField), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//
//     await tester
//         .tap(find.byKey(Key("addressBookEntryDetailsEditEntryButtonKey")));
//     await tester.pump(Duration(milliseconds: 100));
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.transactionData).called(1);
//     verify(manager.fiatPrice).called(3);
//     verify(manager.coinTicker).called(3);
//
//     verify(notesService.addListener(any)).called(1);
//
//     verify(addressBookService.addListener(any)).called(1);
//
//     verify(localeService.addListener(any)).called(1);
//     verify(localeService.locale).called(6);
//
//     verifyNoMoreInteractions(localeService);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(notesService);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verify(() => navigator.push(mockingjay.any())).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap send", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final notesService = MockNotesService();
//     final navigator = mockingjay.MockNavigator();
//     final localeService = MockLocaleService();
//     final clipboard = FakeClipboard();
//
//     when(manager.transactionData)
//         .thenAnswer((_) async => transactionDataFromJsonChunks);
//
//     when(localeService.locale).thenAnswer((_) => "en_US");
//
//     mockingjay
//         .when(() =>
//             navigator.pushAndRemoveUntil(mockingjay.any(), mockingjay.any()))
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
//             child: AddressBookEntryDetailsView(
//                 clipboard: clipboard,
//                 name: "john doe",
//                 address: "aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"),
//           ),
//         ),
//       ),
//     );
//     await tester.pump();
//
//     expect(find.text("john doe"), findsOneWidget);
//     expect(find.text("Address"), findsOneWidget);
//     expect(find.text("aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"), findsOneWidget);
//     expect(find.text("SEND"), findsOneWidget);
//     expect(find.text("Transaction History"), findsOneWidget);
//
//     expect(find.byKey(Key("addressBookEntryDetailsCopyAddressButtonKey")),
//         findsOneWidget);
//     expect(find.byKey(Key("addressBookEntryDetailsEditEntryButtonKey")),
//         findsOneWidget);
//
//     expect(find.byType(SvgPicture), findsNWidgets(4));
//     expect(find.byType(TransactionCard), findsNWidgets(3));
//     expect(find.byType(TextField), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pump(Duration(milliseconds: 100));
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.transactionData).called(1);
//     verify(manager.fiatPrice).called(3);
//     verify(manager.coinTicker).called(3);
//
//     verify(notesService.addListener(any)).called(1);
//
//     verify(addressBookService.addListener(any)).called(1);
//
//     verify(localeService.addListener(any)).called(1);
//     verify(localeService.locale).called(6);
//
//     verifyNoMoreInteractions(localeService);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(notesService);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay
//         .verify(() =>
//             navigator.pushAndRemoveUntil(mockingjay.any(), mockingjay.any()))
//         .called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
}
