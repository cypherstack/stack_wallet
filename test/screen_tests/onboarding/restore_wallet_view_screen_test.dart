// import 'package:barcode_scan2/barcode_scan2.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
// import 'package:provider/provider.dart';
// import 'package:stackwallet/notifications/campfire_alert.dart';
// import 'package:stackwallet/pages/onboarding_view/restore_wallet_form_view.dart';
// import 'package:stackwallet/services/coins/firo/firo_wallet.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/wallets_service.dart';
import 'package:stackwallet/utilities/barcode_scanner_interface.dart';
// import 'package:stackwallet/utilities/clipboard_interface.dart';
// import 'package:stackwallet/utilities/misc_global_constants.dart';
// import 'package:stackwallet/widgets/custom_buttons/gradient_button.dart';
//
// import '../../services/coins/firo/firo_wallet_test_parameters.dart';
// import 'restore_wallet_view_screen_test.mocks.dart';

@GenerateMocks([
  BarcodeScannerWrapper
], customMocks: [
  MockSpec<WalletsService>(returnNullOnMissingStub: true),
  MockSpec<Manager>(returnNullOnMissingStub: true),
  MockSpec<NodeService>(returnNullOnMissingStub: true),
])
void main() {
//   testWidgets("RestoreWalletView builds correctly", (tester) async {
//     await tester.pumpWidget(
//       MaterialApp(
//         home: RestoreWalletFormView(
//           walletName: "My Firo Wallet",
//           firoNetworkType: FiroNetworkType.main,
//         ),
//       ),
//     );
//
//     expect(find.byKey(Key("onboardingAppBarBackButton")), findsOneWidget);
//     expect(find.byKey(Key("onboardingAppBarBackButtonChevronSvg")),
//         findsOneWidget);
//
//     final imageFinder = find.byType(Image);
//     expect(imageFinder, findsOneWidget);
//
//     final imageSource =
//         ((imageFinder.evaluate().single.widget as Image).image as AssetImage)
//             .assetName;
//     expect(imageSource, "assets/images/logo.png");
//
//     expect(find.text("Restore wallet"), findsOneWidget);
//     expect(find.text("Enter your 24-word backup key."), findsOneWidget);
//
//     expect(find.byType(SvgPicture), findsNWidgets(3));
//     expect(find.byType(SingleChildScrollView), findsOneWidget);
//
//     for (int i = 1; i <= 24; i++) {
//       String expected = i < 10 ? " $i" : "$i";
//       expect(find.text(expected), findsOneWidget);
//     }
//
//     expect(find.byType(TextField), findsNWidgets(24));
//     expect(find.text("Enter word..."), findsNWidgets(24));
//
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.text("RESTORE"), findsOneWidget);
//   });
//
//   testWidgets("back button test A", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//     final walletsService = MockWalletsService();
//     final manager = MockManager();
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) async => {});
//
//     when(walletsService.deleteWallet("My Firo Wallet"))
//         .thenAnswer((_) async => 0);
//     when(manager.exitCurrentWallet()).thenAnswer((_) async => {});
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<WalletsService>(
//                 create: (_) => walletsService,
//               ),
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//             ],
//             child: RestoreWalletFormView(
//               walletName: "My Firo Wallet",
//               firoNetworkType: FiroNetworkType.main,
//             ),
//           ),
//         ),
//       ),
//     );
//
//     await tester.tap(find.byKey(Key("onboardingAppBarBackButton")));
//     await tester.pumpAndSettle();
//
//     mockingjay.verify(() => navigator.pop()).called(2);
//   });
//
//   testWidgets("back button test B", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//     final walletsService = MockWalletsService();
//     final manager = MockManager();
//
//     mockingjay
//         .when(() =>
//             navigator.pushAndRemoveUntil(mockingjay.any(), mockingjay.any()))
//         .thenAnswer((_) async => {});
//
//     when(walletsService.deleteWallet("My Firo Wallet"))
//         .thenAnswer((_) async => 2);
//     when(manager.exitCurrentWallet()).thenAnswer((_) async => {});
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<WalletsService>(
//                 create: (_) => walletsService,
//               ),
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//             ],
//             child: RestoreWalletFormView(
//               walletName: "My Firo Wallet",
//               firoNetworkType: FiroNetworkType.main,
//             ),
//           ),
//         ),
//       ),
//     );
//
//     await tester.tap(find.byKey(Key("onboardingAppBarBackButton")));
//     await tester.pumpAndSettle();
//
//     mockingjay
//         .verify(() =>
//             navigator.pushAndRemoveUntil(mockingjay.any(), mockingjay.any()))
//         .called(1);
//   });
//
//   testWidgets("scan qr button succeeds", (tester) async {
//     final scanner = MockBarcodeScannerWrapper();
//
//     when(scanner.scan()).thenAnswer((_) async => ScanResult(
//         rawContent:
//             '{"mnemonic": ["some","mnemonic","words","some","mnemonic","words","some","mnemonic","words","some","mnemonic","words","some","mnemonic","words","some","mnemonic","words","some","mnemonic","words","some","mnemonic","words"]}'));
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: RestoreWalletFormView(
//           walletName: "My Firo Wallet",
//           firoNetworkType: FiroNetworkType.main,
//           barcodeScanner: scanner,
//         ),
//       ),
//     );
//
//     await tester.tap(find.byKey(Key("restoreWalletViewScanQRButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.text("some"), findsNWidgets(8));
//     expect(find.text("mnemonic"), findsNWidgets(8));
//     expect(find.text("words"), findsNWidgets(8));
//
//     verify(scanner.scan()).called(1);
//
//     verifyNoMoreInteractions(scanner);
//   });
//
//   testWidgets("paste button test", (tester) async {
//     final clipboard = FakeClipboard();
//     clipboard.setData(ClipboardData(
//         text:
//             "some mnemonic words some mnemonic words some mnemonic words some mnemonic words some mnemonic words some mnemonic words some mnemonic words some mnemonic words"));
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: RestoreWalletFormView(
//           walletName: "My Firo Wallet",
//           firoNetworkType: FiroNetworkType.main,
//           clipboard: clipboard,
//         ),
//       ),
//     );
//
//     await tester.tap(find.byKey(Key("restoreWalletViewPasteButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.text("some"), findsNWidgets(8));
//     expect(find.text("mnemonic"), findsNWidgets(8));
//     expect(find.text("words"), findsNWidgets(8));
//   });
//
//   testWidgets("paste valid seed word", (tester) async {
//     final clipboard = FakeClipboard();
//     clipboard.setData(ClipboardData(text: "tree"));
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: RestoreWalletFormView(
//           walletName: "My Firo Wallet",
//           firoNetworkType: FiroNetworkType.main,
//           clipboard: clipboard,
//         ),
//       ),
//     );
//
//     await tester.tap(find.byKey(Key("restoreWalletViewPasteButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.text("tree"), findsOneWidget);
//     expect(find.text("Please check spelling"), findsNothing);
//   });
//
//   testWidgets("paste invalid seed word", (tester) async {
//     final clipboard = FakeClipboard();
//     clipboard.setData(ClipboardData(text: "trees"));
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: RestoreWalletFormView(
//           walletName: "My Firo Wallet",
//           firoNetworkType: FiroNetworkType.main,
//           clipboard: clipboard,
//         ),
//       ),
//     );
//
//     await tester.tap(find.byKey(Key("restoreWalletViewPasteButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.text("trees"), findsOneWidget);
//     expect(find.text("Please check spelling"), findsOneWidget);
//   });
//
//   testWidgets("restore an miss spelled mnemonic", (tester) async {
//     final clipboard = FakeClipboard();
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: RestoreWalletFormView(
//           walletName: "My Firo Wallet",
//           firoNetworkType: FiroNetworkType.main,
//           clipboard: clipboard,
//         ),
//       ),
//     );
//
//     for (int i = 1; i <= 24; i++) {
//       await tester.enterText(
//           find.byKey(Key("restoreMnemonicFormField_$i")), "trees");
//     }
//     await tester.pumpAndSettle();
//
//     await tester.fling(
//         find.byType(SingleChildScrollView), Offset(0, -500), 10000);
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(RestoreWalletFormView), findsOneWidget);
//     expect(find.text("Invalid seed phrase!"), findsNothing);
//   });
//
//   testWidgets("restore an invalid mnemonic", (tester) async {
//     final clipboard = FakeClipboard();
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: RestoreWalletFormView(
//           walletName: "My Firo Wallet",
//           firoNetworkType: FiroNetworkType.main,
//           clipboard: clipboard,
//         ),
//       ),
//     );
//
//     for (int i = 1; i <= 24; i++) {
//       await tester.enterText(
//           find.byKey(Key("restoreMnemonicFormField_$i")), "tree");
//     }
//     await tester.pumpAndSettle();
//
//     await tester.fling(
//         find.byType(SingleChildScrollView), Offset(0, -500), 10000);
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(CampfireAlert), findsOneWidget);
//     expect(find.text("Invalid seed phrase!"), findsOneWidget);
//
//     await tester.tap(find.byWidgetPredicate((widget) =>
//         widget is GradientButton &&
//         widget.key != Key("restoreMnemonicViewRestoreButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(CampfireAlert), findsNothing);
//   });
//
//   testWidgets("restore a valid mnemonic", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//     final manager = MockManager();
//     final walletsService = MockWalletsService();
//     final nodeService = MockNodeService();
//     final clipboard = FakeClipboard();
//
//     clipboard.setData(ClipboardData(text: TEST_MNEMONIC));
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) async => {});
//     mockingjay
//         .when(() => navigator.pushReplacementNamed("/mainview"))
//         .thenAnswer((_) async => {});
//
//     when(manager.hasWallet).thenAnswer((_) => true);
//     when(manager.exitCurrentWallet()).thenAnswer((_) async => {});
//     when(manager.recoverFromMnemonic(TEST_MNEMONIC)).thenAnswer((_) async {});
//
//     when(walletsService.refreshWallets()).thenAnswer((_) async => {});
//     when(walletsService.currentWalletName)
//         .thenAnswer((_) async => "My Firo Wallet");
//     when(walletsService.getWalletId("My Firo Wallet"))
//         .thenAnswer((_) async => "walletID");
//
//     when(nodeService.reInit()).thenAnswer((_) async => {});
//     when(
//       nodeService.createNode(
//         name: CampfireConstants.defaultNodeName,
//         ipAddress: CampfireConstants.defaultIpAddress,
//         port: CampfireConstants.defaultPort.toString(),
//         useSSL: CampfireConstants.defaultUseSSL,
//       ),
//     ).thenAnswer((_) async => true);
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<NodeService>(
//                 create: (_) => nodeService,
//               ),
//               ChangeNotifierProvider<WalletsService>(
//                 create: (_) => walletsService,
//               ),
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//             ],
//             child: RestoreWalletFormView(
//               walletName: "My Firo Wallet",
//               firoNetworkType: FiroNetworkType.main,
//               clipboard: clipboard,
//             ),
//           ),
//         ),
//       ),
//     );
//
//     await tester.tap(find.byKey(Key("restoreWalletViewPasteButtonKey")));
//     await tester.pumpAndSettle();
//
//     await tester.fling(
//         find.byType(SingleChildScrollView), Offset(0, -500), 10000);
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pump(Duration(milliseconds: 100));
//     await tester.pump(Duration(milliseconds: 100));
//     await tester.pump(Duration(milliseconds: 100));
//
//     expect(find.text("Restoring wallet"), findsOneWidget);
//     expect(find.text("This may take a while."), findsOneWidget);
//     expect(find.text("Do not close or leave the app until this completes!"),
//         findsOneWidget);
//     expect(find.byType(CircularProgressIndicator), findsOneWidget);
//
//     await tester.pump(Duration(seconds: 1));
//
//     expect(find.text("Wallet Restored!"), findsOneWidget);
//     expect(find.text("Get ready to spend your Firo."), findsOneWidget);
//
//     await tester.pump(Duration(seconds: 2));
//
//     mockingjay.verifyNever(() => navigator.pop());
//     mockingjay
//         .verify(() => navigator.pushReplacementNamed("/mainview"))
//         .called(1);
//   });
//
//   testWidgets("restore fails and throws", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//     final manager = MockManager();
//     final walletsService = MockWalletsService();
//     final nodeService = MockNodeService();
//     final clipboard = FakeClipboard();
//
//     clipboard.setData(ClipboardData(text: TEST_MNEMONIC));
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) async => {});
//     mockingjay
//         .when(() => navigator.pushReplacementNamed("/mainview"))
//         .thenAnswer((_) async => {});
//
//     when(manager.hasWallet).thenAnswer((_) => true);
//     when(manager.exitCurrentWallet()).thenAnswer((_) async => {});
//     when(manager.recoverFromMnemonic(TEST_MNEMONIC))
//         .thenThrow(Exception("Restore failed due to reasons..."));
//
//     when(walletsService.refreshWallets()).thenAnswer((_) async => {});
//     when(walletsService.currentWalletName)
//         .thenAnswer((_) async => "My Firo Wallet");
//     when(walletsService.getWalletId("My Firo Wallet"))
//         .thenAnswer((_) async => "walletID");
//
//     when(nodeService.reInit()).thenAnswer((_) async => {});
//     when(
//       nodeService.createNode(
//         name: CampfireConstants.defaultNodeName,
//         ipAddress: CampfireConstants.defaultIpAddress,
//         port: CampfireConstants.defaultPort.toString(),
//         useSSL: CampfireConstants.defaultUseSSL,
//       ),
//     ).thenAnswer((_) async => true);
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<NodeService>(
//                 create: (_) => nodeService,
//               ),
//               ChangeNotifierProvider<WalletsService>(
//                 create: (_) => walletsService,
//               ),
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//             ],
//             child: RestoreWalletFormView(
//               walletName: "My Firo Wallet",
//               firoNetworkType: FiroNetworkType.main,
//               clipboard: clipboard,
//             ),
//           ),
//         ),
//       ),
//     );
//
//     await tester.tap(find.byKey(Key("restoreWalletViewPasteButtonKey")));
//     await tester.pumpAndSettle();
//
//     await tester.fling(
//         find.byType(SingleChildScrollView), Offset(0, -500), 10000);
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pump(Duration(milliseconds: 100));
//     await tester.pump(Duration(milliseconds: 100));
//     await tester.pump(Duration(milliseconds: 100));
//
//     expect(find.text("Restoring wallet"), findsOneWidget);
//     expect(find.text("This may take a while."), findsOneWidget);
//     expect(find.text("Do not close or leave the app until this completes!"),
//         findsOneWidget);
//     expect(find.byType(CircularProgressIndicator), findsOneWidget);
//
//     await tester.pump(Duration(seconds: 3));
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//     mockingjay.verifyNever(() => navigator.pushReplacementNamed("/mainview"));
//
//     expect(find.text("Restoring wallet failed."), findsOneWidget);
//     expect(find.textContaining("Restore failed due to reasons..."),
//         findsOneWidget);
//
//     await tester
//         .tap(find.byKey(Key("restoreWalletViewRestoreFailedOkButtonKey")));
//     await tester.pump(Duration(milliseconds: 100));
//
//     mockingjay.verify(() => navigator.pop()).called(5);
//   });
}
