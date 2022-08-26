// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
// import 'package:stackwallet/pages/main_view.dart';
// import 'package:stackwallet/pages/onboarding_view/verify_backup_key_view.dart';
import 'package:stackwallet/services/coins/manager.dart';
// import 'package:stackwallet/widgets/custom_buttons/gradient_button.dart';
// import 'package:provider/provider.dart';
//
// import 'verify_backup_key_view_screen_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<Manager>(returnNullOnMissingStub: true),
])
void main() {
//   testWidgets("onboarding view screen test", (tester) async {
//     final screen = VerifyBackupKeyView();
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: screen,
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
//     expect(find.text("Backup Key Verification"), findsOneWidget);
//     expect(
//         find.textContaining(RegExp(
//             r"Type the [1-2]{0,1}[0-9][n,r-t][d,h,t] word from your key\.")),
//         findsOneWidget);
//
//     expect(find.byType(TextField), findsOneWidget);
//     expect(find.text("Type here..."), findsOneWidget);
//
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.text("CONFIRM"), findsOneWidget);
//   });
//
//   testWidgets("back button test", (tester) async {
//     final screen = VerifyBackupKeyView();
//     final navigator = mockingjay.MockNavigator();
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) async => {});
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: screen,
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
//   testWidgets("confirm button empty field", (tester) async {
//     final screen = VerifyBackupKeyView();
//     final manager = MockManager();
//
//     when(manager.mnemonic).thenAnswer(
//       (_) async => [
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
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
//           child: screen,
//         ),
//       ),
//     );
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle(Duration(seconds: 2));
//
//     expect(find.byType(VerifyBackupKeyView), findsOneWidget);
//     expect(find.byType(MainView), findsNothing);
//   });
//
//   testWidgets("confirm button invalid word", (tester) async {
//     final screen = VerifyBackupKeyView();
//     final manager = MockManager();
//
//     when(manager.mnemonic).thenAnswer(
//       (_) async => [
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
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
//           child: screen,
//         ),
//       ),
//     );
//
//     await tester.enterText(find.byType(TextField), "notaword");
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle(Duration(seconds: 2));
//
//     expect(find.byType(VerifyBackupKeyView), findsOneWidget);
//     expect(find.byType(MainView), findsNothing);
//   });
//
//   testWidgets("confirm button matching word", (tester) async {
//     final screen = VerifyBackupKeyView();
//     final manager = MockManager();
//     final navigator = mockingjay.MockNavigator();
//
//     when(manager.mnemonic).thenAnswer(
//       (_) async => [
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//         "word",
//       ],
//     );
//
//     mockingjay
//         .when(() => navigator.pushReplacementNamed("/mainview"))
//         .thenAnswer((_) async => {});
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
//             child: screen,
//           ),
//         ),
//       ),
//     );
//
//     await tester.enterText(find.byType(TextField), "word");
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle(Duration(seconds: 2));
//
//     mockingjay
//         .verify(() => navigator.pushReplacementNamed("/mainview"))
//         .called(1);
//   });
}
