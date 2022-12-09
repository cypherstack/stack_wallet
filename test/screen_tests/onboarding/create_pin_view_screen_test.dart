// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
// import 'package:epicmobile/pages/onboarding_view/create_pin_view.dart';
// import 'package:epicmobile/pages/onboarding_view/helpers/create_wallet_type.dart';
import 'package:epicmobile/services/coins/manager.dart';
import 'package:epicmobile/services/node_service.dart';
import 'package:epicmobile/services/wallets_service.dart';
// import 'package:epicmobile/utilities/flutter_secure_storage_interface.dart';
// import 'package:epicmobile/utilities/misc_global_constants.dart';
// import 'package:epicmobile/widgets/custom_buttons/gradient_button.dart';
// import 'package:epicmobile/widgets/custom_pin_put/custom_pin_put.dart';
// import 'package:epicmobile/widgets/custom_pin_put/pin_keyboard.dart';
// import 'package:provider/provider.dart';
//
// import 'create_pin_view_screen_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<WalletsService>(returnNullOnMissingStub: true),
  MockSpec<NodeService>(returnNullOnMissingStub: true),
  MockSpec<Manager>(returnNullOnMissingStub: true),
])
void main() {
//   testWidgets("CreatePinView builds correctly", (tester) async {
//     await tester.pumpWidget(
//       MaterialApp(
//         home: CreatePinView(
//           type: CreateWalletType.NEW,
//           walletName: "My Firo Wallet",
//           useTestNet: false,
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
//     expect(find.text("Create a PIN"), findsOneWidget);
//
//     expect(find.byType(CustomPinPut), findsOneWidget);
//   });
//
//   testWidgets("back button test", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) async => {});
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: CreatePinView(
//             type: CreateWalletType.NEW,
//             walletName: "My Firo Wallet",
//             useTestNet: false,
//           ),
//         ),
//       ),
//     );
//
//     await tester.tap(find.byKey(Key("onboardingAppBarBackButton")));
//     await tester.pumpAndSettle();
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//   });
//
//   testWidgets("Entering unmatched PINs", (tester) async {
//     await tester.pumpWidget(
//       MaterialApp(
//         home: CreatePinView(
//           type: CreateWalletType.NEW,
//           walletName: "My Firo Wallet",
//           useTestNet: false,
//         ),
//       ),
//     );
//
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "1"));
//     await tester.pumpAndSettle(Duration(milliseconds: 100));
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "2"));
//     await tester.pumpAndSettle(Duration(milliseconds: 100));
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "3"));
//     await tester.pumpAndSettle(Duration(milliseconds: 100));
//     await tester
//         .tap(find.byWidgetPredicate((widget) => widget is BackspaceKey));
//     await tester.pumpAndSettle(Duration(milliseconds: 100));
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "6"));
//     await tester.pumpAndSettle(Duration(milliseconds: 100));
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "4"));
//     await tester.pumpAndSettle(Duration(seconds: 1));
//
//     expect(find.text("Confirm PIN"), findsOneWidget);
//
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "7"));
//     await tester.pumpAndSettle(Duration(milliseconds: 100));
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "9"));
//     await tester.pumpAndSettle(Duration(milliseconds: 100));
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "8"));
//     await tester.pumpAndSettle(Duration(milliseconds: 100));
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "5"));
//     await tester.pumpAndSettle(Duration(seconds: 2));
//
//     expect(find.text("Create a PIN"), findsOneWidget);
//   });
//
//   testWidgets("Entering matched PINs on a new wallet", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//     final walletsService = MockWalletsService();
//     final manager = MockManager();
//     final nodeService = MockNodeService();
//
//     final store = FakeSecureStorage();
//
//     mockingjay
//         .when(() => navigator.push(mockingjay.any()))
//         .thenAnswer((_) async => {});
//
//     when(walletsService.addNewWalletName("My Firo Wallet", "main"))
//         .thenAnswer((_) async => true);
//     when(walletsService.getWalletId("My Firo Wallet"))
//         .thenAnswer((_) async => "walletID");
//
//     when(nodeService.reInit()).thenAnswer((_) => {});
//     when(
//       nodeService.createNode(
//         name: CampfireConstants.defaultNodeName,
//         ipAddress: CampfireConstants.defaultIpAddress,
//         port: CampfireConstants.defaultPort.toString(),
//         useSSL: CampfireConstants.defaultUseSSL,
//       ),
//     ).thenAnswer((_) async => true);
//
//     when(manager.initializeWallet()).thenAnswer((_) async => true);
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: MultiProvider(
//             // home: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<WalletsService>(
//                 create: (_) => walletsService,
//               ),
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//               ChangeNotifierProvider<NodeService>(
//                 create: (_) => nodeService,
//               ),
//             ],
//             child: CreatePinView(
//               type: CreateWalletType.NEW,
//               walletName: "My Firo Wallet",
//               useTestNet: false,
//               secureStore: store,
//             ),
//           ),
//         ),
//       ),
//     );
//
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "1"));
//     await tester.pumpAndSettle(Duration(milliseconds: 100));
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "2"));
//     await tester.pumpAndSettle(Duration(milliseconds: 100));
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "3"));
//     await tester.pumpAndSettle(Duration(milliseconds: 100));
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "4"));
//     await tester.pumpAndSettle(Duration(seconds: 1));
//
//     expect(find.text("Confirm PIN"), findsOneWidget);
//
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "1"));
//     await tester.pumpAndSettle(Duration(milliseconds: 100));
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "2"));
//     await tester.pumpAndSettle(Duration(milliseconds: 100));
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "3"));
//     await tester.pumpAndSettle(Duration(milliseconds: 100));
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "4"));
//     await tester.pump(Duration(seconds: 2));
//
//     expect(find.byType(CircularProgressIndicator), findsOneWidget);
//
//     await tester.pump(Duration(seconds: 20));
//
//     mockingjay.verify(() => navigator.push(mockingjay.any())).called(1);
//   });
//
//   testWidgets("Wallet init fails on entering matched PINs", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//     final walletsService = MockWalletsService();
//     final manager = MockManager();
//     final nodeService = MockNodeService();
//
//     final store = FakeSecureStorage();
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) async => {});
//
//     when(walletsService.addNewWalletName("My Firo Wallet", "main"))
//         .thenAnswer((_) async => true);
//     when(walletsService.getWalletId("My Firo Wallet"))
//         .thenAnswer((_) async => "walletID");
//
//     when(nodeService.reInit()).thenAnswer((_) => {});
//     when(
//       nodeService.createNode(
//         name: CampfireConstants.defaultNodeNameTestNet,
//         ipAddress: CampfireConstants.defaultIpAddressTestNet,
//         port: CampfireConstants.defaultPortTestNet.toString(),
//         useSSL: CampfireConstants.defaultUseSSLTestNet,
//       ),
//     ).thenAnswer((_) async => true);
//
//     when(manager.initializeWallet()).thenAnswer((_) async => false);
//     when(manager.exitCurrentWallet()).thenAnswer((_) async => {});
//     when(walletsService.deleteWallet("My Firo Wallet"))
//         .thenAnswer((_) async => 0);
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: MultiProvider(
//             // home: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<WalletsService>(
//                 create: (_) => walletsService,
//               ),
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//               ChangeNotifierProvider<NodeService>(
//                 create: (_) => nodeService,
//               ),
//             ],
//             child: CreatePinView(
//               type: CreateWalletType.NEW,
//               walletName: "My Firo Wallet",
//               useTestNet: true,
//               secureStore: store,
//             ),
//           ),
//         ),
//       ),
//     );
//
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "1"));
//     await tester.pumpAndSettle(Duration(milliseconds: 100));
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "2"));
//     await tester.pumpAndSettle(Duration(milliseconds: 100));
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "3"));
//     await tester.pumpAndSettle(Duration(milliseconds: 100));
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "4"));
//     await tester.pumpAndSettle(Duration(seconds: 1));
//
//     expect(find.text("Confirm PIN"), findsOneWidget);
//
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "1"));
//     await tester.pumpAndSettle(Duration(milliseconds: 100));
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "2"));
//     await tester.pumpAndSettle(Duration(milliseconds: 100));
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "3"));
//     await tester.pumpAndSettle(Duration(milliseconds: 100));
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "4"));
//     await tester.pump(Duration(seconds: 2));
//
//     expect(
//         find.text(
//             "Failed to connect to network. Check your internet connection."),
//         findsOneWidget);
//     expect(find.text("OK"), findsOneWidget);
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pump(Duration(seconds: 1));
//
//     mockingjay.verify(() => navigator.pop()).called(4);
//   });
//
//   testWidgets("Entering matched PINs on a restore", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//     final walletsService = MockWalletsService();
//
//     final store = FakeSecureStorage();
//
//     mockingjay
//         .when(() => navigator.push(mockingjay.any()))
//         .thenAnswer((_) async => {});
//
//     when(walletsService.addNewWalletName("My Firo Wallet", "main"))
//         .thenAnswer((_) async => true);
//     when(walletsService.getWalletId("My Firo Wallet"))
//         .thenAnswer((_) async => "walletID");
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: MultiProvider(
//             // home: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<WalletsService>(
//                 create: (_) => walletsService,
//               ),
//             ],
//             child: CreatePinView(
//               type: CreateWalletType.RESTORE,
//               walletName: "My Firo Wallet",
//               useTestNet: false,
//               secureStore: store,
//             ),
//           ),
//         ),
//       ),
//     );
//
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "1"));
//     await tester.pumpAndSettle(Duration(milliseconds: 100));
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "2"));
//     await tester.pumpAndSettle(Duration(milliseconds: 100));
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "3"));
//     await tester.pumpAndSettle(Duration(milliseconds: 100));
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "4"));
//     await tester.pumpAndSettle(Duration(seconds: 1));
//
//     expect(find.text("Confirm PIN"), findsOneWidget);
//
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "1"));
//     await tester.pumpAndSettle(Duration(milliseconds: 100));
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "2"));
//     await tester.pumpAndSettle(Duration(milliseconds: 100));
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "3"));
//     await tester.pumpAndSettle(Duration(milliseconds: 100));
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "4"));
//     await tester.pumpAndSettle(Duration(seconds: 6));
//
//     mockingjay.verify(() => navigator.push(mockingjay.any())).called(1);
//   });
}
