// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
// import 'package:stackwallet/pages/onboarding_view/helpers/create_wallet_type.dart';
// import 'package:stackwallet/pages/onboarding_view/name_your_wallet_view.dart';
import 'package:stackwallet/services/wallets_service.dart';
// import 'package:stackwallet/widgets/custom_buttons/gradient_button.dart';
// import 'package:provider/provider.dart';
//
// import 'name_your_wallet_view_screen_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<WalletsService>(returnNullOnMissingStub: true),
])
void main() {
//   testWidgets("NameYourWalletView builds correctly with testnet option",
//       (tester) async {
//     await tester.pumpWidget(
//       MaterialApp(
//         home: NameYourWalletView(
//           type: CreateWalletType.NEW,
//           allowTestNet: true,
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
//     expect(find.text("Name your wallet"), findsOneWidget);
//     expect(find.text("Enter a label for your wallet"), findsOneWidget);
//     expect(find.text("(e.g. My Hot Wallet)"), findsOneWidget);
//
//     expect(find.byType(TextField), findsOneWidget);
//     expect(find.text("Enter wallet name"), findsOneWidget);
//
//     expect(find.text("Test net"), findsOneWidget);
//     expect(find.byType(Checkbox), findsOneWidget);
//
//     expect(find.text("NEXT"), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//   });
//
//   testWidgets("NameYourWalletView builds correctly without testnet option",
//       (tester) async {
//     await tester.pumpWidget(
//       MaterialApp(
//         home: NameYourWalletView(
//           type: CreateWalletType.NEW,
//           allowTestNet: false,
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
//     expect(find.text("Name your wallet"), findsOneWidget);
//     expect(find.text("Enter a label for your wallet"), findsOneWidget);
//     expect(find.text("(e.g. My Hot Wallet)"), findsOneWidget);
//
//     expect(find.byType(TextField), findsOneWidget);
//     expect(find.text("Enter wallet name"), findsOneWidget);
//
//     expect(find.text("Test net"), findsNothing);
//     expect(find.byType(Checkbox), findsNothing);
//
//     expect(find.text("NEXT"), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
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
//           child: NameYourWalletView(
//             type: CreateWalletType.RESTORE,
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
//   testWidgets("next pressed with empty field", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//
//     mockingjay
//         .when(() => navigator.push(mockingjay.any()))
//         .thenAnswer((_) async => {});
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: NameYourWalletView(
//             type: CreateWalletType.NEW,
//             allowTestNet: false,
//           ),
//         ),
//       ),
//     );
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle(Duration(seconds: 2));
//
//     mockingjay.verifyNever(() => navigator.push(mockingjay.any()));
//     expect(find.byType(NameYourWalletView), findsOneWidget);
//   });
//
//   testWidgets("next pressed with unique wallet name in field", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//     final walletsService = MockWalletsService();
//     final name = "My Firo Wallet";
//
//     when(walletsService.checkForDuplicate(name)).thenAnswer((_) async => false);
//
//     mockingjay
//         .when(() => navigator.push(mockingjay.any()))
//         .thenAnswer((_) async => {});
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
//             ],
//             child: NameYourWalletView(
//               type: CreateWalletType.RESTORE,
//               allowTestNet: true,
//             ),
//           ),
//         ),
//       ),
//     );
//
//     await tester.tap(find.byType(Checkbox));
//     await tester.pumpAndSettle();
//
//     await tester.enterText(find.byType(TextField), name);
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle(Duration(seconds: 2));
//
//     mockingjay.verify(() => navigator.push(mockingjay.any())).called(1);
//   });
//
//   testWidgets("next pressed with existing wallet name in field",
//       (tester) async {
//     final navigator = mockingjay.MockNavigator();
//     final walletsService = MockWalletsService();
//     final name = "My Firo Wallet";
//
//     when(walletsService.checkForDuplicate(name)).thenAnswer((_) async => true);
//
//     mockingjay
//         .when(() => navigator.push(mockingjay.any()))
//         .thenAnswer((_) async => {});
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
//             ],
//             child: NameYourWalletView(
//               type: CreateWalletType.NEW,
//               allowTestNet: false,
//             ),
//           ),
//         ),
//       ),
//     );
//
//     await tester.enterText(find.byType(TextField), name);
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle(Duration(seconds: 2));
//
//     mockingjay.verifyNever(() => navigator.push(mockingjay.any()));
//     expect(find.byType(NameYourWalletView), findsOneWidget);
//   });
}
