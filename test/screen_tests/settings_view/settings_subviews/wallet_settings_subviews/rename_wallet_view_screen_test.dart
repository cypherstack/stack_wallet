// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
// import 'package:stackwallet/notifications/campfire_alert.dart';
// import 'package:stackwallet/pages/settings_view/settings_subviews/wallet_settings_subviews/rename_wallet_view.dart';
import 'package:stackwallet/services/wallets_service.dart';
// import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
// import 'package:stackwallet/widgets/custom_buttons/gradient_button.dart';
// import 'package:provider/provider.dart';
//
// import 'rename_wallet_view_screen_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<WalletsService>(returnNullOnMissingStub: true),
])
void main() {
//   testWidgets("RenameWalletView builds correctly", (tester) async {
//     await tester.pumpWidget(
//       MaterialApp(
//         home: RenameWalletView(
//           oldWalletName: "my wallet",
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(Text), findsNWidgets(2));
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(SvgPicture), findsOneWidget);
//     expect(find.byType(TextField), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//
//     expect(
//         (find.byType(GradientButton).evaluate().first.widget as GradientButton)
//             .enabled,
//         false);
//
//     expect(find.text("Rename wallet"), findsOneWidget);
//     expect(find.text("my wallet"), findsOneWidget);
//     expect(find.text("SAVE"), findsOneWidget);
//   });
//
//   testWidgets("clear text field", (tester) async {
//     await tester.pumpWidget(
//       MaterialApp(
//         home: RenameWalletView(
//           oldWalletName: "my wallet",
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(Text), findsNWidgets(2));
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(TextField), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//
//     expect(
//         (find.byType(GradientButton).evaluate().first.widget as GradientButton)
//             .enabled,
//         false);
//
//     expect(find.text("Rename wallet"), findsOneWidget);
//     expect(find.text("my wallet"), findsOneWidget);
//     expect(find.text("SAVE"), findsOneWidget);
//
//     await tester.enterText(find.byType(TextField), "");
//     await tester.pumpAndSettle();
//
//     expect(find.text("my wallet"), findsNothing);
//     expect(
//         (find.byType(GradientButton).evaluate().first.widget as GradientButton)
//             .enabled,
//         false);
//   });
//
//   testWidgets("enter only spaces", (tester) async {
//     await tester.pumpWidget(
//       MaterialApp(
//         home: RenameWalletView(
//           oldWalletName: "my wallet",
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(Text), findsNWidgets(2));
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(TextField), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//
//     expect(
//         (find.byType(GradientButton).evaluate().first.widget as GradientButton)
//             .enabled,
//         false);
//
//     expect(find.text("Rename wallet"), findsOneWidget);
//     expect(find.text("my wallet"), findsOneWidget);
//     expect(find.text("SAVE"), findsOneWidget);
//
//     await tester.enterText(find.byType(TextField), "  ");
//     await tester.pumpAndSettle();
//
//     expect(find.text("my wallet"), findsNothing);
//     expect(find.text("  "), findsOneWidget);
//     expect(
//         (find.byType(GradientButton).evaluate().first.widget as GradientButton)
//             .enabled,
//         false);
//   });
//
//   testWidgets("enter new name", (tester) async {
//     await tester.pumpWidget(
//       MaterialApp(
//         home: RenameWalletView(
//           oldWalletName: "my wallet",
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(Text), findsNWidgets(2));
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(TextField), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//
//     expect(
//         (find.byType(GradientButton).evaluate().first.widget as GradientButton)
//             .enabled,
//         false);
//
//     expect(find.text("Rename wallet"), findsOneWidget);
//     expect(find.text("my wallet"), findsOneWidget);
//     expect(find.text("SAVE"), findsOneWidget);
//
//     await tester.enterText(find.byType(TextField), "some new name");
//     await tester.pumpAndSettle();
//
//     expect(find.text("my wallet"), findsNothing);
//     expect(find.text("some new name"), findsOneWidget);
//     expect(
//         (find.byType(GradientButton).evaluate().first.widget as GradientButton)
//             .enabled,
//         true);
//   });
//
//   testWidgets("edit then re enter same name", (tester) async {
//     await tester.pumpWidget(
//       MaterialApp(
//         home: RenameWalletView(
//           oldWalletName: "my wallet",
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(Text), findsNWidgets(2));
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(TextField), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//
//     expect(
//         (find.byType(GradientButton).evaluate().first.widget as GradientButton)
//             .enabled,
//         false);
//
//     expect(find.text("Rename wallet"), findsOneWidget);
//     expect(find.text("my wallet"), findsOneWidget);
//     expect(find.text("SAVE"), findsOneWidget);
//
//     await tester.enterText(find.byType(TextField), "some new name");
//     await tester.pumpAndSettle();
//
//     expect(find.text("my wallet"), findsNothing);
//     expect(find.text("some new name"), findsOneWidget);
//     expect(
//         (find.byType(GradientButton).evaluate().first.widget as GradientButton)
//             .enabled,
//         true);
//
//     await tester.enterText(find.byType(TextField), "my wallet");
//     await tester.pumpAndSettle();
//
//     expect(find.text("my wallet"), findsOneWidget);
//     expect(find.text("some new name"), findsNothing);
//     expect(
//         (find.byType(GradientButton).evaluate().first.widget as GradientButton)
//             .enabled,
//         true);
//   });
//
//   testWidgets("save succeeds", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//     final walletsService = MockWalletsService();
//
//     when(walletsService.renameWallet(toName: "some new name"))
//         .thenAnswer((_) async => true);
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
//             child: RenameWalletView(
//               oldWalletName: "my wallet",
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(Text), findsNWidgets(2));
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(TextField), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//
//     expect(
//         (find.byType(GradientButton).evaluate().first.widget as GradientButton)
//             .enabled,
//         false);
//
//     expect(find.text("Rename wallet"), findsOneWidget);
//     expect(find.text("my wallet"), findsOneWidget);
//     expect(find.text("SAVE"), findsOneWidget);
//
//     await tester.enterText(find.byType(TextField), "some new name");
//     await tester.pumpAndSettle();
//
//     expect(find.text("my wallet"), findsNothing);
//     expect(find.text("some new name"), findsOneWidget);
//     expect(
//         (find.byType(GradientButton).evaluate().first.widget as GradientButton)
//             .enabled,
//         true);
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle();
//
//     verify(walletsService.addListener(any)).called(1);
//     verify(walletsService.renameWallet(toName: "some new name")).called(1);
//
//     verifyNoMoreInteractions(walletsService);
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("save fails", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//     final walletsService = MockWalletsService();
//
//     when(walletsService.renameWallet(toName: "some new name"))
//         .thenAnswer((_) async => false);
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
//             child: RenameWalletView(
//               oldWalletName: "my wallet",
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(Text), findsNWidgets(2));
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(TextField), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//
//     expect(
//         (find.byType(GradientButton).evaluate().first.widget as GradientButton)
//             .enabled,
//         false);
//
//     expect(find.text("Rename wallet"), findsOneWidget);
//     expect(find.text("my wallet"), findsOneWidget);
//     expect(find.text("SAVE"), findsOneWidget);
//
//     await tester.enterText(find.byType(TextField), "some new name");
//     await tester.pumpAndSettle();
//
//     expect(find.text("my wallet"), findsNothing);
//     expect(find.text("some new name"), findsOneWidget);
//     expect(
//         (find.byType(GradientButton).evaluate().first.widget as GradientButton)
//             .enabled,
//         true);
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(CampfireAlert), findsOneWidget);
//     expect(find.text("A wallet with name \"some new name\" already exists!"),
//         findsOneWidget);
//
//     verify(walletsService.addListener(any)).called(1);
//     verify(walletsService.renameWallet(toName: "some new name")).called(1);
//
//     verifyNoMoreInteractions(walletsService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
}
