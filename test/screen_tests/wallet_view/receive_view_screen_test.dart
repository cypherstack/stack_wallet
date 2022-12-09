// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
// import 'package:epicmobile/notifications/modal_popup_dialog.dart';
// import 'package:epicmobile/pages/wallet_view/receive_view.dart';
import 'package:epicmobile/services/coins/manager.dart';
// import 'package:epicmobile/utilities/clipboard_interface.dart';
// import 'package:epicmobile/widgets/custom_buttons/gradient_button.dart';
// import 'package:epicmobile/widgets/custom_buttons/simple_button.dart';
// import 'package:pretty_qr_code/pretty_qr_code.dart';
// import 'package:provider/provider.dart';
//
// import 'receive_view_screen_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<Manager>(returnNullOnMissingStub: true),
])
void main() {
//   testWidgets("ReceiveView builds without loading address", (tester) async {
//     final manager = MockManager();
//     final clipboard = FakeClipboard();
//
//     when(manager.currentReceivingAddress).thenAnswer(((_) async => null) as Future<String>? Function(Invocation));
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<Manager>(
//               create: (_) => manager,
//             ),
//           ],
//           child: ReceiveView(
//             clipboard: clipboard,
//           ),
//         ),
//       ),
//     );
//     await tester.pump(Duration(seconds: 1));
//
//     expect(find.byType(CircularProgressIndicator), findsOneWidget);
//
//     expect(find.byType(PrettyQr), findsNothing);
//     expect(find.byType(MaterialButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//     expect(find.text("MORE OPTIONS"), findsOneWidget);
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsNothing);
//     expect(find.text("TAP ADDRESS TO COPY"), findsNothing);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.currentReceivingAddress).called(2);
//
//     verifyNoMoreInteractions(manager);
//   });
//
//   testWidgets("ReceiveView builds correctly and loads address", (tester) async {
//     final manager = MockManager();
//     final clipboard = FakeClipboard();
//
//     when(manager.currentReceivingAddress)
//         .thenAnswer((_) async => "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg");
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<Manager>(
//               create: (_) => manager,
//             ),
//           ],
//           child: ReceiveView(
//             clipboard: clipboard,
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     final qr = find.byType(PrettyQr).evaluate().single.widget as PrettyQr;
//
//     expect(qr.data, "firo:a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg");
//
//     expect(find.byType(MaterialButton), findsNWidgets(2));
//     expect(find.byType(SimpleButton), findsOneWidget);
//     expect(find.text("MORE OPTIONS"), findsOneWidget);
//
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
//     expect(find.text("TAP ADDRESS TO COPY"), findsOneWidget);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.currentReceivingAddress).called(2);
//
//     verifyNoMoreInteractions(manager);
//   });
//
//   testWidgets("tap copy address", (tester) async {
//     final manager = MockManager();
//     final clipboard = FakeClipboard();
//
//     when(manager.currentReceivingAddress)
//         .thenAnswer((_) async => "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg");
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<Manager>(
//               create: (_) => manager,
//             ),
//           ],
//           child: ReceiveView(
//             clipboard: clipboard,
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     final qr = find.byType(PrettyQr).evaluate().single.widget as PrettyQr;
//
//     expect(qr.data, "firo:a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg");
//
//     expect(find.byType(MaterialButton), findsNWidgets(2));
//     expect(find.byType(SimpleButton), findsOneWidget);
//     expect(find.text("MORE OPTIONS"), findsOneWidget);
//
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
//     expect(find.text("TAP ADDRESS TO COPY"), findsOneWidget);
//
//     await tester.tap(find.byKey(Key("receiveViewAddressCopyButtonKey")));
//     await tester.pump(Duration(seconds: 1));
//     expect(find.text("Copied to clipboard"), findsOneWidget);
//
//     await tester.pump(Duration(seconds: 2));
//     expect(find.text("Copied to clipboard"), findsNothing);
//
//     final clipboardString = await clipboard.getData(Clipboard.kTextPlain);
//     expect(clipboardString.text, "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg");
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.currentReceivingAddress).called(2);
//
//     verifyNoMoreInteractions(manager);
//   });
//
//   testWidgets("toggle more options", (tester) async {
//     final channel = MethodChannel('uk.spiralarm.flutter/devicelocale');
//
//     handler(MethodCall methodCall) async {
//       if (methodCall.method == 'currentLocale') {
//         return 'en_US';
//       }
//       fail("Bad DeviceLocale MethodCall");
//     }
//
//     tester.binding.defaultBinaryMessenger
//         .setMockMethodCallHandler(channel, handler);
//
//     final manager = MockManager();
//     final clipboard = FakeClipboard();
//
//     when(manager.currentReceivingAddress)
//         .thenAnswer((_) async => "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg");
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
//           child: Material(
//             child: ReceiveView(
//               clipboard: clipboard,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     final qr = find.byType(PrettyQr).evaluate().single.widget as PrettyQr;
//     expect(qr.data, "firo:a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg");
//
//     expect(find.byType(MaterialButton), findsNWidgets(2));
//     expect(find.byType(Text), findsNWidgets(3));
//     expect(find.byType(SimpleButton), findsOneWidget);
//     expect(find.text("MORE OPTIONS"), findsOneWidget);
//
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
//     expect(find.text("TAP ADDRESS TO COPY"), findsOneWidget);
//
//     await tester.tap(find.byKey(Key("receiveViewMoreOptionsButtonKey")));
//     await tester.pumpAndSettle();
//
//     final qr2 = find.byType(PrettyQr).evaluate().single.widget as PrettyQr;
//     expect(qr2.data, "firo:a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg");
//
//     expect(find.byType(MaterialButton), findsNWidgets(3));
//     expect(find.byType(Text), findsNWidgets(9));
//     expect(find.byType(TextField), findsNWidgets(2));
//     expect(find.byType(SimpleButton), findsOneWidget);
//     expect(find.text("MORE OPTIONS"), findsOneWidget);
//
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
//     expect(find.text("TAP ADDRESS TO COPY"), findsOneWidget);
//
//     await tester.fling(
//         find.byType(SingleChildScrollView), Offset(0, -500), 1000);
//     await tester.pumpAndSettle();
//
//     expect(find.text("Amount (optional)"), findsOneWidget);
//     expect(find.text("0.00"), findsOneWidget);
//     expect(find.text("FIRO"), findsOneWidget);
//     expect(find.text("Note (optional)"), findsOneWidget);
//     expect(find.text("Type something..."), findsOneWidget);
//     expect(find.text("GENERATE QR CODE"), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//
//     await tester.tap(find.byKey(Key("receiveViewMoreOptionsButtonKey")));
//     await tester.pumpAndSettle();
//
//     final qr3 = find.byType(PrettyQr).evaluate().single.widget as PrettyQr;
//     expect(qr3.data, "firo:a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg");
//
//     expect(find.byType(MaterialButton), findsNWidgets(2));
//     expect(find.byType(Text), findsNWidgets(3));
//     expect(find.byType(TextField), findsNothing);
//     expect(find.byType(SimpleButton), findsOneWidget);
//     expect(find.text("MORE OPTIONS"), findsOneWidget);
//
//     expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
//     expect(find.text("TAP ADDRESS TO COPY"), findsOneWidget);
//
//     expect(find.text("Amount (optional)"), findsNothing);
//     expect(find.text("0.00"), findsNothing);
//     expect(find.text("FIRO"), findsNothing);
//     expect(find.text("Note (optional)"), findsNothing);
//     expect(find.text("Type something..."), findsNothing);
//     expect(find.text("GENERATE QR CODE"), findsNothing);
//     expect(find.byType(GradientButton), findsNothing);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.coinTicker).called(1);
//     verify(manager.currentReceivingAddress).called(6);
//
//     verifyNoMoreInteractions(manager);
//   });
//
//   testWidgets(
//       "enter amount using period decimal separator, message, then generate qr code",
//       (tester) async {
//     final channel = MethodChannel('uk.spiralarm.flutter/devicelocale');
//
//     handler(MethodCall methodCall) async {
//       if (methodCall.method == 'currentLocale') {
//         return 'en_US';
//       }
//       fail("Bad DeviceLocale MethodCall");
//     }
//
//     tester.binding.defaultBinaryMessenger
//         .setMockMethodCallHandler(channel, handler);
//
//     final manager = MockManager();
//     final clipboard = FakeClipboard();
//
//     when(manager.currentReceivingAddress)
//         .thenAnswer((_) async => "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg");
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
//           child: Material(
//             child: ReceiveView(
//               clipboard: clipboard,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byKey(Key("receiveViewMoreOptionsButtonKey")));
//     await tester.pumpAndSettle();
//
//     await tester.fling(
//         find.byType(SingleChildScrollView), Offset(0, -500), 1000);
//     await tester.pumpAndSettle();
//
//     await tester.enterText(
//         find.byKey(Key("receiveViewCryptoFieldKey")), "10.0111");
//     await tester.enterText(
//         find.byKey(Key("receiveViewNoteFieldKey")), "Some kind of Message");
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle();
//
//     final qr = find
//         .byKey(Key("receiveViewGeneratedQrCodeKey"))
//         .evaluate()
//         .single
//         .widget as PrettyQr;
//     expect(qr.data,
//         "firo:a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg?amount=10.0111&message=Some+kind+of+Message");
//
//     expect(find.byType(Text), findsNWidgets(13));
//     expect(find.text("Scan this QR Code"), findsOneWidget);
//     expect(find.text("Receive 10.0111 FIRO"), findsOneWidget);
//     expect(find.text("for \"Some kind of Message\""), findsOneWidget);
//     expect(find.text("OK"), findsOneWidget);
//     expect(find.byType(ModalPopupDialog), findsOneWidget);
//
//     await tester.tap(find.byKey(Key("receiveViewGeneratedQrPopupOkButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(ModalPopupDialog), findsNothing);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.coinTicker).called(2);
//     verify(manager.currentReceivingAddress).called(5);
//
//     verifyNoMoreInteractions(manager);
//   });
//
//   testWidgets(
//       "enter amount using comma decimal separator, message, then generate qr code",
//       (tester) async {
//     final channel = MethodChannel('uk.spiralarm.flutter/devicelocale');
//
//     handler(MethodCall methodCall) async {
//       if (methodCall.method == 'currentLocale') {
//         return 'de_DE';
//       }
//       fail("Bad DeviceLocale MethodCall");
//     }
//
//     tester.binding.defaultBinaryMessenger
//         .setMockMethodCallHandler(channel, handler);
//
//     final manager = MockManager();
//     final clipboard = FakeClipboard();
//
//     when(manager.currentReceivingAddress)
//         .thenAnswer((_) async => "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg");
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
//           child: Material(
//             child: ReceiveView(
//               clipboard: clipboard,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(ModalPopupDialog), findsNothing);
//
//     await tester.tap(find.byKey(Key("receiveViewMoreOptionsButtonKey")));
//     await tester.pumpAndSettle();
//
//     await tester.fling(
//         find.byType(SingleChildScrollView), Offset(0, -500), 1000);
//     await tester.pumpAndSettle();
//
//     await tester.enterText(
//         find.byKey(Key("receiveViewCryptoFieldKey")), "10,0111");
//     await tester.enterText(
//         find.byKey(Key("receiveViewNoteFieldKey")), "Some kind of Message");
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle();
//
//     final qr = find
//         .byKey(Key("receiveViewGeneratedQrCodeKey"))
//         .evaluate()
//         .single
//         .widget as PrettyQr;
//     expect(qr.data,
//         "firo:a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg?amount=10.0111&message=Some+kind+of+Message");
//
//     expect(find.byType(Text), findsNWidgets(13));
//     expect(find.text("Scan this QR Code"), findsOneWidget);
//     expect(find.text("Receive 10,0111 FIRO"), findsOneWidget);
//     expect(find.text("for \"Some kind of Message\""), findsOneWidget);
//     expect(find.text("OK"), findsOneWidget);
//     expect(find.byType(ModalPopupDialog), findsOneWidget);
//
//     await tester.tap(find.byKey(Key("receiveViewGeneratedQrPopupOkButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(ModalPopupDialog), findsNothing);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.coinTicker).called(2);
//     verify(manager.currentReceivingAddress).called(5);
//
//     verifyNoMoreInteractions(manager);
//   });
}
