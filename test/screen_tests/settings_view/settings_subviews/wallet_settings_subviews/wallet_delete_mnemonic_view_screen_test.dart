// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
// import 'package:epicmobile/notifications/modal_popup_dialog.dart';
// import 'package:epicmobile/pages/settings_view/settings_subviews/wallet_settings_subviews/wallet_delete_mnemonic_view.dart';
import 'package:epicmobile/services/coins/manager.dart';
import 'package:epicmobile/services/wallets_service.dart';
// import 'package:epicmobile/utilities/clipboard_interface.dart';
// import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
// import 'package:epicmobile/widgets/custom_buttons/gradient_button.dart';
// import 'package:epicmobile/widgets/custom_buttons/simple_button.dart';
// import 'package:pretty_qr_code/pretty_qr_code.dart';
// import 'package:provider/provider.dart';
//
// import 'wallet_delete_mnemonic_view_screen_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<WalletsService>(returnNullOnMissingStub: true),
  MockSpec<Manager>(returnNullOnMissingStub: true),
])
void main() {
//   testWidgets("WalletDeleteMnemonicView builds correctly", (tester) async {
//     await tester.pumpWidget(
//       MaterialApp(
//         home: WalletDeleteMnemonicView(),
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
//     final walletsService = MockWalletsService();
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
//             ChangeNotifierProvider<WalletsService>(
//               create: (_) => walletsService,
//             ),
//           ],
//           child: WalletDeleteMnemonicView(),
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
//                 .byKey(Key("walletDeleteShowQrCodeButtonKey"))
//                 .evaluate()
//                 .first
//                 .widget as SimpleButton)
//             .enabled,
//         true);
//     expect(
//         (find
//                 .byKey(Key("walletDeleteCopySeedButtonKey"))
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
//     verifyNoMoreInteractions(walletsService);
//   });
//
//   testWidgets("tap back", (tester) async {
//     final manager = MockManager();
//     final walletsService = MockWalletsService();
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
//               ChangeNotifierProvider<WalletsService>(
//                 create: (_) => walletsService,
//               ),
//             ],
//             child: WalletDeleteMnemonicView(),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//
//     await tester.tap(find.byType(AppBarIconButton));
//     await tester.pump(Duration(milliseconds: 100));
//
//     verify(manager.mnemonic).called(1);
//     verify(manager.addListener(any)).called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(walletsService);
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("show qr code", (tester) async {
//     final manager = MockManager();
//     final walletsService = MockWalletsService();
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
//             ChangeNotifierProvider<WalletsService>(
//               create: (_) => walletsService,
//             ),
//           ],
//           child: WalletDeleteMnemonicView(),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byKey(Key("walletDeleteShowQrCodeButtonKey")));
//     await tester.pump();
//
//     expect(find.byType(ModalPopupDialog), findsOneWidget);
//     expect(find.text("Backup Key QR Code"), findsOneWidget);
//     expect(find.text("CANCEL"), findsOneWidget);
//     expect(find.byType(CircularProgressIndicator), findsOneWidget);
//     expect(find.byKey(Key("deleteWalletQrCodePopupCancelButtonKey")),
//         findsOneWidget);
//
//     await tester.pumpAndSettle();
//
//     expect(find.byType(PrettyQr), findsOneWidget);
//     expect(find.byType(CircularProgressIndicator), findsNothing);
//
//     await tester.tap(find.byKey(Key("deleteWalletQrCodePopupCancelButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(ModalPopupDialog), findsNothing);
//     expect(find.text("Backup Key QR Code"), findsNothing);
//     expect(find.text("CANCEL"), findsNothing);
//     expect(find.byType(CircularProgressIndicator), findsNothing);
//     expect(find.byKey(Key("deleteWalletQrCodePopupCancelButtonKey")),
//         findsNothing);
//     expect(find.byType(PrettyQr), findsNothing);
//
//     verify(manager.mnemonic).called(2);
//     verify(manager.addListener(any)).called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(walletsService);
//   });
//
//   testWidgets("copy backup key", (tester) async {
//     final manager = MockManager();
//     final walletsService = MockWalletsService();
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
//             ChangeNotifierProvider<WalletsService>(
//               create: (_) => walletsService,
//             ),
//           ],
//           child: WalletDeleteMnemonicView(
//             clipboard: clipboard,
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect((await clipboard.getData(Clipboard.kTextPlain)).text, null);
//
//     await tester.tap(find.byKey(Key("walletDeleteCopySeedButtonKey")));
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
//     verifyNoMoreInteractions(walletsService);
//   });
//
//   testWidgets("tap continue then cancel", (tester) async {
//     final manager = MockManager();
//     final walletsService = MockWalletsService();
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
//             ChangeNotifierProvider<WalletsService>(
//               create: (_) => walletsService,
//             ),
//           ],
//           child: WalletDeleteMnemonicView(),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(ModalPopupDialog), findsOneWidget);
//     expect(find.text("Thanks!\nYour wallet will be deleted"), findsOneWidget);
//     expect(
//         find.byKey(Key("walletDeleteContinueCancelButtonKey")), findsOneWidget);
//     expect(
//         find.byKey(Key("walletDeleteContinueDeleteButtonKey")), findsOneWidget);
//     expect(find.text("CANCEL"), findsOneWidget);
//     expect(find.text("DELETE"), findsOneWidget);
//
//     await tester.tap(find.byKey(Key("walletDeleteContinueCancelButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(ModalPopupDialog), findsNothing);
//     expect(find.text("Thanks!\nYour wallet will be deleted"), findsNothing);
//     expect(
//         find.byKey(Key("walletDeleteContinueCancelButtonKey")), findsNothing);
//     expect(
//         find.byKey(Key("walletDeleteContinueDeleteButtonKey")), findsNothing);
//     expect(find.text("CANCEL"), findsNothing);
//     expect(find.text("DELETE"), findsNothing);
//
//     verify(manager.mnemonic).called(1);
//     verify(manager.addListener(any)).called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(walletsService);
//   });
//
//   testWidgets("tap continue then delete last wallet", (tester) async {
//     final manager = MockManager();
//     final walletsService = MockWalletsService();
//     final navigator = mockingjay.MockNavigator();
//
//     mockingjay
//         .when(() => navigator.pushAndRemoveUntil(
//             mockingjay.any(
//                 that: mockingjay.isRoute(
//                     whereName: equals("/onboardingview"),
//                     whereMaintainState: equals(false))),
//             mockingjay.any()))
//         .thenAnswer((_) async {});
//
//     when(walletsService.currentWalletName).thenAnswer((_) async => "my wallet");
//     when(walletsService.deleteWallet("my wallet")).thenAnswer((_) async => 2);
//
//     when(manager.exitCurrentWallet()).thenAnswer((_) async {});
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
//               ChangeNotifierProvider<WalletsService>(
//                 create: (_) => walletsService,
//               ),
//             ],
//             child: WalletDeleteMnemonicView(),
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
//     expect(find.text("Thanks!\nYour wallet will be deleted"), findsOneWidget);
//     expect(
//         find.byKey(Key("walletDeleteContinueCancelButtonKey")), findsOneWidget);
//     expect(
//         find.byKey(Key("walletDeleteContinueDeleteButtonKey")), findsOneWidget);
//     expect(find.text("CANCEL"), findsOneWidget);
//     expect(find.text("DELETE"), findsOneWidget);
//
//     await tester.tap(find.byKey(Key("walletDeleteContinueDeleteButtonKey")));
//     await tester.pumpAndSettle();
//
//     verify(manager.mnemonic).called(1);
//     verify(manager.exitCurrentWallet()).called(1);
//     verify(manager.addListener(any)).called(1);
//
//     verify(walletsService.addListener(any)).called(1);
//     verify(walletsService.currentWalletName).called(1);
//     verify(walletsService.deleteWallet("my wallet")).called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(walletsService);
//
//     mockingjay
//         .verify(() => navigator.pushAndRemoveUntil(
//             mockingjay.any(
//                 that: mockingjay.isRoute(
//                     whereName: equals("/onboardingview"),
//                     whereMaintainState: equals(false))),
//             mockingjay.any()))
//         .called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap continue then delete with more than one remaining wallet",
//       (tester) async {
//     final manager = MockManager();
//     final walletsService = MockWalletsService();
//     final navigator = mockingjay.MockNavigator();
//
//     mockingjay
//         .when(() => navigator.pushAndRemoveUntil(
//             mockingjay.any(
//                 that: mockingjay.isRoute(
//                     whereName: equals("/walletselectionview"),
//                     whereMaintainState: equals(true))),
//             mockingjay.any()))
//         .thenAnswer((_) async {});
//
//     when(walletsService.currentWalletName).thenAnswer((_) async => "my wallet");
//     when(walletsService.deleteWallet("my wallet")).thenAnswer((_) async => 0);
//
//     when(manager.exitCurrentWallet()).thenAnswer((_) async {});
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
//               ChangeNotifierProvider<WalletsService>(
//                 create: (_) => walletsService,
//               ),
//             ],
//             child: WalletDeleteMnemonicView(),
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
//     expect(find.text("Thanks!\nYour wallet will be deleted"), findsOneWidget);
//     expect(
//         find.byKey(Key("walletDeleteContinueCancelButtonKey")), findsOneWidget);
//     expect(
//         find.byKey(Key("walletDeleteContinueDeleteButtonKey")), findsOneWidget);
//     expect(find.text("CANCEL"), findsOneWidget);
//     expect(find.text("DELETE"), findsOneWidget);
//
//     await tester.tap(find.byKey(Key("walletDeleteContinueDeleteButtonKey")));
//     await tester.pumpAndSettle();
//
//     verify(manager.mnemonic).called(1);
//     verify(manager.exitCurrentWallet()).called(1);
//     verify(manager.addListener(any)).called(1);
//
//     verify(walletsService.addListener(any)).called(1);
//     verify(walletsService.currentWalletName).called(1);
//     verify(walletsService.deleteWallet("my wallet")).called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(walletsService);
//
//     mockingjay
//         .verify(() => navigator.pushAndRemoveUntil(
//             mockingjay.any(
//                 that: mockingjay.isRoute(
//                     whereName: equals("/walletselectionview"),
//                     whereMaintainState: equals(true))),
//             mockingjay.any()))
//         .called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
}
