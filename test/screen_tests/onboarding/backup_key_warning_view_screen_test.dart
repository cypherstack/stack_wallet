// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
// import 'package:stackwallet/pages/onboarding_view/backup_key_warning_view.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/services/wallets_service.dart';
// import 'package:stackwallet/widgets/custom_buttons/gradient_button.dart';
// import 'package:provider/provider.dart';
//
// import 'backup_key_warning_view_screen_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<WalletsService>(returnNullOnMissingStub: true),
  MockSpec<Manager>(returnNullOnMissingStub: true),
])
void main() {
//   testWidgets("BackupKeyWarningView builds correctly", (tester) async {
//     await tester.pumpWidget(
//       MaterialApp(
//         home: BackupKeyWarningView(
//           walletName: "My Firo Wallet",
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
//     expect(find.byType(TextButton), findsOneWidget);
//     expect(find.text("SKIP"), findsOneWidget);
//
//     expect(find.text("Backup Key"), findsOneWidget);
//
//     expect(find.byType(SingleChildScrollView), findsOneWidget);
//     expect(find.text("""
// On the next screen you will see 24 words that make up your backup key.
//
// Please write it down. Keep it safe and never share it with anyone. Your backup key is the only way you can access your funds if you forget PIN, lose your phone, etc.
//
// Campfire Wallet does not keep nor is able to restore your backup key. Only you have access to your wallet.
// """), findsOneWidget);
//
//     expect(find.byType(Checkbox), findsOneWidget);
//     expect(
//         find.text(
//             "I understand that if I lose my backup key, I will not be able to access my funds."),
//         findsOneWidget);
//
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.text("VIEW BACKUP KEY"), findsOneWidget);
//   });
//
//   testWidgets("back button test A", (tester) async {
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
//             child: BackupKeyWarningView(
//               walletName: "My Firo Wallet",
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
//   testWidgets("back button test B", (tester) async {
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
//             child: BackupKeyWarningView(
//               walletName: "My Firo Wallet",
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
//   testWidgets("skip button test", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//
//     mockingjay
//         .when(() => navigator.pushReplacementNamed("/mainview"))
//         .thenAnswer((_) async => {});
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: BackupKeyWarningView(
//             walletName: "My Firo Wallet",
//           ),
//         ),
//       ),
//     );
//
//     await tester.tap(find.byType(TextButton));
//     await tester.pumpAndSettle();
//
//     mockingjay
//         .verify(() => navigator.pushReplacementNamed("/mainview"))
//         .called(1);
//   });
//
//   testWidgets("tap view backup key when checkbox is not checked",
//       (tester) async {
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
//           child: BackupKeyWarningView(
//             walletName: "My Firo Wallet",
//           ),
//         ),
//       ),
//     );
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle();
//
//     mockingjay.verifyNever(() => navigator.push(mockingjay.any()));
//   });
//
//   testWidgets("tap view backup key when checkbox is checked", (tester) async {
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
//           child: BackupKeyWarningView(
//             walletName: "My Firo Wallet",
//           ),
//         ),
//       ),
//     );
//
//     await tester.tap(find.byType(Checkbox));
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle();
//
//     mockingjay.verify(() => navigator.push(mockingjay.any())).called(1);
//   });
}
