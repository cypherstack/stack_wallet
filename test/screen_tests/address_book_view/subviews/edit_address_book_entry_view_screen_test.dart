// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockingjay/mockingjay.dart' as mockingjay;
// import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
// import 'package:epicmobile/notifications/campfire_alert.dart';
// import 'package:epicmobile/pages/address_book_view/subviews/edit_address_book_entry_view.dart';
// import 'package:epicmobile/services/address_book_service.dart';
import 'package:mockito/annotations.dart';
import 'package:epicmobile/services/address_book_service.dart';
import 'package:epicmobile/services/coins/manager.dart';
// import 'package:epicmobile/utilities/clipboard_interface.dart';
// import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
// import 'package:epicmobile/widgets/custom_buttons/gradient_button.dart';
// import 'package:epicmobile/widgets/custom_buttons/simple_button.dart';
// import 'package:provider/provider.dart';
//
// import 'edit_address_book_entry_view_screen_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<AddressBookService>(returnNullOnMissingStub: true),
  MockSpec<Manager>(returnNullOnMissingStub: true),
])
void main() {
//   testWidgets("EditAddressBookEntryView builds correctly", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final navigator = mockingjay.MockNavigator();
//
//     when(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .thenAnswer((_) => true);
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
//             child: EditAddressBookEntryView(
//               name: "john doe",
//               address: "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg",
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(SvgPicture), findsNWidgets(2));
//     expect(find.byType(TextField), findsNWidgets(2));
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         true);
//
//     expect(find.text("Edit Contact"), findsOneWidget);
//     expect(find.text("Paste address"), findsOneWidget);
//     expect(find.text("Enter name"), findsOneWidget);
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
//     expect(find.text("john doe"), findsOneWidget);
//     expect(find.text("Invalid address"), findsNothing);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .called(2);
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
//     final navigator = mockingjay.MockNavigator();
//
//     when(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .thenAnswer((_) => true);
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
//             ],
//             child: EditAddressBookEntryView(
//               name: "john doe",
//               address: "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg",
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(SvgPicture), findsNWidgets(2));
//     expect(find.byType(TextField), findsNWidgets(2));
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         true);
//
//     expect(find.text("Edit Contact"), findsOneWidget);
//     expect(find.text("Paste address"), findsOneWidget);
//     expect(find.text("Enter name"), findsOneWidget);
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
//     expect(find.text("john doe"), findsOneWidget);
//     expect(find.text("Invalid address"), findsNothing);
//
//     await tester.tap(find.byKey(Key("editAddressBookEntryBackButtonKey")));
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .called(2);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap cancel", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final navigator = mockingjay.MockNavigator();
//
//     when(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .thenAnswer((_) => true);
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
//             ],
//             child: EditAddressBookEntryView(
//               name: "john doe",
//               address: "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg",
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(SvgPicture), findsNWidgets(2));
//     expect(find.byType(TextField), findsNWidgets(2));
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         true);
//
//     expect(find.text("Edit Contact"), findsOneWidget);
//     expect(find.text("Paste address"), findsOneWidget);
//     expect(find.text("Enter name"), findsOneWidget);
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
//     expect(find.text("john doe"), findsOneWidget);
//     expect(find.text("Invalid address"), findsNothing);
//
//     await tester.tap(find.byType(SimpleButton));
//     await tester.pump(Duration(milliseconds: 200));
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .called(3);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap save with no changes", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final navigator = mockingjay.MockNavigator();
//
//     when(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .thenAnswer((_) => true);
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
//             ],
//             child: EditAddressBookEntryView(
//               name: "john doe",
//               address: "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg",
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(SvgPicture), findsNWidgets(2));
//     expect(find.byType(TextField), findsNWidgets(2));
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         true);
//
//     expect(find.text("Edit Contact"), findsOneWidget);
//     expect(find.text("Paste address"), findsOneWidget);
//     expect(find.text("Enter name"), findsOneWidget);
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
//     expect(find.text("john doe"), findsOneWidget);
//     expect(find.text("Invalid address"), findsNothing);
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pump(Duration(milliseconds: 200));
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .called(3);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("clear and paste new address", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final navigator = mockingjay.MockNavigator();
//     final clipboard = FakeClipboard();
//
//     clipboard
//         .setData(ClipboardData(text: "aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"));
//
//     when(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .thenAnswer((_) => true);
//     when(manager.validateAddress("aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"))
//         .thenAnswer((_) => true);
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
//             ],
//             child: EditAddressBookEntryView(
//               name: "john doe",
//               address: "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg",
//               clipboard: clipboard,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(SvgPicture), findsNWidgets(2));
//     expect(find.byType(TextField), findsNWidgets(2));
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         true);
//
//     expect(find.text("Edit Contact"), findsOneWidget);
//     expect(find.text("Paste address"), findsOneWidget);
//     expect(find.text("Enter name"), findsOneWidget);
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
//     expect(find.text("john doe"), findsOneWidget);
//     expect(find.text("Invalid address"), findsNothing);
//
//     await tester
//         .tap(find.byKey(Key("editAddressBookEntryClearAddressButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsNothing);
//     expect(find.text("Invalid address"), findsNothing);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//
//     await tester
//         .tap(find.byKey(Key("editAddressBookEntryPasteAddressButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.text("aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"), findsOneWidget);
//     expect(find.text("Invalid address"), findsNothing);
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         true);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .called(2);
//     verify(manager.validateAddress("aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"))
//         .called(2);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("clear and paste invalid address", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final navigator = mockingjay.MockNavigator();
//     final clipboard = FakeClipboard();
//
//     clipboard.setData(ClipboardData(text: "invalid"));
//
//     when(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .thenAnswer((_) => true);
//     when(manager.validateAddress("invalid")).thenAnswer((_) => false);
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
//             ],
//             child: EditAddressBookEntryView(
//               name: "john doe",
//               address: "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg",
//               clipboard: clipboard,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(SvgPicture), findsNWidgets(2));
//     expect(find.byType(TextField), findsNWidgets(2));
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         true);
//
//     expect(find.text("Edit Contact"), findsOneWidget);
//     expect(find.text("Paste address"), findsOneWidget);
//     expect(find.text("Enter name"), findsOneWidget);
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
//     expect(find.text("john doe"), findsOneWidget);
//     expect(find.text("Invalid address"), findsNothing);
//
//     await tester
//         .tap(find.byKey(Key("editAddressBookEntryClearAddressButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsNothing);
//     expect(find.text("Invalid address"), findsNothing);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//
//     await tester
//         .tap(find.byKey(Key("editAddressBookEntryPasteAddressButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.text("invalid"), findsOneWidget);
//     expect(find.text("Invalid address"), findsOneWidget);
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .called(2);
//     verify(manager.validateAddress("invalid")).called(2);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("clear and enter invalid address", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final navigator = mockingjay.MockNavigator();
//
//     when(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .thenAnswer((_) => true);
//     when(manager.validateAddress("")).thenAnswer((_) => false);
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
//             ],
//             child: EditAddressBookEntryView(
//               name: "john doe",
//               address: "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg",
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(SvgPicture), findsNWidgets(2));
//     expect(find.byType(TextField), findsNWidgets(2));
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         true);
//
//     expect(find.text("Edit Contact"), findsOneWidget);
//     expect(find.text("Paste address"), findsOneWidget);
//     expect(find.text("Enter name"), findsOneWidget);
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
//     expect(find.text("john doe"), findsOneWidget);
//     expect(find.text("Invalid address"), findsNothing);
//
//     await tester
//         .tap(find.byKey(Key("editAddressBookEntryClearAddressButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsNothing);
//     expect(find.text("Invalid address"), findsNothing);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//
//     await tester.enterText(
//         find.byKey(Key("editAddressBookEntryAddressFieldKey")), "invalid");
//     await tester.pumpAndSettle();
//
//     expect(find.text("invalid"), findsNothing);
//     expect(find.text("Invalid address"), findsNothing);
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .called(2);
//     verify(manager.validateAddress("")).called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap save with new address", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final navigator = mockingjay.MockNavigator();
//     final clipboard = FakeClipboard();
//
//     clipboard
//         .setData(ClipboardData(text: "aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"));
//
//     when(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .thenAnswer((_) => true);
//     when(manager.validateAddress("aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"))
//         .thenAnswer((_) => true);
//
//     when(addressBookService
//             .containsAddress("aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"))
//         .thenAnswer((_) async => false);
//     when(addressBookService.addAddressBookEntry(
//             "aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E", "john doe"))
//         .thenAnswer((_) async {});
//     when(addressBookService
//             .removeAddressBookEntry("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
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
//             ],
//             child: EditAddressBookEntryView(
//               name: "john doe",
//               address: "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg",
//               clipboard: clipboard,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(SvgPicture), findsNWidgets(2));
//     expect(find.byType(TextField), findsNWidgets(2));
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         true);
//
//     expect(find.text("Edit Contact"), findsOneWidget);
//     expect(find.text("Paste address"), findsOneWidget);
//     expect(find.text("Enter name"), findsOneWidget);
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
//     expect(find.text("john doe"), findsOneWidget);
//     expect(find.text("Invalid address"), findsNothing);
//
//     await tester
//         .tap(find.byKey(Key("editAddressBookEntryClearAddressButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsNothing);
//     expect(find.text("Invalid address"), findsNothing);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//
//     await tester
//         .tap(find.byKey(Key("editAddressBookEntryPasteAddressButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.text("aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"), findsOneWidget);
//     expect(find.text("Invalid address"), findsNothing);
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         true);
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pump(Duration(milliseconds: 200));
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .called(2);
//     verify(manager.validateAddress("aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"))
//         .called(3);
//
//     verify(addressBookService.addListener(any)).called(1);
//     verify(addressBookService.addAddressBookEntry(
//             "aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E", "john doe"))
//         .called(1);
//     verify(addressBookService
//             .removeAddressBookEntry("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .called(1);
//     verify(addressBookService
//             .containsAddress("aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"))
//         .called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verify(() => navigator.pop()).called(2);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap save with new name", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final navigator = mockingjay.MockNavigator();
//
//     when(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .thenAnswer((_) => true);
//
//     when(addressBookService.addAddressBookEntry(
//             "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg", "jane doe"))
//         .thenAnswer((_) async {});
//     when(addressBookService
//             .removeAddressBookEntry("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
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
//             ],
//             child: EditAddressBookEntryView(
//               name: "john doe",
//               address: "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg",
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(SvgPicture), findsNWidgets(2));
//     expect(find.byType(TextField), findsNWidgets(2));
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         true);
//
//     expect(find.text("Edit Contact"), findsOneWidget);
//     expect(find.text("Paste address"), findsOneWidget);
//     expect(find.text("Enter name"), findsOneWidget);
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
//     expect(find.text("john doe"), findsOneWidget);
//     expect(find.text("Invalid address"), findsNothing);
//
//     await tester.enterText(
//         find.byKey(Key("editAddressBookEntryNameFieldKey")), "jane doe");
//     await tester.pumpAndSettle();
//
//     expect(find.text("john doe"), findsNothing);
//     expect(find.text("jane doe"), findsOneWidget);
//
//     expect(find.text("Invalid address"), findsNothing);
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         true);
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pump(Duration(milliseconds: 200));
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .called(5);
//
//     verify(addressBookService.addListener(any)).called(1);
//     verify(addressBookService.addAddressBookEntry(
//             "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg", "jane doe"))
//         .called(1);
//     verify(addressBookService
//             .removeAddressBookEntry("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verify(() => navigator.pop()).called(2);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap save with an address already in contacts", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final navigator = mockingjay.MockNavigator();
//     final clipboard = FakeClipboard();
//
//     clipboard
//         .setData(ClipboardData(text: "aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"));
//
//     when(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .thenAnswer((_) => true);
//     when(manager.validateAddress("aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"))
//         .thenAnswer((_) => true);
//
//     when(addressBookService
//             .containsAddress("aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"))
//         .thenAnswer((_) async => true);
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
//             ],
//             child: EditAddressBookEntryView(
//               name: "john doe",
//               address: "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg",
//               clipboard: clipboard,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(SvgPicture), findsNWidgets(2));
//     expect(find.byType(TextField), findsNWidgets(2));
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         true);
//
//     expect(find.text("Edit Contact"), findsOneWidget);
//     expect(find.text("Paste address"), findsOneWidget);
//     expect(find.text("Enter name"), findsOneWidget);
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
//     expect(find.text("john doe"), findsOneWidget);
//     expect(find.text("Invalid address"), findsNothing);
//
//     await tester
//         .tap(find.byKey(Key("editAddressBookEntryClearAddressButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsNothing);
//     expect(find.text("Invalid address"), findsNothing);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//
//     await tester
//         .tap(find.byKey(Key("editAddressBookEntryPasteAddressButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.text("aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"), findsOneWidget);
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         true);
//     expect(find.text("Invalid address"), findsNothing);
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(CampfireAlert), findsOneWidget);
//     expect(find.text("The address you entered is already in your contacts!"),
//         findsOneWidget);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .called(2);
//     verify(manager.validateAddress("aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"))
//         .called(3);
//
//     verify(addressBookService.addListener(any)).called(1);
//
//     verify(addressBookService
//             .containsAddress("aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"))
//         .called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap save throws", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final navigator = mockingjay.MockNavigator();
//     final clipboard = FakeClipboard();
//
//     clipboard
//         .setData(ClipboardData(text: "aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"));
//
//     when(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .thenAnswer((_) => true);
//     when(manager.validateAddress("aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"))
//         .thenAnswer((_) => true);
//
//     when(addressBookService
//             .containsAddress("aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"))
//         .thenAnswer((_) async => false);
//     when(addressBookService.addAddressBookEntry(
//             "aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E", "john doe"))
//         .thenThrow(Exception("some problem"));
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
//             ],
//             child: EditAddressBookEntryView(
//               name: "john doe",
//               address: "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg",
//               clipboard: clipboard,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(SvgPicture), findsNWidgets(2));
//     expect(find.byType(TextField), findsNWidgets(2));
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         true);
//
//     expect(find.text("Edit Contact"), findsOneWidget);
//     expect(find.text("Paste address"), findsOneWidget);
//     expect(find.text("Enter name"), findsOneWidget);
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
//     expect(find.text("john doe"), findsOneWidget);
//     expect(find.text("Invalid address"), findsNothing);
//
//     await tester
//         .tap(find.byKey(Key("editAddressBookEntryClearAddressButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsNothing);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//
//     await tester
//         .tap(find.byKey(Key("editAddressBookEntryPasteAddressButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.text("aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"), findsOneWidget);
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         true);
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle();
//     expect(find.text("Invalid address"), findsNothing);
//
//     expect(find.byType(CampfireAlert), findsOneWidget);
//     expect(find.text("The address you entered is already in your contacts!"),
//         findsOneWidget);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .called(2);
//     verify(manager.validateAddress("aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"))
//         .called(3);
//
//     verify(addressBookService.addListener(any)).called(1);
//     verify(addressBookService.addAddressBookEntry(
//             "aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E", "john doe"))
//         .called(1);
//     verify(addressBookService
//             .containsAddress("aCN7qLWtwhhtQDv83dFW4BYN26eigB2g1E"))
//         .called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap disabled save button", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final navigator = mockingjay.MockNavigator();
//     final clipboard = FakeClipboard();
//
//     when(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .thenAnswer((_) => true);
//     when(manager.validateAddress("")).thenAnswer((_) => false);
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
//             ],
//             child: EditAddressBookEntryView(
//               name: "john doe",
//               address: "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg",
//               clipboard: clipboard,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(SvgPicture), findsNWidgets(2));
//     expect(find.byType(TextField), findsNWidgets(2));
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         true);
//
//     expect(find.text("Edit Contact"), findsOneWidget);
//     expect(find.text("Paste address"), findsOneWidget);
//     expect(find.text("Enter name"), findsOneWidget);
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
//     expect(find.text("john doe"), findsOneWidget);
//
//     await tester
//         .tap(find.byKey(Key("editAddressBookEntryClearAddressButtonKey")));
//     await tester.enterText(
//         find.byKey(Key("editAddressBookEntryNameFieldKey")), "john");
//     await tester.pumpAndSettle();
//
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsNothing);
//     expect(find.text("john doe"), findsNothing);
//     expect(find.text("john"), findsOneWidget);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//
//     expect(find.text("Invalid address"), findsNothing);
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle();
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .called(2);
//     verify(manager.validateAddress("")).called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
}
