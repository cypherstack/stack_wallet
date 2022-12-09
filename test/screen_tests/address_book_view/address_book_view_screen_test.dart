// import 'package:flutter/material.dart';
// import 'package:flutter_feather_icons/flutter_feather_icons.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
// import 'package:epicmobile/pages/address_book_view/address_book_view.dart';
import 'package:epicmobile/services/address_book_service.dart';
// import 'package:epicmobile/widgets/address_book_card.dart';
// import 'package:provider/provider.dart';
//
// import 'address_book_view_screen_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<AddressBookService>(returnNullOnMissingStub: true),
])
void main() {
//   testWidgets("AddressBookView builds correctly", (tester) async {
//     final addressBookService = MockAddressBookService();
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<AddressBookService>(
//               create: (_) => addressBookService,
//             ),
//           ],
//           child: AddressBookView(),
//         ),
//       ),
//     );
//
//     expect(find.byKey(Key("addressBookAddButton")), findsOneWidget);
//     expect(find.byKey(Key("addressBookBackButton")), findsOneWidget);
//     expect(find.byType(SvgPicture), findsNWidgets(3));
//     expect(find.byIcon(FeatherIcons.search), findsOneWidget);
//     expect(find.byType(TextField), findsOneWidget);
//     expect(find.textContaining("Address Book"), findsOneWidget);
//     expect(find.textContaining("NO ADDRESSES YET"), findsOneWidget);
//   });
//
//   testWidgets("AddressBookView loads null contacts", (tester) async {
//     final addressBookService = MockAddressBookService();
//
//     when(addressBookService.addressBookEntries).thenAnswer(((_) async => null)
//         as Future<Map<String, String>> Function(Invocation));
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<AddressBookService>(
//               create: (_) => addressBookService,
//             ),
//           ],
//           child: AddressBookView(),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byKey(Key("addressBookAddButton")), findsOneWidget);
//     expect(find.byKey(Key("addressBookBackButton")), findsOneWidget);
//     expect(find.byType(SvgPicture), findsNWidgets(3));
//     expect(find.byIcon(FeatherIcons.search), findsOneWidget);
//     expect(find.byType(TextField), findsOneWidget);
//     expect(find.textContaining("Address Book"), findsOneWidget);
//     expect(find.textContaining("NO ADDRESSES YET"), findsOneWidget);
//
//     verify(addressBookService.addressBookEntries).called(1);
//   });
//
//   testWidgets("AddressBookView loads no contacts", (tester) async {
//     final addressBookService = MockAddressBookService();
//
//     when(addressBookService.addressBookEntries).thenAnswer((_) async => {});
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<AddressBookService>(
//               create: (_) => addressBookService,
//             ),
//           ],
//           child: AddressBookView(),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byKey(Key("addressBookAddButton")), findsOneWidget);
//     expect(find.byKey(Key("addressBookBackButton")), findsOneWidget);
//     expect(find.byType(SvgPicture), findsNWidgets(3));
//     expect(find.byIcon(FeatherIcons.search), findsOneWidget);
//     expect(find.byType(TextField), findsOneWidget);
//     expect(find.textContaining("Address Book"), findsOneWidget);
//     expect(find.textContaining("NO ADDRESSES YET"), findsOneWidget);
//
//     verify(addressBookService.addressBookEntries).called(1);
//   });
//
//   testWidgets("AddressBookView loads two contacts", (tester) async {
//     final addressBookService = MockAddressBookService();
//
//     when(addressBookService.addressBookEntries).thenAnswer((_) async => {
//           "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg": "John Doe",
//           "aMyzmcgns2bEEasMyESW4zx3EzjsWfLLc9": "Jane Doe",
//         });
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<AddressBookService>(
//               create: (_) => addressBookService,
//             ),
//           ],
//           child: AddressBookView(),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byKey(Key("addressBookAddButton")), findsOneWidget);
//     expect(find.byKey(Key("addressBookBackButton")), findsOneWidget);
//     expect(find.byType(SvgPicture), findsNWidgets(4));
//     expect(find.byIcon(FeatherIcons.search), findsOneWidget);
//     expect(find.byType(TextField), findsOneWidget);
//     expect(find.textContaining("Address Book"), findsOneWidget);
//     expect(find.textContaining("Jane Doe"), findsOneWidget);
//     expect(find.textContaining("John Doe"), findsOneWidget);
//     expect(find.byType(AddressBookCard), findsNWidgets(2));
//
//     verify(addressBookService.addressBookEntries).called(1);
//   });
//
//   testWidgets("simple search", (tester) async {
//     final addressBookService = MockAddressBookService();
//
//     when(addressBookService.addressBookEntries).thenAnswer((_) async => {
//           "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg": "John Doe",
//           "aMyzmcgns2bEEasMyESW4zx3EzjsWfLLc9": "Jane Doe",
//         });
//
//     when(addressBookService.search(captureAny))
//         .thenAnswer((realInvocation) async {
//       final searchString = realInvocation.positionalArguments.first as String?;
//
//       var result = {
//         "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg": "John Doe",
//         "aMyzmcgns2bEEasMyESW4zx3EzjsWfLLc9": "Jane Doe",
//       };
//
//       result.removeWhere((key, value) =>
//           (!key.contains(searchString!) && !value.contains(searchString)));
//       return result;
//     });
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<AddressBookService>(
//               create: (_) => addressBookService,
//             ),
//           ],
//           child: AddressBookView(),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byKey(Key("addressBookAddButton")), findsOneWidget);
//     expect(find.byKey(Key("addressBookBackButton")), findsOneWidget);
//     expect(find.byType(SvgPicture), findsNWidgets(4));
//     expect(find.byIcon(FeatherIcons.search), findsOneWidget);
//     expect(find.byType(TextField), findsOneWidget);
//     expect(find.textContaining("Address Book"), findsOneWidget);
//     expect(find.textContaining("Jane Doe"), findsOneWidget);
//     expect(find.textContaining("John Doe"), findsOneWidget);
//     expect(find.byType(AddressBookCard), findsNWidgets(2));
//
//     verify(addressBookService.addressBookEntries).called(1);
//
//     await tester.enterText(find.byType(TextField), "Jan");
//
//     await tester.pumpAndSettle();
//
//     expect(find.byKey(Key("addressBookAddButton")), findsOneWidget);
//     expect(find.byKey(Key("addressBookBackButton")), findsOneWidget);
//     expect(find.byType(SvgPicture), findsNWidgets(3));
//     expect(find.byIcon(FeatherIcons.search), findsOneWidget);
//     expect(find.byType(TextField), findsOneWidget);
//     expect(find.textContaining("Address Book"), findsOneWidget);
//     expect(find.textContaining("Jane Doe"), findsOneWidget);
//     expect(find.textContaining("John Doe"), findsNothing);
//     expect(find.byType(AddressBookCard), findsOneWidget);
//   });
//
//   testWidgets("tap back", (tester) async {
//     final addressBookService = MockAddressBookService();
//     final navigator = mockingjay.MockNavigator();
//
//     when(addressBookService.addressBookEntries).thenAnswer((_) async => {
//           "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg": "John Doe",
//           "aMyzmcgns2bEEasMyESW4zx3EzjsWfLLc9": "Jane Doe",
//         });
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) async => {});
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<AddressBookService>(
//                 create: (_) => addressBookService,
//               ),
//             ],
//             child: AddressBookView(),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byKey(Key("addressBookAddButton")), findsOneWidget);
//     expect(find.byKey(Key("addressBookBackButton")), findsOneWidget);
//     expect(find.byType(SvgPicture), findsNWidgets(4));
//     expect(find.byIcon(FeatherIcons.search), findsOneWidget);
//     expect(find.byType(TextField), findsOneWidget);
//     expect(find.textContaining("Address Book"), findsOneWidget);
//     expect(find.textContaining("Jane Doe"), findsOneWidget);
//     expect(find.textContaining("John Doe"), findsOneWidget);
//     expect(find.byType(AddressBookCard), findsNWidgets(2));
//
//     verify(addressBookService.addressBookEntries).called(1);
//
//     await tester.tap(find.byKey(Key("addressBookBackButton")));
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//   });
//
//   testWidgets("tap add", (tester) async {
//     final addressBookService = MockAddressBookService();
//     final navigator = mockingjay.MockNavigator();
//
//     when(addressBookService.addressBookEntries).thenAnswer((_) async => {
//           "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg": "John Doe",
//           "aMyzmcgns2bEEasMyESW4zx3EzjsWfLLc9": "Jane Doe",
//         });
//     mockingjay
//         .when(() => navigator.pushNamed("/addaddressbookentry"))
//         .thenAnswer((_) async => {});
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<AddressBookService>(
//                 create: (_) => addressBookService,
//               ),
//             ],
//             child: AddressBookView(),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byKey(Key("addressBookAddButton")), findsOneWidget);
//     expect(find.byKey(Key("addressBookBackButton")), findsOneWidget);
//     expect(find.byType(SvgPicture), findsNWidgets(4));
//     expect(find.byIcon(FeatherIcons.search), findsOneWidget);
//     expect(find.byType(TextField), findsOneWidget);
//     expect(find.textContaining("Address Book"), findsOneWidget);
//     expect(find.textContaining("Jane Doe"), findsOneWidget);
//     expect(find.textContaining("John Doe"), findsOneWidget);
//     expect(find.byType(AddressBookCard), findsNWidgets(2));
//
//     verify(addressBookService.addressBookEntries).called(1);
//
//     await tester.tap(find.byKey(Key("addressBookAddButton")));
//
//     mockingjay
//         .verify(() => navigator.pushNamed("/addaddressbookentry"))
//         .called(1);
//   });
}
