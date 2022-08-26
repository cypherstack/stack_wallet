// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
// import 'package:stackwallet/notifications/modal_popup_dialog.dart';
// import 'package:stackwallet/pages/settings_view/settings_subviews/wallet_settings_subviews/rescan_warning_view.dart';
import 'package:stackwallet/services/coins/manager.dart';
// import 'package:stackwallet/utilities/clipboard_interface.dart';
// import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
// import 'package:stackwallet/widgets/custom_buttons/gradient_button.dart';
// import 'package:stackwallet/widgets/custom_buttons/simple_button.dart';
// import 'package:pretty_qr_code/pretty_qr_code.dart';
// import 'package:provider/provider.dart';
//
// import 'rescan_warning_view_screen_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<Manager>(returnNullOnMissingStub: true),
])
void main() {
//   testWidgets("RescanWarningView builds correctly", (tester) async {
//     await tester.pumpWidget(
//       MaterialApp(
//         home: RescanWarningView(),
//       ),
//     );
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(Text), findsNWidgets(5));
//     expect(find.byType(SpinKitThreeBounce), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsNWidgets(2));
//     expect(find.byType(SvgPicture), findsNWidgets(3));
//     expect(find.text("Backup Key"), findsOneWidget);
//     expect(find.text("Please write down your backup key."), findsOneWidget);
//     expect(find.text("QR CODE"), findsOneWidget);
//     expect(find.text("COPY"), findsOneWidget);
//     expect(find.text("CONTINUE"), findsOneWidget);
//   });
//
//   testWidgets("WalletDeleteMnemonicView loads correctly", (tester) async {
//     final manager = MockManager();
//
//     when(manager.mnemonic).thenAnswer(
//       (_) async => [
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//       ],
//     );
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<Manager>(
//               create: (_) => manager,
//             ),
//           ],
//           child: RescanWarningView(),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(Text), findsNWidgets(53));
//     expect(find.byType(SpinKitThreeBounce), findsNothing);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsNWidgets(2));
//     expect(find.byType(SvgPicture), findsNWidgets(3));
//     expect(
//         (find.byType(GradientButton).evaluate().first.widget as GradientButton)
//             .enabled,
//         true);
//     expect(
//         (find
//                 .byKey(Key("rescanWarningShowQrCodeButtonKey"))
//                 .evaluate()
//                 .first
//                 .widget as SimpleButton)
//             .enabled,
//         true);
//     expect(
//         (find
//                 .byKey(Key("rescanWarningCopySeedButtonKey"))
//                 .evaluate()
//                 .first
//                 .widget as SimpleButton)
//             .enabled,
//         true);
//     expect(find.text("Backup Key"), findsOneWidget);
//     expect(find.text("Please write down your backup key."), findsOneWidget);
//     expect(find.text("QR CODE"), findsOneWidget);
//     expect(find.text("COPY"), findsOneWidget);
//     expect(find.text("CONTINUE"), findsOneWidget);
//
//     expect(find.byType(Table), findsOneWidget);
//     expect(find.byType(SingleChildScrollView), findsOneWidget);
//     expect(find.byType(TableCell), findsNWidgets(36));
//
//     expect(find.text("some"), findsNWidgets(8));
//     expect(find.text("mnemonic"), findsNWidgets(8));
//     expect(find.text("words"), findsNWidgets(8));
//
//     for (int i = 1; i <= 24; i++) {
//       expect(find.text("$i"), findsOneWidget);
//     }
//
//     verify(manager.mnemonic).called(1);
//     verify(manager.addListener(any)).called(1);
//
//     verifyNoMoreInteractions(manager);
//   });
//
//   testWidgets("tap back", (tester) async {
//     final manager = MockManager();
//     final navigator = mockingjay.MockNavigator();
//
//     when(manager.mnemonic).thenAnswer(
//       (_) async => [
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//       ],
//     );
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) {});
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
//             ],
//             child: RescanWarningView(),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//
//     await tester.tap(find.byKey(Key("settingsAppBarBackButton")));
//     await tester.pump(Duration(milliseconds: 100));
//
//     verify(manager.mnemonic).called(1);
//     verify(manager.addListener(any)).called(1);
//
//     verifyNoMoreInteractions(manager);
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("show qr code", (tester) async {
//     final manager = MockManager();
//
//     when(manager.mnemonic).thenAnswer(
//       (_) async => [
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//       ],
//     );
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<Manager>(
//               create: (_) => manager,
//             ),
//           ],
//           child: RescanWarningView(),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byKey(Key("rescanWarningShowQrCodeButtonKey")));
//     await tester.pump();
//
//     expect(find.byType(ModalPopupDialog), findsOneWidget);
//     expect(find.text("Backup Key QR Code"), findsOneWidget);
//     expect(find.text("CANCEL"), findsOneWidget);
//     expect(find.byType(CircularProgressIndicator), findsOneWidget);
//     expect(find.byKey(Key("rescanWarningQrCodePopupCancelButtonKey")),
//         findsOneWidget);
//
//     await tester.pumpAndSettle();
//
//     expect(find.byType(PrettyQr), findsOneWidget);
//     expect(find.byType(CircularProgressIndicator), findsNothing);
//
//     await tester
//         .tap(find.byKey(Key("rescanWarningQrCodePopupCancelButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(ModalPopupDialog), findsNothing);
//     expect(find.text("Backup Key QR Code"), findsNothing);
//     expect(find.text("CANCEL"), findsNothing);
//     expect(find.byType(CircularProgressIndicator), findsNothing);
//     expect(find.byKey(Key("rescanWarningQrCodePopupCancelButtonKey")),
//         findsNothing);
//     expect(find.byType(PrettyQr), findsNothing);
//
//     verify(manager.mnemonic).called(2);
//     verify(manager.addListener(any)).called(1);
//
//     verifyNoMoreInteractions(manager);
//   });
//
//   testWidgets("copy backup key", (tester) async {
//     final manager = MockManager();
//     final clipboard = FakeClipboard();
//
//     when(manager.mnemonic).thenAnswer(
//       (_) async => [
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//       ],
//     );
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<Manager>(
//               create: (_) => manager,
//             ),
//           ],
//           child: RescanWarningView(
//             clipboard: clipboard,
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect((await clipboard.getData(Clipboard.kTextPlain)).text, null);
//
//     await tester.tap(find.byKey(Key("rescanWarningCopySeedButtonKey")));
//     await tester.pump(Duration(milliseconds: 200));
//
//     expect(find.text("Copied to clipboard"), findsOneWidget);
//
//     await tester.pump(Duration(seconds: 2));
//
//     expect(find.text("Copied to clipboard"), findsNothing);
//
//     expect(
//       (await clipboard.getData(Clipboard.kTextPlain)).text,
//       "some mnemonic words some mnemonic words some mnemonic words some mnemonic words some mnemonic words some mnemonic words some mnemonic words some mnemonic words",
//     );
//
//     verify(manager.mnemonic).called(2);
//     verify(manager.addListener(any)).called(1);
//
//     verifyNoMoreInteractions(manager);
//   });
//
//   testWidgets("tap continue then cancel", (tester) async {
//     final manager = MockManager();
//
//     when(manager.mnemonic).thenAnswer(
//       (_) async => [
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//       ],
//     );
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<Manager>(
//               create: (_) => manager,
//             ),
//           ],
//           child: RescanWarningView(),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(ModalPopupDialog), findsOneWidget);
//     expect(find.text("Thanks!\nYour wallet will be completely rescanned"),
//         findsOneWidget);
//     expect(find.byKey(Key("rescanWarningContinueCancelButtonKey")),
//         findsOneWidget);
//     expect(find.byKey(Key("rescanWarningContinueRescanButtonKey")),
//         findsOneWidget);
//     expect(find.text("CANCEL"), findsOneWidget);
//     expect(find.text("RESCAN"), findsOneWidget);
//
//     await tester.tap(find.byKey(Key("rescanWarningContinueCancelButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(ModalPopupDialog), findsNothing);
//     expect(find.text("Thanks!\nYour wallet will be deleted"), findsNothing);
//     expect(
//         find.byKey(Key("rescanWarningContinueCancelButtonKey")), findsNothing);
//     expect(
//         find.byKey(Key("rescanWarningContinueRescanButtonKey")), findsNothing);
//     expect(find.text("CANCEL"), findsNothing);
//     expect(find.text("RESCAN"), findsNothing);
//
//     verify(manager.mnemonic).called(1);
//     verify(manager.addListener(any)).called(1);
//
//     verifyNoMoreInteractions(manager);
//   });
//
//   testWidgets("tap continue then rescan", (tester) async {
//     final manager = MockManager();
//     final navigator = mockingjay.MockNavigator();
//
//     mockingjay
//         .when(() => navigator.pushReplacementNamed("/mainview"))
//         .thenAnswer((_) async => {});
//
//     when(manager.fullRescan()).thenAnswer((_) async {});
//     when(manager.mnemonic).thenAnswer(
//       (_) async => [
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//       ],
//     );
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
//             ],
//             child: RescanWarningView(),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(ModalPopupDialog), findsOneWidget);
//     expect(find.text("Thanks!\nYour wallet will be completely rescanned"),
//         findsOneWidget);
//     expect(find.byKey(Key("rescanWarningContinueCancelButtonKey")),
//         findsOneWidget);
//     expect(find.byKey(Key("rescanWarningContinueRescanButtonKey")),
//         findsOneWidget);
//     expect(find.text("CANCEL"), findsOneWidget);
//     expect(find.text("RESCAN"), findsOneWidget);
//
//     await tester.tap(find.byKey(Key("rescanWarningContinueRescanButtonKey")));
//     await tester.pump(Duration(milliseconds: 100));
//     await tester.pump(Duration(milliseconds: 100));
//     await tester.pump(Duration(milliseconds: 100));
//
//     expect(find.text("Rescanning wallet"), findsOneWidget);
//     expect(find.text("This may take a while."), findsOneWidget);
//     expect(find.text("Do not close or leave the app until this completes!"),
//         findsOneWidget);
//     expect(find.byType(CircularProgressIndicator), findsOneWidget);
//
//     await tester.pump(Duration(seconds: 1));
//
//     expect(find.text("Rescan Complete!"), findsOneWidget);
//
//     await tester.pump(Duration(seconds: 2));
//
//     verify(manager.mnemonic).called(1);
//     verify(manager.fullRescan()).called(1);
//     verify(manager.addListener(any)).called(1);
//
//     verifyNoMoreInteractions(manager);
//
//     mockingjay
//         .verify(() => navigator.pushReplacementNamed("/mainview"))
//         .called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap continue and rescan throws", (tester) async {
//     final manager = MockManager();
//     final navigator = mockingjay.MockNavigator();
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) async => {});
//
//     when(manager.fullRescan())
//         .thenThrow(Exception("Rescan failed error message"));
//     when(manager.mnemonic).thenAnswer(
//       (_) async => [
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//         "some",
//         "mnemonic",
//         "words",
//       ],
//     );
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
//             ],
//             child: RescanWarningView(),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(ModalPopupDialog), findsOneWidget);
//     expect(find.text("Thanks!\nYour wallet will be completely rescanned"),
//         findsOneWidget);
//     expect(find.byKey(Key("rescanWarningContinueCancelButtonKey")),
//         findsOneWidget);
//     expect(find.byKey(Key("rescanWarningContinueRescanButtonKey")),
//         findsOneWidget);
//     expect(find.text("CANCEL"), findsOneWidget);
//     expect(find.text("RESCAN"), findsOneWidget);
//
//     await tester.tap(find.byKey(Key("rescanWarningContinueRescanButtonKey")));
//     await tester.pump(Duration(milliseconds: 100));
//     await tester.pump(Duration(milliseconds: 100));
//     await tester.pump(Duration(milliseconds: 100));
//
//     expect(find.text("Rescanning wallet"), findsOneWidget);
//     expect(find.text("This may take a while."), findsOneWidget);
//     expect(find.text("Do not close or leave the app until this completes!"),
//         findsOneWidget);
//     expect(find.byType(CircularProgressIndicator), findsOneWidget);
//
//     await tester.pump(Duration(seconds: 1));
//
//     expect(find.byType(RescanFailedDialog), findsOneWidget);
//     expect(find.text("Rescan wallet failed."), findsOneWidget);
//     expect(find.text("Exception: Rescan failed error message"), findsOneWidget);
//
//     await tester.pump(Duration(seconds: 2));
//
//     verify(manager.mnemonic).called(1);
//     verify(manager.fullRescan()).called(1);
//     verify(manager.addListener(any)).called(1);
//
//     verifyNoMoreInteractions(manager);
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("RescanFailedDialog test", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) async => {});
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: RescanFailedDialog(
//             errorMessage: "Some error message",
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byKey(Key("rescanWarningViewRescanFailedOkButtonKey")),
//         findsOneWidget);
//     expect(find.text("Rescan wallet failed."), findsOneWidget);
//     expect(find.text("Some error message"), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.text("OK"), findsOneWidget);
//
//     await tester
//         .tap(find.byKey(Key("rescanWarningViewRescanFailedOkButtonKey")));
//     await tester.pumpAndSettle();
//
//     mockingjay.verify(() => navigator.pop()).called(3);
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
}
