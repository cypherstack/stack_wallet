// import 'package:barcode_scan2/barcode_scan2.dart';
// import 'package:decimal/decimal.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
// import 'package:epicmobile/models/lelantus_fee_data.dart';
// import 'package:epicmobile/notifications/campfire_alert.dart';
// import 'package:epicmobile/pages/wallet_view/send_view.dart';
import 'package:epicmobile/services/coins/manager.dart';
import 'package:epicmobile/services/notes_service.dart';
import 'package:epicmobile/utilities/barcode_scanner_interface.dart';
// import 'package:epicmobile/utilities/clipboard_interface.dart';
// import 'package:epicmobile/widgets/amount_input_field.dart';
// import 'package:epicmobile/widgets/custom_buttons/gradient_button.dart';
// import 'package:epicmobile/widgets/gradient_card.dart';
// import 'package:provider/provider.dart';
//
// import 'send_view_screen_test.mocks.dart';

@GenerateMocks([
  BarcodeScannerWrapper
], customMocks: [
  MockSpec<Manager>(returnNullOnMissingStub: true),
  MockSpec<NotesService>(returnNullOnMissingStub: true),
])
void main() {
//   testWidgets("SendView builds correctly", (tester) async {
//     final manager = MockManager();
//     final notesService = MockNotesService();
//
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//     when(manager.fiatPrice).thenAnswer((_) async => Decimal.ten);
//     when(manager.balanceMinusMaxFee)
//         .thenAnswer((_) async => Decimal.fromInt(9));
//     when(manager.maxFee)
//         .thenAnswer((_) async => LelantusFeeData(null, 100000000, null));
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: Material(
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//               ChangeNotifierProvider<NotesService>(
//                 create: (_) => notesService,
//               ),
//             ],
//             child: SendView(),
//           ),
//         ),
//       ),
//     );
//
//     expect(find.byType(GradientCard), findsOneWidget);
//     expect(find.byType(AmountInputField), findsOneWidget);
//     expect(find.byType(TextField), findsNWidgets(4));
//     expect(find.text("You can spend: "), findsOneWidget);
//     expect(find.text("0.00000000 FIRO"), findsNWidgets(3));
//
//     expect(find.text("Send to"), findsOneWidget);
//     expect(find.text("Paste address"), findsOneWidget);
//
//     expect(find.text("Note (optional)"), findsOneWidget);
//     expect(find.text("Type something..."), findsOneWidget);
//
//     expect(find.text("Amount"), findsOneWidget);
//     expect(find.text("0.00"), findsNWidgets(2));
//     expect(find.text("FIRO"), findsOneWidget);
//     expect(find.text("USD"), findsOneWidget);
//
//     expect(find.text("Maximum Transaction fee"), findsOneWidget);
//     expect(find.text("Total amount to send"), findsOneWidget);
//
//     expect(find.byType(SvgPicture), findsNWidgets(5));
//     expect(find.text("SEND"), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//   });
//
//   testWidgets("SendView loads correctly", (tester) async {
//     final manager = MockManager();
//     final notesService = MockNotesService();
//
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//     when(manager.fiatPrice).thenAnswer((_) async => Decimal.ten);
//     when(manager.balanceMinusMaxFee)
//         .thenAnswer((_) async => Decimal.fromInt(9));
//     when(manager.maxFee)
//         .thenAnswer((_) async => LelantusFeeData(null, 100000000, null));
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: Material(
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//               ChangeNotifierProvider<NotesService>(
//                 create: (_) => notesService,
//               ),
//             ],
//             child: SendView(),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(GradientCard), findsOneWidget);
//     expect(find.byType(AmountInputField), findsOneWidget);
//     expect(find.byType(TextField), findsNWidgets(4));
//     expect(find.text("You can spend: "), findsOneWidget);
//     expect(find.text("9.00000000 FIRO"), findsOneWidget);
//
//     expect(find.text("Send to"), findsOneWidget);
//     expect(find.text("Paste address"), findsOneWidget);
//
//     expect(find.text("Note (optional)"), findsOneWidget);
//     expect(find.text("Type something..."), findsOneWidget);
//
//     expect(find.text("Amount"), findsOneWidget);
//     expect(find.text("0.00"), findsNWidgets(2));
//     expect(find.text("FIRO"), findsOneWidget);
//     expect(find.text("USD"), findsOneWidget);
//
//     expect(find.text("Maximum Transaction fee"), findsOneWidget);
//     expect(find.text("Total amount to send"), findsOneWidget);
//     expect(find.text("1.00000000 FIRO"), findsOneWidget);
//     expect(find.text("0.00000000 FIRO"), findsOneWidget);
//
//     expect(find.byType(SvgPicture), findsNWidgets(5));
//     expect(find.text("SEND"), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//   });
//
//   testWidgets("SendView tiny screen loads correctly", (tester) async {
//     tester.binding.window.physicalSizeTestValue = Size(340, 600);
//     tester.binding.window.devicePixelRatioTestValue = 1;
//
//     // resets screen to original size after the test end
//     addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
//     addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
//
//     final manager = MockManager();
//     final notesService = MockNotesService();
//
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//     when(manager.fiatPrice).thenAnswer((_) async => Decimal.ten);
//     when(manager.balanceMinusMaxFee)
//         .thenAnswer((_) async => Decimal.fromInt(9));
//     when(manager.maxFee)
//         .thenAnswer((_) async => LelantusFeeData(null, 100000000, null));
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: Material(
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//               ChangeNotifierProvider<NotesService>(
//                 create: (_) => notesService,
//               ),
//             ],
//             child: SendView(),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(GradientCard), findsOneWidget);
//     expect(find.byType(AmountInputField), findsOneWidget);
//     expect(find.byType(TextField), findsNWidgets(4));
//     expect(find.text("You can spend: "), findsOneWidget);
//     expect(find.text("9.00000000 FIRO"), findsOneWidget);
//
//     expect(find.text("Send to"), findsOneWidget);
//     expect(find.text("Paste address"), findsOneWidget);
//
//     expect(find.text("Note (optional)"), findsOneWidget);
//     expect(find.text("Type something..."), findsOneWidget);
//
//     expect(find.text("Amount"), findsOneWidget);
//     expect(find.text("0.00"), findsNWidgets(2));
//     expect(find.text("FIRO"), findsOneWidget);
//     expect(find.text("USD"), findsOneWidget);
//
//     expect(find.text("Maximum Transaction fee"), findsOneWidget);
//     expect(find.text("Total amount to send"), findsOneWidget);
//     expect(find.text("1.00000000 FIRO"), findsOneWidget);
//     expect(find.text("0.00000000 FIRO"), findsOneWidget);
//
//     expect(find.byType(SvgPicture), findsNWidgets(5));
//     expect(find.text("SEND"), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//   });
//
//   testWidgets("SendView load fails to fetch data", (tester) async {
//     final manager = MockManager();
//     final notesService = MockNotesService();
//
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//     when(manager.fiatPrice).thenAnswer((_) async => Decimal.fromInt(-1));
//     when(manager.balanceMinusMaxFee).thenAnswer(((_) async => null) as Future<Decimal> Function(Invocation));
//     when(manager.maxFee).thenAnswer((_) async => null);
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: Material(
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//               ChangeNotifierProvider<NotesService>(
//                 create: (_) => notesService,
//               ),
//             ],
//             child: SendView(),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(GradientCard), findsOneWidget);
//     expect(find.byType(AmountInputField), findsOneWidget);
//     expect(find.byType(TextField), findsNWidgets(4));
//     expect(find.text("You can spend: "), findsOneWidget);
//     expect(find.text("... FIRO"), findsOneWidget);
//
//     expect(find.text("Send to"), findsOneWidget);
//     expect(find.text("Paste address"), findsOneWidget);
//
//     expect(find.text("Note (optional)"), findsOneWidget);
//     expect(find.text("Type something..."), findsOneWidget);
//
//     expect(find.text("Amount"), findsOneWidget);
//     expect(find.text("0.00"), findsOneWidget);
//     expect(find.text("FIRO"), findsOneWidget);
//     expect(find.text("..."), findsOneWidget);
//     expect(find.text("USD"), findsOneWidget);
//
//     expect(find.text("Maximum Transaction fee"), findsOneWidget);
//     expect(find.text("Total amount to send"), findsOneWidget);
//     expect(find.text("0.00000000 FIRO"), findsNWidgets(2));
//
//     expect(find.byType(SvgPicture), findsNWidgets(5));
//     expect(find.text("SEND"), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//   });
//
//   testWidgets("paste and clear a valid address", (tester) async {
//     final manager = MockManager();
//     final notesService = MockNotesService();
//     final clipboard = FakeClipboard();
//
//     clipboard
//         .setData(ClipboardData(text: "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"));
//     when(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .thenAnswer((_) => true);
//     when(manager.validateAddress("")).thenAnswer((_) => false);
//
//     when(manager.allOwnAddresses).thenAnswer((_) async => []);
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//     when(manager.fiatPrice).thenAnswer((_) async => Decimal.ten);
//     when(manager.balanceMinusMaxFee)
//         .thenAnswer((_) async => Decimal.fromInt(9));
//     when(manager.maxFee)
//         .thenAnswer((_) async => LelantusFeeData(null, 100000000, null));
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: Material(
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//               ChangeNotifierProvider<NotesService>(
//                 create: (_) => notesService,
//               ),
//             ],
//             child: SendView(
//               clipboard: clipboard,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byKey(Key("sendViewPasteAddressFieldButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
//     expect(find.text("Invalid address"), findsNothing);
//
//     await tester.tap(find.byKey(Key("sendViewClearAddressFieldButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsNothing);
//     expect(find.byKey(Key("sendViewClearAddressFieldButtonKey")), findsNothing);
//     expect(
//         find.byKey(Key("sendViewPasteAddressFieldButtonKey")), findsOneWidget);
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//   });
//
//   testWidgets("tap fee tooltips", (tester) async {
//     final manager = MockManager();
//     final notesService = MockNotesService();
//     final clipboard = FakeClipboard();
//
//     when(manager.validateAddress("")).thenAnswer((_) => false);
//
//     when(manager.allOwnAddresses).thenAnswer((_) async => []);
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//     when(manager.fiatPrice).thenAnswer((_) async => Decimal.ten);
//     when(manager.balanceMinusMaxFee)
//         .thenAnswer((_) async => Decimal.fromInt(9));
//     when(manager.maxFee)
//         .thenAnswer((_) async => LelantusFeeData(null, 100000000, null));
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: Material(
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//               ChangeNotifierProvider<NotesService>(
//                 create: (_) => notesService,
//               ),
//             ],
//             child: SendView(
//               clipboard: clipboard,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.text("Maximum Transaction fee"));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(MaxFeeTooltipWidget), findsOneWidget);
//     expect(
//         find.text(
//             "This is the maximum possible fee. Actual fee is calculated when attempting to send and will generally be less."),
//         findsOneWidget);
//     await tester.tap(find.byType(MaxFeeTooltipWidget));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(MaxFeeTooltipWidget), findsNothing);
//
//     await tester.tap(find.text("Total amount to send"));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(MaxFeeTooltipWidget), findsOneWidget);
//     expect(
//         find.text(
//             "This is the maximum possible fee. Actual fee is calculated when attempting to send and will generally be less."),
//         findsOneWidget);
//     await tester.tap(find.byType(MaxFeeTooltipWidget));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(MaxFeeTooltipWidget), findsNothing);
//   });
//
//   testWidgets("paste and clear an invalid address", (tester) async {
//     final manager = MockManager();
//     final notesService = MockNotesService();
//     final clipboard = FakeClipboard();
//
//     clipboard.setData(ClipboardData(text: "hahahahahaha"));
//     when(manager.validateAddress("hahahahahaha")).thenAnswer((_) => false);
//     when(manager.validateAddress("")).thenAnswer((_) => false);
//
//     when(manager.allOwnAddresses).thenAnswer((_) async => []);
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//     when(manager.fiatPrice).thenAnswer((_) async => Decimal.ten);
//     when(manager.balanceMinusMaxFee)
//         .thenAnswer((_) async => Decimal.fromInt(9));
//     when(manager.maxFee)
//         .thenAnswer((_) async => LelantusFeeData(null, 100000000, null));
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: Material(
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//               ChangeNotifierProvider<NotesService>(
//                 create: (_) => notesService,
//               ),
//             ],
//             child: SendView(
//               clipboard: clipboard,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byKey(Key("sendViewPasteAddressFieldButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.text("hahahahahaha"), findsOneWidget);
//     expect(find.text("Invalid address"), findsOneWidget);
//
//     await tester.tap(find.byKey(Key("sendViewClearAddressFieldButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.text("hahahahahaha"), findsNothing);
//     expect(find.text("Invalid address"), findsNothing);
//     expect(find.byKey(Key("sendViewClearAddressFieldButtonKey")), findsNothing);
//     expect(
//         find.byKey(Key("sendViewPasteAddressFieldButtonKey")), findsOneWidget);
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//   });
//
//   testWidgets("enter and clear a valid address", (tester) async {
//     final manager = MockManager();
//     final notesService = MockNotesService();
//     final clipboard = FakeClipboard();
//
//     when(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .thenAnswer((_) => true);
//     when(manager.validateAddress("")).thenAnswer((_) => false);
//
//     when(manager.allOwnAddresses).thenAnswer((_) async => []);
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//     when(manager.fiatPrice).thenAnswer((_) async => Decimal.ten);
//     when(manager.balanceMinusMaxFee)
//         .thenAnswer((_) async => Decimal.fromInt(9));
//     when(manager.maxFee)
//         .thenAnswer((_) async => LelantusFeeData(null, 100000000, null));
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: Material(
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//               ChangeNotifierProvider<NotesService>(
//                 create: (_) => notesService,
//               ),
//             ],
//             child: SendView(
//               clipboard: clipboard,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.enterText(find.byKey(Key("sendViewAddressFieldKey")),
//         "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg");
//     await tester.pumpAndSettle();
//
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
//     expect(find.text("Invalid address"), findsNothing);
//
//     await tester.tap(find.byKey(Key("sendViewClearAddressFieldButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsNothing);
//     expect(find.byKey(Key("sendViewClearAddressFieldButtonKey")), findsNothing);
//     expect(
//         find.byKey(Key("sendViewPasteAddressFieldButtonKey")), findsOneWidget);
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//   });
//
//   testWidgets("enter an invalid address", (tester) async {
//     final manager = MockManager();
//     final notesService = MockNotesService();
//     final clipboard = FakeClipboard();
//
//     when(manager.validateAddress("hahahahahaha")).thenAnswer((_) => false);
//     when(manager.validateAddress("")).thenAnswer((_) => false);
//
//     when(manager.allOwnAddresses).thenAnswer((_) async => []);
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//     when(manager.fiatPrice).thenAnswer((_) async => Decimal.ten);
//     when(manager.balanceMinusMaxFee)
//         .thenAnswer((_) async => Decimal.fromInt(9));
//     when(manager.maxFee)
//         .thenAnswer((_) async => LelantusFeeData(null, 100000000, null));
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: Material(
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//               ChangeNotifierProvider<NotesService>(
//                 create: (_) => notesService,
//               ),
//             ],
//             child: SendView(
//               clipboard: clipboard,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.enterText(
//         find.byKey(Key("sendViewAddressFieldKey")), "hahahahahaha");
//     await tester.pumpAndSettle();
//
//     expect(find.text("hahahahahaha"), findsNothing);
//     expect(find.text("Invalid address"), findsNothing);
//     expect(find.byKey(Key("sendViewClearAddressFieldButtonKey")), findsNothing);
//     expect(
//         find.byKey(Key("sendViewPasteAddressFieldButtonKey")), findsOneWidget);
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//   });
//
//   testWidgets("enter a firo amount", (tester) async {
//     final manager = MockManager();
//     final notesService = MockNotesService();
//     final clipboard = FakeClipboard();
//
//     when(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .thenAnswer((_) => true);
//     when(manager.validateAddress("")).thenAnswer((_) => false);
//
//     when(manager.allOwnAddresses).thenAnswer((_) async => []);
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//     when(manager.fiatPrice).thenAnswer((_) async => Decimal.ten);
//     when(manager.balanceMinusMaxFee)
//         .thenAnswer((_) async => Decimal.fromInt(9));
//     when(manager.maxFee)
//         .thenAnswer((_) async => LelantusFeeData(null, 100000000, null));
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: Material(
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//               ChangeNotifierProvider<NotesService>(
//                 create: (_) => notesService,
//               ),
//             ],
//             child: SendView(
//               clipboard: clipboard,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.enterText(
//         find.byKey(Key("amountInputFieldCryptoTextFieldKey")), "2");
//     await tester.pumpAndSettle();
//
//     expect(find.text("2"), findsOneWidget);
//     expect(find.text("20.00"), findsOneWidget);
//     expect(find.text("3.00000000 FIRO"), findsOneWidget);
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//   });
//
//   testWidgets("tap available to autofill maximum amount", (tester) async {
//     final manager = MockManager();
//     final notesService = MockNotesService();
//     final clipboard = FakeClipboard();
//
//     when(manager.validateAddress("")).thenAnswer((_) => false);
//     when(manager.allOwnAddresses).thenAnswer((_) async => []);
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//     when(manager.fiatPrice).thenAnswer((_) async => Decimal.ten);
//     when(manager.balanceMinusMaxFee)
//         .thenAnswer((_) async => Decimal.fromInt(9));
//     when(manager.maxFee)
//         .thenAnswer((_) async => LelantusFeeData(null, 100000000, null));
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: Material(
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//               ChangeNotifierProvider<NotesService>(
//                 create: (_) => notesService,
//               ),
//             ],
//             child: SendView(
//               clipboard: clipboard,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byKey(Key("availableToSpendBalanceLabelKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.text("0.00"), findsNWidgets(2));
//     expect(find.text("1.00000000 FIRO"), findsOneWidget);
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.validateAddress("")).called(1);
//     verify(manager.coinTicker).called(15);
//     verify(manager.fiatPrice).called(3);
//     verify(manager.fiatCurrency).called(5);
//     verify(manager.balanceMinusMaxFee).called(2);
//     verify(manager.maxFee).called(3);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(notesService);
//   });
//
//   testWidgets("enter a fiat amount", (tester) async {
//     final manager = MockManager();
//     final notesService = MockNotesService();
//     final clipboard = FakeClipboard();
//
//     when(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .thenAnswer((_) => true);
//     when(manager.validateAddress("")).thenAnswer((_) => false);
//
//     when(manager.allOwnAddresses).thenAnswer((_) async => []);
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//     when(manager.fiatPrice).thenAnswer((_) async => Decimal.ten);
//     when(manager.balanceMinusMaxFee)
//         .thenAnswer((_) async => Decimal.fromInt(9));
//     when(manager.maxFee)
//         .thenAnswer((_) async => LelantusFeeData(null, 100000000, null));
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: Material(
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//               ChangeNotifierProvider<NotesService>(
//                 create: (_) => notesService,
//               ),
//             ],
//             child: SendView(
//               clipboard: clipboard,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.enterText(
//         find.byKey(Key("amountInputFieldFiatTextFieldKey")), "2");
//     await tester.pumpAndSettle();
//
//     expect(find.text("0.20000000"), findsOneWidget);
//     expect(find.text("2"), findsOneWidget);
//     expect(find.text("1.20000000 FIRO"), findsOneWidget);
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//   });
//
//   testWidgets("tap addressbook icon", (tester) async {
//     final manager = MockManager();
//     final notesService = MockNotesService();
//     final clipboard = FakeClipboard();
//     final navigator = mockingjay.MockNavigator();
//
//     when(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .thenAnswer((_) => true);
//     when(manager.validateAddress("")).thenAnswer((_) => false);
//
//     when(manager.allOwnAddresses).thenAnswer((_) async => []);
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//     when(manager.fiatPrice).thenAnswer((_) async => Decimal.ten);
//     when(manager.balanceMinusMaxFee)
//         .thenAnswer((_) async => Decimal.fromInt(9));
//     when(manager.maxFee)
//         .thenAnswer((_) async => LelantusFeeData(null, 100000000, null));
//
//     mockingjay
//         .when(() => navigator.pushNamed("/addressbook"))
//         .thenAnswer((_) async => "john doe");
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: Material(
//           child: mockingjay.MockNavigatorProvider(
//             navigator: navigator,
//             child: MultiProvider(
//               providers: [
//                 ChangeNotifierProvider<Manager>(
//                   create: (_) => manager,
//                 ),
//                 ChangeNotifierProvider<NotesService>(
//                   create: (_) => notesService,
//                 ),
//               ],
//               child: SendView(
//                 clipboard: clipboard,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byKey(Key("sendViewAddressBookButtonKey")));
//     await tester.pumpAndSettle();
//
//     mockingjay.verify(() => navigator.pushNamed("/addressbook")).called(1);
//
//     expect(find.text("john doe"), findsOneWidget);
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//   });
//
//   testWidgets("tap scan qr code icon and do not give camera permissions",
//       (tester) async {
//     final manager = MockManager();
//     final notesService = MockNotesService();
//     final clipboard = FakeClipboard();
//     final scanner = MockBarcodeScannerWrapper();
//
//     when(scanner.scan())
//         .thenThrow(PlatformException(code: "camera permission denied"));
//
//     when(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .thenAnswer((_) => true);
//     when(manager.validateAddress("")).thenAnswer((_) => false);
//
//     when(manager.allOwnAddresses).thenAnswer((_) async => []);
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//     when(manager.fiatPrice).thenAnswer((_) async => Decimal.ten);
//     when(manager.balanceMinusMaxFee)
//         .thenAnswer((_) async => Decimal.fromInt(9));
//     when(manager.maxFee)
//         .thenAnswer((_) async => LelantusFeeData(null, 100000000, null));
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: Material(
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//               ChangeNotifierProvider<NotesService>(
//                 create: (_) => notesService,
//               ),
//             ],
//             child: SendView(
//               clipboard: clipboard,
//               barcodeScanner: scanner,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byKey(Key("sendViewScanQrButtonKey")));
//     await tester.pumpAndSettle();
//
//     verify(scanner.scan()).called(1);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//   });
//
//   testWidgets("tap scan qr code for basic address", (tester) async {
//     final manager = MockManager();
//     final notesService = MockNotesService();
//     final clipboard = FakeClipboard();
//     final scanner = MockBarcodeScannerWrapper();
//
//     when(scanner.scan()).thenAnswer((_) async =>
//         ScanResult(rawContent: "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"));
//
//     when(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .thenAnswer((_) => true);
//     when(manager.validateAddress("")).thenAnswer((_) => false);
//
//     when(manager.allOwnAddresses).thenAnswer((_) async => []);
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//     when(manager.fiatPrice).thenAnswer((_) async => Decimal.ten);
//     when(manager.balanceMinusMaxFee)
//         .thenAnswer((_) async => Decimal.fromInt(9));
//     when(manager.maxFee)
//         .thenAnswer((_) async => LelantusFeeData(null, 100000000, null));
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: Material(
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//               ChangeNotifierProvider<NotesService>(
//                 create: (_) => notesService,
//               ),
//             ],
//             child: SendView(
//               clipboard: clipboard,
//               barcodeScanner: scanner,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byKey(Key("sendViewScanQrButtonKey")));
//     await tester.pumpAndSettle();
//
//     verify(scanner.scan()).called(1);
//
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//   });
//
//   testWidgets("tap scan qr code for firo uri", (tester) async {
//     final manager = MockManager();
//     final notesService = MockNotesService();
//     final clipboard = FakeClipboard();
//     final scanner = MockBarcodeScannerWrapper();
//
//     when(scanner.scan()).thenAnswer((_) async => ScanResult(
//         rawContent:
//             "firo:a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg?label=john&amount=12"));
//
//     when(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .thenAnswer((_) => true);
//     when(manager.validateAddress("")).thenAnswer((_) => false);
//
//     when(manager.allOwnAddresses).thenAnswer((_) async => []);
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//     when(manager.fiatPrice).thenAnswer((_) async => Decimal.ten);
//     when(manager.balanceMinusMaxFee)
//         .thenAnswer((_) async => Decimal.fromInt(9));
//     when(manager.maxFee)
//         .thenAnswer((_) async => LelantusFeeData(null, 100000000, null));
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: Material(
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//               ChangeNotifierProvider<NotesService>(
//                 create: (_) => notesService,
//               ),
//             ],
//             child: SendView(
//               clipboard: clipboard,
//               barcodeScanner: scanner,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byKey(Key("sendViewScanQrButtonKey")));
//     await tester.pumpAndSettle();
//
//     verify(scanner.scan()).called(1);
//
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
//     expect(find.text("john"), findsOneWidget);
//     expect(find.text("12"), findsOneWidget);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         true);
//   });
//
//   testWidgets("attempt send to own address", (tester) async {
//     final manager = MockManager();
//     final notesService = MockNotesService();
//     final clipboard = FakeClipboard();
//     final scanner = MockBarcodeScannerWrapper();
//
//     when(scanner.scan()).thenAnswer((_) async => ScanResult(
//         rawContent:
//             "firo:a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg?label=john&amount=12"));
//
//     when(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .thenAnswer((_) => true);
//     when(manager.validateAddress("")).thenAnswer((_) => false);
//
//     when(manager.allOwnAddresses)
//         .thenAnswer((_) async => ["a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"]);
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//     when(manager.fiatPrice).thenAnswer((_) async => Decimal.ten);
//     when(manager.balanceMinusMaxFee)
//         .thenAnswer((_) async => Decimal.fromInt(9));
//     when(manager.maxFee)
//         .thenAnswer((_) async => LelantusFeeData(null, 100000000, null));
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: Material(
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//               ChangeNotifierProvider<NotesService>(
//                 create: (_) => notesService,
//               ),
//             ],
//             child: SendView(
//               clipboard: clipboard,
//               barcodeScanner: scanner,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byKey(Key("sendViewScanQrButtonKey")));
//     await tester.pumpAndSettle();
//
//     verify(scanner.scan()).called(1);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         true);
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(CampfireAlert), findsOneWidget);
//     expect(find.text("Sending to your own address is currently disabled."),
//         findsOneWidget);
//   });
//
//   testWidgets("attempt send to invalid address", (tester) async {
//     final manager = MockManager();
//     final notesService = MockNotesService();
//     final clipboard = FakeClipboard();
//     final scanner = MockBarcodeScannerWrapper();
//
//     when(scanner.scan()).thenAnswer((_) async => ScanResult(
//         rawContent:
//             "firo:a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg?label=john&amount=12"));
//
//     when(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .thenAnswer((_) => false);
//     when(manager.validateAddress("")).thenAnswer((_) => false);
//
//     when(manager.allOwnAddresses)
//         .thenAnswer((_) async => ["a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"]);
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//     when(manager.fiatPrice).thenAnswer((_) async => Decimal.ten);
//     when(manager.balanceMinusMaxFee)
//         .thenAnswer((_) async => Decimal.fromInt(9));
//     when(manager.maxFee)
//         .thenAnswer((_) async => LelantusFeeData(null, 100000000, null));
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: Material(
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//               ChangeNotifierProvider<NotesService>(
//                 create: (_) => notesService,
//               ),
//             ],
//             child: SendView(
//               clipboard: clipboard,
//               barcodeScanner: scanner,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byKey(Key("sendViewScanQrButtonKey")));
//     await tester.pumpAndSettle();
//
//     verify(scanner.scan()).called(1);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         false);
//   });
//
//   testWidgets("attempt send more than available balance", (tester) async {
//     final manager = MockManager();
//     final notesService = MockNotesService();
//     final clipboard = FakeClipboard();
//     final scanner = MockBarcodeScannerWrapper();
//
//     when(scanner.scan()).thenAnswer((_) async => ScanResult(
//         rawContent:
//             "firo:a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg?label=john&amount=1200"));
//
//     when(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .thenAnswer((_) => true);
//     when(manager.validateAddress("")).thenAnswer((_) => false);
//
//     when(manager.allOwnAddresses).thenAnswer((_) async => []);
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//     when(manager.fiatPrice).thenAnswer((_) async => Decimal.ten);
//     when(manager.balanceMinusMaxFee)
//         .thenAnswer((_) async => Decimal.fromInt(9));
//     when(manager.maxFee)
//         .thenAnswer((_) async => LelantusFeeData(null, 100000000, null));
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: Material(
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//               ChangeNotifierProvider<NotesService>(
//                 create: (_) => notesService,
//               ),
//             ],
//             child: SendView(
//               clipboard: clipboard,
//               barcodeScanner: scanner,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byKey(Key("sendViewScanQrButtonKey")));
//     await tester.pumpAndSettle();
//
//     verify(scanner.scan()).called(1);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         true);
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(CampfireAlert), findsOneWidget);
//     expect(find.text("Insufficient balance!"), findsOneWidget);
//   });
//
//   testWidgets("attempt valid send succeeds", (tester) async {
//     final manager = MockManager();
//     final notesService = MockNotesService();
//     final clipboard = FakeClipboard();
//     final scanner = MockBarcodeScannerWrapper();
//     final navigator = mockingjay.MockNavigator();
//
//     when(scanner.scan()).thenAnswer((_) async => ScanResult(
//         rawContent:
//             "firo:a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg?label=john&amount=2"));
//
//     when(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .thenAnswer((_) => true);
//     when(manager.validateAddress("")).thenAnswer((_) => false);
//
//     when(manager.allOwnAddresses).thenAnswer((_) async => []);
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//     when(manager.fiatPrice).thenAnswer((_) async => Decimal.ten);
//     when(manager.balanceMinusMaxFee)
//         .thenAnswer((_) async => Decimal.fromInt(9));
//     when(manager.maxFee)
//         .thenAnswer((_) async => LelantusFeeData(null, 100000000, null));
//
//     mockingjay
//         .when(() => navigator.push(mockingjay.any()))
//         .thenAnswer((_) async => true);
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: Material(
//           child: mockingjay.MockNavigatorProvider(
//             navigator: navigator,
//             child: MultiProvider(
//               providers: [
//                 ChangeNotifierProvider<Manager>(
//                   create: (_) => manager,
//                 ),
//                 ChangeNotifierProvider<NotesService>(
//                   create: (_) => notesService,
//                 ),
//               ],
//               child: SendView(
//                 clipboard: clipboard,
//                 barcodeScanner: scanner,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byKey(Key("sendViewScanQrButtonKey")));
//     await tester.pumpAndSettle();
//
//     verify(scanner.scan()).called(1);
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
//     expect(find.text("john"), findsOneWidget);
//     expect(find.text("2"), findsOneWidget);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         true);
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle();
//
//     mockingjay.verify(() => navigator.push(mockingjay.any())).called(1);
//
//     expect(find.text("0.00"), findsNWidgets(2));
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsNothing);
//     expect(find.text("john"), findsNothing);
//     expect(find.text("2"), findsNothing);
//   });
//
//   testWidgets("attempt valid send fails", (tester) async {
//     final manager = MockManager();
//     final notesService = MockNotesService();
//     final clipboard = FakeClipboard();
//     final scanner = MockBarcodeScannerWrapper();
//     final navigator = mockingjay.MockNavigator();
//
//     when(scanner.scan()).thenAnswer((_) async => ScanResult(
//         rawContent:
//             "firo:a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg?label=john&amount=2"));
//
//     when(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .thenAnswer((_) => true);
//     when(manager.validateAddress("")).thenAnswer((_) => false);
//
//     when(manager.allOwnAddresses).thenAnswer((_) async => []);
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//     when(manager.fiatPrice).thenAnswer((_) async => Decimal.ten);
//     when(manager.balanceMinusMaxFee)
//         .thenAnswer((_) async => Decimal.fromInt(9));
//     when(manager.maxFee)
//         .thenAnswer((_) async => LelantusFeeData(null, 100000000, null));
//
//     mockingjay
//         .when(() => navigator.push(mockingjay.any()))
//         .thenAnswer((_) async => false);
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: Material(
//           child: mockingjay.MockNavigatorProvider(
//             navigator: navigator,
//             child: MultiProvider(
//               providers: [
//                 ChangeNotifierProvider<Manager>(
//                   create: (_) => manager,
//                 ),
//                 ChangeNotifierProvider<NotesService>(
//                   create: (_) => notesService,
//                 ),
//               ],
//               child: SendView(
//                 clipboard: clipboard,
//                 barcodeScanner: scanner,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byKey(Key("sendViewScanQrButtonKey")));
//     await tester.pumpAndSettle();
//
//     verify(scanner.scan()).called(1);
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
//     expect(find.text("john"), findsOneWidget);
//     expect(find.text("2"), findsOneWidget);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         true);
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle();
//
//     mockingjay.verify(() => navigator.push(mockingjay.any())).called(1);
//
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
//     expect(find.text("john"), findsOneWidget);
//     expect(find.text("2"), findsOneWidget);
//     expect(find.text("1.00000000 FIRO"), findsOneWidget);
//   });
//
//   testWidgets("autofill args send", (tester) async {
//     final manager = MockManager();
//     final notesService = MockNotesService();
//     final clipboard = FakeClipboard();
//     final scanner = MockBarcodeScannerWrapper();
//     final navigator = mockingjay.MockNavigator();
//
//     when(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .thenAnswer((_) => true);
//     when(manager.validateAddress("")).thenAnswer((_) => false);
//
//     when(manager.allOwnAddresses).thenAnswer((_) async => []);
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//     when(manager.fiatPrice).thenAnswer((_) async => Decimal.ten);
//     when(manager.balanceMinusMaxFee)
//         .thenAnswer((_) async => Decimal.fromInt(9));
//     when(manager.maxFee)
//         .thenAnswer((_) async => LelantusFeeData(null, 100000000, null));
//
//     mockingjay
//         .when(() => navigator.push(mockingjay.any()))
//         .thenAnswer((_) async => true);
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: Material(
//           child: mockingjay.MockNavigatorProvider(
//             navigator: navigator,
//             child: MultiProvider(
//               providers: [
//                 ChangeNotifierProvider<Manager>(
//                   create: (_) => manager,
//                 ),
//                 ChangeNotifierProvider<NotesService>(
//                   create: (_) => notesService,
//                 ),
//               ],
//               child: SendView(
//                 clipboard: clipboard,
//                 barcodeScanner: scanner,
//                 autofillArgs: {
//                   "cryptoAmount": "3.5",
//                   "addressBookEntry": {
//                     "address": "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg",
//                     "name": "john doe",
//                   }
//                 },
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsNothing);
//     expect(find.text("john doe"), findsOneWidget);
//     expect(find.text("3.50000000"), findsOneWidget);
//
//     expect(
//         (find.byType(GradientButton).evaluate().single.widget as GradientButton)
//             .enabled,
//         true);
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle();
//
//     mockingjay.verify(() => navigator.push(mockingjay.any())).called(1);
//
//     expect(find.text("0.00"), findsNWidgets(2));
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsNothing);
//     expect(find.text("john doe"), findsNothing);
//     expect(find.text("3.50000000"), findsNothing);
//   });
}
