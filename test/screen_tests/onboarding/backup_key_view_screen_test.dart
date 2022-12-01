// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
// import 'package:epicmobile/notifications/modal_popup_dialog.dart';
// import 'package:epicmobile/pages/onboarding_view/backup_key_view.dart';
import 'package:epicmobile/services/coins/manager.dart';
// import 'package:epicmobile/widgets/custom_buttons/gradient_button.dart';
// import 'package:pretty_qr_code/pretty_qr_code.dart';
// import 'package:provider/provider.dart';
//
// import 'backup_key_view_screen_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<Manager>(returnNullOnMissingStub: true),
])
void main() {
//   testWidgets("BackupKeyView builds correctly", (tester) async {
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
//           child: BackupKeyView(),
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
//     expect(find.text("Please write down your backup key."), findsOneWidget);
//
//     expect(find.byType(CircularProgressIndicator), findsOneWidget);
//
//     await tester.pumpAndSettle();
//
//     expect(find.text("some"), findsNWidgets(8));
//     expect(find.text("mnemonic"), findsNWidgets(8));
//     expect(find.text("words"), findsNWidgets(8));
//
//     for (int i = 1; i <= 24; i++) {
//       expect(find.text("$i"), findsOneWidget);
//     }
//
//     expect(find.byType(SvgPicture), findsNWidgets(3));
//
//     expect(find.byKey(Key("backupKeyQrCodeButtonKey")), findsOneWidget);
//     expect(find.text("QR CODE"), findsOneWidget);
//
//     expect(find.byKey(Key("backupKeyViewCopyButtonKey")), findsOneWidget);
//     expect(find.text("COPY"), findsOneWidget);
//
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.text("VERIFY"), findsOneWidget);
//   });
//
//   testWidgets("back button test", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//     final manager = MockManager();
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) async => {});
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
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//             ],
//             child: BackupKeyView(),
//           ),
//         ),
//       ),
//     );
//
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byKey(Key("onboardingAppBarBackButton")));
//     await tester.pumpAndSettle();
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//   });
//
//   testWidgets("skip button test", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//     final manager = MockManager();
//
//     mockingjay
//         .when(() => navigator.pushReplacementNamed("/mainview"))
//         .thenAnswer((_) async => {});
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
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//             ],
//             child: BackupKeyView(),
//           ),
//         ),
//       ),
//     );
//
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byType(TextButton));
//     await tester.pumpAndSettle();
//
//     mockingjay
//         .verify(() => navigator.pushReplacementNamed("/mainview"))
//         .called(1);
//   });
//
//   testWidgets("qrcode button test", (tester) async {
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
//           child: BackupKeyView(),
//         ),
//       ),
//     );
//
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byKey(Key("backupKeyQrCodeButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.text("Backup Key QR Code"), findsOneWidget);
//
//     expect(find.byType(PrettyQr), findsOneWidget);
//
//     await tester.tap(find.byKey(Key("backUpKeyViewQrCodeCancelButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(ModalPopupDialog), findsNothing);
//   });
//
//   testWidgets("copy button test", (tester) async {
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
//           child: BackupKeyView(),
//         ),
//       ),
//     );
//
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byKey(Key("backupKeyViewCopyButtonKey")));
//     await tester.pump();
//     expect(find.text("Copied to clipboard"), findsOneWidget);
//     await tester.pumpAndSettle(Duration(seconds: 2));
//
//     expect(find.byType(BackupKeyView), findsOneWidget);
//   });
//
//   testWidgets("verify button test", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//     final manager = MockManager();
//
//     mockingjay
//         .when(() => navigator.push(mockingjay.any()))
//         .thenAnswer((_) async => {});
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
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//             ],
//             child: BackupKeyView(),
//           ),
//         ),
//       ),
//     );
//
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle();
//
//     mockingjay.verify(() => navigator.push(mockingjay.any())).called(1);
//   });
}
