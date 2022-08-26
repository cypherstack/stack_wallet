// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
// import 'package:stackwallet/notifications/modal_popup_dialog.dart';
// import 'package:stackwallet/pages/settings_view/settings_subviews/wallet_backup_view.dart';
import 'package:stackwallet/services/coins/manager.dart';
// import 'package:stackwallet/utilities/clipboard_interface.dart';
// import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
// import 'package:stackwallet/widgets/custom_buttons/simple_button.dart';
// import 'package:pretty_qr_code/pretty_qr_code.dart';
// import 'package:provider/provider.dart';
//
// import 'wallet_backup_view_screen_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<Manager>(returnNullOnMissingStub: true),
])
void main() {
//   testWidgets("WalletBackupView builds correctly", (tester) async {
//     final manager = MockManager();
//
//     when(manager.mnemonic).thenAnswer((_) async => [
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//         ]);
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<Manager>(
//               create: (_) => manager,
//             ),
//           ],
//           child: WalletBackUpView(),
//         ),
//       ),
//     );
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(SvgPicture), findsNWidgets(3));
//     expect(find.text("Backup Key"), findsOneWidget);
//     expect(
//         find.text("Please write down your backup key. Keep it safe and never share it with anyone." +
//             " Your backup key is the only way you can access your funds if you forget PIN, " +
//             "lose your phone, etc.\n\nCampfire Wallet does not keep nor is able to" +
//             " restore your backup key. Only you have access to your wallet."),
//         findsOneWidget);
//     expect(find.byType(BackupWarningDetails), findsOneWidget);
//     expect(find.byType(SpinKitThreeBounce), findsOneWidget);
//
//     expect(
//         find.byWidgetPredicate((widget) =>
//             widget is SimpleButton &&
//             widget.key == Key("walletBackupQrCodeButtonKey")),
//         findsOneWidget);
//     expect(
//         find.byWidgetPredicate((widget) =>
//             widget is SimpleButton &&
//             widget.key == Key("walletBackupCopyButtonKey")),
//         findsOneWidget);
//
//     expect(find.text("QR CODE"), findsOneWidget);
//     expect(find.text("COPY"), findsOneWidget);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.mnemonic).called(1);
//
//     verifyNoMoreInteractions(manager);
//   });
//
//   testWidgets("WalletBackupView loads correctly", (tester) async {
//     final manager = MockManager();
//
//     when(manager.mnemonic).thenAnswer((_) async => [
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//         ]);
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<Manager>(
//               create: (_) => manager,
//             ),
//           ],
//           child: WalletBackUpView(),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(SvgPicture), findsNWidgets(3));
//     expect(find.text("Backup Key"), findsOneWidget);
//     expect(
//         find.text("Please write down your backup key. Keep it safe and never share it with anyone." +
//             " Your backup key is the only way you can access your funds if you forget PIN, " +
//             "lose your phone, etc.\n\nCampfire Wallet does not keep nor is able to" +
//             " restore your backup key. Only you have access to your wallet."),
//         findsOneWidget);
//     expect(find.byType(BackupWarningDetails), findsOneWidget);
//     expect(find.byType(SpinKitThreeBounce), findsNothing);
//
//     expect(
//         find.byWidgetPredicate((widget) =>
//             widget is SimpleButton &&
//             widget.key == Key("walletBackupQrCodeButtonKey")),
//         findsOneWidget);
//     expect(
//         find.byWidgetPredicate((widget) =>
//             widget is SimpleButton &&
//             widget.key == Key("walletBackupCopyButtonKey")),
//         findsOneWidget);
//
//     expect(find.text("QR CODE"), findsOneWidget);
//     expect(find.text("COPY"), findsOneWidget);
//
//     expect(find.byType(SingleChildScrollView), findsOneWidget);
//     expect(find.byType(Table), findsOneWidget);
//     expect(find.byType(TableCell), findsNWidgets(36));
//
//     for (int i = 1; i <= 24; i++) {
//       expect(find.text("$i"), findsOneWidget);
//     }
//
//     expect(find.text("some"), findsNWidgets(8));
//     expect(find.text("mnemonic"), findsNWidgets(8));
//     expect(find.text("words"), findsNWidgets(8));
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.mnemonic).called(1);
//
//     verifyNoMoreInteractions(manager);
//   });
//
//   testWidgets("tap back", (tester) async {
//     final manager = MockManager();
//     final navigator = mockingjay.MockNavigator();
//
//     when(manager.mnemonic).thenAnswer((_) async => [
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//         ]);
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
//             child: WalletBackUpView(),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(SvgPicture), findsNWidgets(3));
//     expect(find.text("Backup Key"), findsOneWidget);
//     expect(
//         find.text("Please write down your backup key. Keep it safe and never share it with anyone." +
//             " Your backup key is the only way you can access your funds if you forget PIN, " +
//             "lose your phone, etc.\n\nCampfire Wallet does not keep nor is able to" +
//             " restore your backup key. Only you have access to your wallet."),
//         findsOneWidget);
//     expect(find.byType(BackupWarningDetails), findsOneWidget);
//     expect(find.byType(SpinKitThreeBounce), findsNothing);
//
//     expect(
//         find.byWidgetPredicate((widget) =>
//             widget is SimpleButton &&
//             widget.key == Key("walletBackupQrCodeButtonKey")),
//         findsOneWidget);
//     expect(
//         find.byWidgetPredicate((widget) =>
//             widget is SimpleButton &&
//             widget.key == Key("walletBackupCopyButtonKey")),
//         findsOneWidget);
//
//     expect(find.text("QR CODE"), findsOneWidget);
//     expect(find.text("COPY"), findsOneWidget);
//
//     expect(find.byType(SingleChildScrollView), findsOneWidget);
//     expect(find.byType(Table), findsOneWidget);
//     expect(find.byType(TableCell), findsNWidgets(36));
//
//     for (int i = 1; i <= 24; i++) {
//       expect(find.text("$i"), findsOneWidget);
//     }
//
//     expect(find.text("some"), findsNWidgets(8));
//     expect(find.text("mnemonic"), findsNWidgets(8));
//     expect(find.text("words"), findsNWidgets(8));
//
//     await tester.tap(find.byType(AppBarIconButton));
//     await tester.pumpAndSettle();
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.mnemonic).called(1);
//
//     verifyNoMoreInteractions(manager);
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap copy", (tester) async {
//     final manager = MockManager();
//     final clipboard = FakeClipboard();
//
//     when(manager.mnemonic).thenAnswer((_) async => [
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//         ]);
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<Manager>(
//               create: (_) => manager,
//             ),
//           ],
//           child: WalletBackUpView(
//             clipboard: clipboard,
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(SvgPicture), findsNWidgets(3));
//     expect(find.text("Backup Key"), findsOneWidget);
//     expect(
//         find.text("Please write down your backup key. Keep it safe and never share it with anyone." +
//             " Your backup key is the only way you can access your funds if you forget PIN, " +
//             "lose your phone, etc.\n\nCampfire Wallet does not keep nor is able to" +
//             " restore your backup key. Only you have access to your wallet."),
//         findsOneWidget);
//     expect(find.byType(BackupWarningDetails), findsOneWidget);
//     expect(find.byType(SpinKitThreeBounce), findsNothing);
//
//     expect(
//         find.byWidgetPredicate((widget) =>
//             widget is SimpleButton &&
//             widget.key == Key("walletBackupQrCodeButtonKey")),
//         findsOneWidget);
//     expect(
//         find.byWidgetPredicate((widget) =>
//             widget is SimpleButton &&
//             widget.key == Key("walletBackupCopyButtonKey")),
//         findsOneWidget);
//
//     expect(find.text("QR CODE"), findsOneWidget);
//     expect(find.text("COPY"), findsOneWidget);
//
//     expect(find.byType(SingleChildScrollView), findsOneWidget);
//     expect(find.byType(Table), findsOneWidget);
//     expect(find.byType(TableCell), findsNWidgets(36));
//
//     for (int i = 1; i <= 24; i++) {
//       expect(find.text("$i"), findsOneWidget);
//     }
//
//     expect(find.text("some"), findsNWidgets(8));
//     expect(find.text("mnemonic"), findsNWidgets(8));
//     expect(find.text("words"), findsNWidgets(8));
//
//     await tester.tap(find.byWidgetPredicate((widget) =>
//         widget is SimpleButton &&
//         widget.key == Key("walletBackupCopyButtonKey")));
//     await tester.pump(Duration(milliseconds: 500));
//
//     expect((await clipboard.getData(Clipboard.kTextPlain)).text,
//         "some mnemonic words some mnemonic words some mnemonic words some mnemonic words some mnemonic words some mnemonic words some mnemonic words some mnemonic words");
//     expect(find.text("Copied to clipboard"), findsOneWidget);
//
//     await tester.pump(Duration(seconds: 2));
//     expect(find.text("Copied to clipboard"), findsNothing);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.mnemonic).called(2);
//
//     verifyNoMoreInteractions(manager);
//   });
//
//   testWidgets("tap qr code", (tester) async {
//     final manager = MockManager();
//
//     when(manager.mnemonic).thenAnswer((_) async => [
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//           "some",
//           "mnemonic",
//           "words",
//         ]);
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<Manager>(
//               create: (_) => manager,
//             ),
//           ],
//           child: WalletBackUpView(),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(SvgPicture), findsNWidgets(3));
//     expect(find.text("Backup Key"), findsOneWidget);
//     expect(
//         find.text("Please write down your backup key. Keep it safe and never share it with anyone." +
//             " Your backup key is the only way you can access your funds if you forget PIN, " +
//             "lose your phone, etc.\n\nCampfire Wallet does not keep nor is able to" +
//             " restore your backup key. Only you have access to your wallet."),
//         findsOneWidget);
//     expect(find.byType(BackupWarningDetails), findsOneWidget);
//     expect(find.byType(SpinKitThreeBounce), findsNothing);
//
//     expect(
//         find.byWidgetPredicate((widget) =>
//             widget is SimpleButton &&
//             widget.key == Key("walletBackupQrCodeButtonKey")),
//         findsOneWidget);
//     expect(
//         find.byWidgetPredicate((widget) =>
//             widget is SimpleButton &&
//             widget.key == Key("walletBackupCopyButtonKey")),
//         findsOneWidget);
//
//     expect(find.text("QR CODE"), findsOneWidget);
//     expect(find.text("COPY"), findsOneWidget);
//
//     expect(find.byType(SingleChildScrollView), findsOneWidget);
//     expect(find.byType(Table), findsOneWidget);
//     expect(find.byType(TableCell), findsNWidgets(36));
//
//     for (int i = 1; i <= 24; i++) {
//       expect(find.text("$i"), findsOneWidget);
//     }
//
//     expect(find.text("some"), findsNWidgets(8));
//     expect(find.text("mnemonic"), findsNWidgets(8));
//     expect(find.text("words"), findsNWidgets(8));
//
//     await tester.tap(find.byWidgetPredicate((widget) =>
//         widget is SimpleButton &&
//         widget.key == Key("walletBackupQrCodeButtonKey")));
//     await tester.pump();
//
//     expect(find.byType(ModalPopupDialog), findsOneWidget);
//     expect(find.byType(CircularProgressIndicator), findsOneWidget);
//
//     await tester.pumpAndSettle();
//     expect(find.byType(CircularProgressIndicator), findsNothing);
//
//     expect(find.text("Backup Key QR Code"), findsOneWidget);
//     expect(find.byType(PrettyQr), findsOneWidget);
//
//     await tester.tap(find.byWidgetPredicate((widget) =>
//         widget is SimpleButton &&
//         widget.key == Key("walletBackupQrCodeCancelButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(CircularProgressIndicator), findsNothing);
//     expect(find.byType(ModalPopupDialog), findsNothing);
//     expect(
//         find.byWidgetPredicate((widget) =>
//             widget is SimpleButton &&
//             widget.key == Key("walletBackupQrCodeCancelButtonKey")),
//         findsNothing);
//     expect(find.text("Backup Key QR Code"), findsNothing);
//     expect(find.byType(PrettyQr), findsNothing);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.mnemonic).called(2);
//
//     verifyNoMoreInteractions(manager);
//   });
}
