// import 'package:barcode_scan2/barcode_scan2.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
// import 'package:epicmobile/notifications/campfire_alert.dart';
// import 'package:epicmobile/pages/address_book_view/subviews/add_address_book_entry_view.dart';
import 'package:epicmobile/services/address_book_service.dart';
import 'package:epicmobile/services/coins/manager.dart';
import 'package:epicmobile/utilities/barcode_scanner_interface.dart';
// import 'package:epicmobile/utilities/clipboard_interface.dart';
// import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
// import 'package:epicmobile/widgets/custom_buttons/gradient_button.dart';
// import 'package:epicmobile/widgets/custom_buttons/simple_button.dart';
// import 'package:provider/provider.dart';
//
// import 'add_address_book_view_screen_test.mocks.dart';

@GenerateMocks([
  BarcodeScannerWrapper
], customMocks: [
  MockSpec<AddressBookService>(returnNullOnMissingStub: true),
  MockSpec<Manager>(returnNullOnMissingStub: true),
])
void main() {
//   testWidgets("AddAddressBookEntryView builds correctly", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<AddressBookService>(
//               create: (_) => addressBookService,
//             ),
//             ChangeNotifierProvider<Manager>(
//               create: (_) => manager,
//             ),
//           ],
//           child: AddAddressBookEntryView(),
//         ),
//       ),
//     );
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//
//     expect(find.text("New address"), findsOneWidget);
//     expect(find.text("Paste address"), findsOneWidget);
//     expect(find.text("Enter name"), findsOneWidget);
//     expect(find.text("CANCEL"), findsOneWidget);
//     expect(find.text("SAVE"), findsOneWidget);
//
//     expect(find.byType(SvgPicture), findsNWidgets(3));
//     expect(find.byType(TextField), findsNWidgets(2));
//
//     expect(find.byType(SimpleButton), findsOneWidget);
//
//     final button =
//         find.byType(GradientButton).evaluate().single.widget as GradientButton;
//
//     expect(find.byWidget(button), findsOneWidget);
//     expect(button.enabled, false);
//
//     verify(manager.addListener(any)).called(1);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(addressBookService);
//   });
//
//   testWidgets("tap back", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final navigator = mockingjay.MockNavigator();
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) async => {});
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
//             child: AddAddressBookEntryView(),
//           ),
//         ),
//       ),
//     );
//
//     await tester.tap(find.byType(AppBarIconButton));
//     await tester.pumpAndSettle();
//
//     verify(manager.addListener(any)).called(1);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap cancel", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final navigator = mockingjay.MockNavigator();
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) async => {});
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
//             child: AddAddressBookEntryView(),
//           ),
//         ),
//       ),
//     );
//
//     await tester.tap(find.byType(SimpleButton));
//     await tester.pumpAndSettle();
//
//     verify(manager.addListener(any)).called(1);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap disabled save button", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
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
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//             ],
//             child: AddAddressBookEntryView(),
//           ),
//         ),
//       ),
//     );
//
//     final button =
//         find.byType(GradientButton).evaluate().single.widget as GradientButton;
//
//     expect(button.enabled, false);
//
//     await tester.tap(find.byWidget(button));
//     await tester.pumpAndSettle();
//
//     verify(manager.addListener(any)).called(1);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap scan qr with valid firo uri A", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final navigator = mockingjay.MockNavigator();
//     final scanner = MockBarcodeScannerWrapper();
//
//     when(scanner.scan()).thenAnswer((_) async => ScanResult(
//         rawContent: "firo:a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg?label=john"));
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
//             child: AddAddressBookEntryView(
//               barcodeScanner: scanner,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byKey(Key("addAddressBookEntryScanQrButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
//     expect(find.text("john"), findsOneWidget);
//     expect(find.text("Invalid address"), findsNothing);
//
//     expect(
//         find.byKey(Key("addAddressBookClearAddressButtonKey")), findsOneWidget);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         true);
//
//     verify(scanner.scan()).called(1);
//     verifyNoMoreInteractions(scanner);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .called(2);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap scan qr throws", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final navigator = mockingjay.MockNavigator();
//     final scanner = MockBarcodeScannerWrapper();
//
//     when(scanner.scan())
//         .thenThrow(PlatformException(code: "CAMERA_PERMISSION_DENIED"));
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
//             child: AddAddressBookEntryView(
//               barcodeScanner: scanner,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byKey(Key("addAddressBookEntryScanQrButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsNothing);
//     expect(find.text("Invalid address"), findsNothing);
//
//     expect(
//         find.byKey(Key("addAddressBookClearAddressButtonKey")), findsNothing);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//
//     verify(scanner.scan()).called(1);
//     verifyNoMoreInteractions(scanner);
//
//     verify(manager.addListener(any)).called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap scan qr with valid firo uri B", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final navigator = mockingjay.MockNavigator();
//     final scanner = MockBarcodeScannerWrapper();
//
//     when(scanner.scan()).thenAnswer((_) async =>
//         ScanResult(rawContent: "firo:a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"));
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
//             child: AddAddressBookEntryView(
//               barcodeScanner: scanner,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byKey(Key("addAddressBookEntryScanQrButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
//     expect(find.text("Invalid address"), findsNothing);
//
//     expect(
//         find.byKey(Key("addAddressBookClearAddressButtonKey")), findsOneWidget);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//
//     verify(scanner.scan()).called(1);
//     verifyNoMoreInteractions(scanner);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .called(2);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap scan qr with valid firo address", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final navigator = mockingjay.MockNavigator();
//     final scanner = MockBarcodeScannerWrapper();
//
//     when(scanner.scan()).thenAnswer((_) async =>
//         ScanResult(rawContent: "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"));
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
//             child: AddAddressBookEntryView(
//               barcodeScanner: scanner,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byKey(Key("addAddressBookEntryScanQrButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
//
//     expect(
//         find.byKey(Key("addAddressBookClearAddressButtonKey")), findsOneWidget);
//     expect(find.text("Invalid address"), findsNothing);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//
//     verify(scanner.scan()).called(1);
//     verifyNoMoreInteractions(scanner);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .called(3);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap scan qr with valid firo uri with invalid address",
//       (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final navigator = mockingjay.MockNavigator();
//     final scanner = MockBarcodeScannerWrapper();
//
//     when(scanner.scan()).thenAnswer(
//         (_) async => ScanResult(rawContent: "firo:invalidAddress?label=john"));
//
//     when(manager.validateAddress("invalidAddress")).thenAnswer((_) => false);
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
//             child: AddAddressBookEntryView(
//               barcodeScanner: scanner,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byKey(Key("addAddressBookEntryScanQrButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.text("invalidAddress"), findsOneWidget);
//     expect(find.text("john"), findsOneWidget);
//
//     expect(
//         find.byKey(Key("addAddressBookClearAddressButtonKey")), findsOneWidget);
//     expect(find.text("Invalid address"), findsOneWidget);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//
//     verify(scanner.scan()).called(1);
//     verifyNoMoreInteractions(scanner);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.validateAddress("invalidAddress")).called(2);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap scan qr with invalid firo address", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final navigator = mockingjay.MockNavigator();
//     final scanner = MockBarcodeScannerWrapper();
//
//     when(scanner.scan())
//         .thenAnswer((_) async => ScanResult(rawContent: "invalidAddress"));
//
//     when(manager.validateAddress("invalidAddress")).thenAnswer((_) => false);
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
//             child: AddAddressBookEntryView(
//               barcodeScanner: scanner,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byKey(Key("addAddressBookEntryScanQrButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.text("invalidAddress"), findsNothing);
//     expect(find.text("Invalid address"), findsNothing);
//
//     expect(
//         find.byKey(Key("addAddressBookClearAddressButtonKey")), findsNothing);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//
//     verify(scanner.scan()).called(1);
//     verifyNoMoreInteractions(scanner);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.validateAddress("invalidAddress")).called(1);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("enter invalid firo address", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final navigator = mockingjay.MockNavigator();
//     final scanner = MockBarcodeScannerWrapper();
//
//     when(manager.validateAddress("")).thenAnswer((_) => false);
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
//             child: AddAddressBookEntryView(
//               barcodeScanner: scanner,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.enterText(
//         find.byKey(Key("addAddressBookEntryViewAddressField")),
//         "invalidAddress");
//     await tester.pumpAndSettle();
//
//     expect(find.text("invalidAddress"), findsNothing);
//     expect(find.text("Invalid address"), findsNothing);
//
//     expect(
//         find.byKey(Key("addAddressBookClearAddressButtonKey")), findsNothing);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//
//     verifyNoMoreInteractions(scanner);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.validateAddress("")).called(1);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("enter valid firo address", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final navigator = mockingjay.MockNavigator();
//     final scanner = MockBarcodeScannerWrapper();
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
//             child: AddAddressBookEntryView(
//               barcodeScanner: scanner,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.enterText(
//         find.byKey(Key("addAddressBookEntryViewAddressField")),
//         "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg");
//     await tester.pumpAndSettle();
//
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
//     expect(find.text("Invalid address"), findsNothing);
//
//     expect(
//         find.byKey(Key("addAddressBookClearAddressButtonKey")), findsOneWidget);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//
//     verifyNoMoreInteractions(scanner);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .called(2);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap paste with a valid firo address", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final navigator = mockingjay.MockNavigator();
//     final clipboard = FakeClipboard();
//
//     clipboard
//         .setData(ClipboardData(text: "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"));
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
//             child: AddAddressBookEntryView(
//               clipboard: clipboard,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byKey(Key("addAddressPasteAddressButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
//     expect(find.text("Invalid address"), findsNothing);
//
//     expect(
//         find.byKey(Key("addAddressBookClearAddressButtonKey")), findsOneWidget);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .called(2);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap paste with a invalid firo address", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final navigator = mockingjay.MockNavigator();
//     final clipboard = FakeClipboard();
//
//     clipboard.setData(ClipboardData(text: "invalidAddress"));
//
//     when(manager.validateAddress("invalidAddress")).thenAnswer((_) => false);
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
//             child: AddAddressBookEntryView(
//               clipboard: clipboard,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byKey(Key("addAddressPasteAddressButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.text("invalidAddress"), findsOneWidget);
//     expect(find.text("Invalid address"), findsOneWidget);
//
//     expect(
//         find.byKey(Key("addAddressBookClearAddressButtonKey")), findsOneWidget);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.validateAddress("invalidAddress")).called(2);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap paste then tap clear address", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final navigator = mockingjay.MockNavigator();
//     final clipboard = FakeClipboard();
//
//     clipboard.setData(ClipboardData(text: "invalidAddress"));
//
//     when(manager.validateAddress("invalidAddress")).thenAnswer((_) => false);
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
//             child: AddAddressBookEntryView(
//               clipboard: clipboard,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byKey(Key("addAddressPasteAddressButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.text("invalidAddress"), findsOneWidget);
//     expect(find.text("Invalid address"), findsOneWidget);
//
//     expect(find.byKey(Key("addAddressPasteAddressButtonKey")), findsNothing);
//     expect(
//         find.byKey(Key("addAddressBookClearAddressButtonKey")), findsOneWidget);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//
//     await tester.tap(find.byKey(Key("addAddressBookClearAddressButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.text("invalidAddress"), findsNothing);
//     expect(find.text("Invalid address"), findsNothing);
//
//     expect(find.byKey(Key("addAddressPasteAddressButtonKey")), findsOneWidget);
//     expect(
//         find.byKey(Key("addAddressBookClearAddressButtonKey")), findsNothing);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.validateAddress("invalidAddress")).called(2);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("enter name", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final navigator = mockingjay.MockNavigator();
//     final scanner = MockBarcodeScannerWrapper();
//
//     when(manager.validateAddress("")).thenAnswer((_) => false);
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
//             child: AddAddressBookEntryView(
//               barcodeScanner: scanner,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.enterText(
//         find.byKey(Key("addAddressBookEntryViewNameField")), "john");
//     await tester.pumpAndSettle();
//
//     expect(find.text("john"), findsOneWidget);
//     expect(find.text("invalidAddress"), findsNothing);
//     expect(find.text("Invalid address"), findsNothing);
//
//     expect(
//         find.byKey(Key("addAddressBookClearAddressButtonKey")), findsNothing);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//
//     verifyNoMoreInteractions(scanner);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.validateAddress("")).called(1);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("enter a name with invalid firo address", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final navigator = mockingjay.MockNavigator();
//     final scanner = MockBarcodeScannerWrapper();
//
//     when(manager.validateAddress("")).thenAnswer((_) => false);
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
//             child: AddAddressBookEntryView(
//               barcodeScanner: scanner,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.enterText(
//         find.byKey(Key("addAddressBookEntryViewAddressField")),
//         "invalidAddress");
//     await tester.enterText(
//         find.byKey(Key("addAddressBookEntryViewNameField")), "john");
//     await tester.pumpAndSettle();
//
//     expect(find.text("john"), findsOneWidget);
//     expect(find.text("invalidAddress"), findsNothing);
//     expect(find.text("Invalid address"), findsNothing);
//
//     expect(
//         find.byKey(Key("addAddressBookClearAddressButtonKey")), findsNothing);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//
//     verifyNoMoreInteractions(scanner);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.validateAddress("")).called(2);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("enter a name with a valid firo address", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final navigator = mockingjay.MockNavigator();
//     final scanner = MockBarcodeScannerWrapper();
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
//             child: AddAddressBookEntryView(
//               barcodeScanner: scanner,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.enterText(
//         find.byKey(Key("addAddressBookEntryViewAddressField")),
//         "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg");
//     await tester.enterText(
//         find.byKey(Key("addAddressBookEntryViewNameField")), "john");
//     await tester.pumpAndSettle();
//
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
//     expect(find.text("john"), findsOneWidget);
//     expect(find.text("Invalid address"), findsNothing);
//
//     expect(
//         find.byKey(Key("addAddressBookClearAddressButtonKey")), findsOneWidget);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         true);
//
//     verifyNoMoreInteractions(scanner);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .called(4);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("save a validated contact where address is new", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final navigator = mockingjay.MockNavigator();
//     final scanner = MockBarcodeScannerWrapper();
//
//     when(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .thenAnswer((_) => true);
//
//     when(addressBookService
//             .containsAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .thenAnswer((_) async => false);
//     when(addressBookService.addAddressBookEntry(
//             "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg", "john"))
//         .thenAnswer((_) async => false);
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
//             child: AddAddressBookEntryView(
//               barcodeScanner: scanner,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.enterText(
//         find.byKey(Key("addAddressBookEntryViewAddressField")),
//         "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg");
//     await tester.enterText(
//         find.byKey(Key("addAddressBookEntryViewNameField")), "john");
//     await tester.pumpAndSettle();
//
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
//     expect(find.text("john"), findsOneWidget);
//     expect(find.text("Invalid address"), findsNothing);
//
//     expect(
//         find.byKey(Key("addAddressBookClearAddressButtonKey")), findsOneWidget);
//
//     final saveButton =
//         find.byType(GradientButton).evaluate().single.widget as GradientButton;
//     expect(saveButton.enabled, true);
//
//     await tester.tap(find.byWidget(saveButton));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(CampfireAlert), findsNothing);
//
//     verifyNoMoreInteractions(scanner);
//
//     verify(manager.addListener(any)).called(1);
//     verify(addressBookService.addListener(any)).called(1);
//
//     verify(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .called(4);
//     verify(addressBookService
//             .containsAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .called(1);
//     verify(addressBookService.addAddressBookEntry(
//             "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg", "john"))
//         .called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("save a validated contact where address is already in contacts",
//       (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final navigator = mockingjay.MockNavigator();
//     final scanner = MockBarcodeScannerWrapper();
//
//     when(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .thenAnswer((_) => true);
//
//     when(addressBookService
//             .containsAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .thenAnswer((_) async => true);
//
//     when(addressBookService.addAddressBookEntry(
//             "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg", "john"))
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
//             child: AddAddressBookEntryView(
//               barcodeScanner: scanner,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.enterText(
//         find.byKey(Key("addAddressBookEntryViewAddressField")),
//         "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg");
//     await tester.enterText(
//         find.byKey(Key("addAddressBookEntryViewNameField")), "john");
//     await tester.pumpAndSettle();
//
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
//     expect(find.text("john"), findsOneWidget);
//     expect(find.text("Invalid address"), findsNothing);
//
//     expect(
//         find.byKey(Key("addAddressBookClearAddressButtonKey")), findsOneWidget);
//
//     final saveButton =
//         find.byType(GradientButton).evaluate().single.widget as GradientButton;
//     expect(saveButton.enabled, true);
//
//     await tester.tap(find.byWidget(saveButton));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(CampfireAlert), findsOneWidget);
//     expect(find.text("The address you entered is already in your contacts!"),
//         findsOneWidget);
//
//     verifyNoMoreInteractions(scanner);
//
//     verify(manager.addListener(any)).called(1);
//     verify(addressBookService.addListener(any)).called(1);
//
//     verify(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .called(4);
//     verify(addressBookService
//             .containsAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("save a validated contact throws", (tester) async {
//     final manager = MockManager();
//     final addressBookService = MockAddressBookService();
//     final navigator = mockingjay.MockNavigator();
//     final scanner = MockBarcodeScannerWrapper();
//
//     when(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .thenAnswer((_) => true);
//
//     when(addressBookService
//             .containsAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .thenAnswer((_) async => false);
//     when(addressBookService.addAddressBookEntry(
//             "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg", "john"))
//         .thenThrow(Exception("some exception"));
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
//             child: AddAddressBookEntryView(
//               barcodeScanner: scanner,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.enterText(
//         find.byKey(Key("addAddressBookEntryViewAddressField")),
//         "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg");
//     await tester.enterText(
//         find.byKey(Key("addAddressBookEntryViewNameField")), "john");
//     await tester.pumpAndSettle();
//
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
//     expect(find.text("john"), findsOneWidget);
//     expect(find.text("Invalid address"), findsNothing);
//
//     expect(
//         find.byKey(Key("addAddressBookClearAddressButtonKey")), findsOneWidget);
//
//     final saveButton =
//         find.byType(GradientButton).evaluate().single.widget as GradientButton;
//     expect(saveButton.enabled, true);
//
//     await tester.tap(find.byWidget(saveButton));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(CampfireAlert), findsOneWidget);
//     expect(find.text("The address you entered is already in your contacts!"),
//         findsOneWidget);
//
//     verifyNoMoreInteractions(scanner);
//
//     verify(manager.addListener(any)).called(1);
//     verify(addressBookService.addListener(any)).called(1);
//
//     verify(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .called(4);
//     verify(addressBookService
//             .containsAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .called(1);
//     verify(addressBookService.addAddressBookEntry(
//             "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg", "john"))
//         .called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(addressBookService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
}
