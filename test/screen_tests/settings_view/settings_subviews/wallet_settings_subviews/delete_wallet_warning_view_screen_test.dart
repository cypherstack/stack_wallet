// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockingjay/mockingjay.dart' as mockingjay;
// import 'package:stackwallet/pages/settings_view/settings_subviews/wallet_settings_subviews/delete_wallet_warning_view.dart';
// import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
// import 'package:stackwallet/widgets/custom_buttons/gradient_button.dart';
// import 'package:stackwallet/widgets/custom_buttons/simple_button.dart';

void main() {
//   testWidgets("DeleteWalletWarningView builds correctly", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: DeleteWalletWarningView(),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(SvgPicture), findsOneWidget);
//     expect(find.byType(Text), findsNWidgets(8));
//     expect(find.byType(SimpleButton), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//
//     expect(find.text(""), findsOneWidget);
//     expect(find.text("Warning!"), findsOneWidget);
//     expect(find.text("You are going to permanently delete you wallet."),
//         findsOneWidget);
//     expect(
//         find.text(
//             "If you delete your wallet, the only way you can have access to your funds is by using your backup key."),
//         findsOneWidget);
//     expect(
//         find.text(
//             "Campfire Wallet does not keep nor is able to restore your backup key or your wallet."),
//         findsOneWidget);
//     expect(find.text("PLEASE SAVE YOUR BACKUP KEY."), findsOneWidget);
//     expect(find.text("CANCEL AND GO BACK"), findsOneWidget);
//     expect(find.text("VIEW BACKUP KEY"), findsOneWidget);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap back", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) {});
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: DeleteWalletWarningView(),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byType(AppBarIconButton));
//     await tester.pump(Duration(milliseconds: 100));
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap cancel and go back", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) {});
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: DeleteWalletWarningView(),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byType(SimpleButton));
//     await tester.pump(Duration(milliseconds: 100));
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap view backup key", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//
//     mockingjay
//         .when(() => navigator.push(mockingjay.any(
//             that: mockingjay.isRoute(
//                 whereName: equals("/settings/walletdeletemnemonicview")))))
//         .thenAnswer((_) async {});
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: DeleteWalletWarningView(),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pump(Duration(milliseconds: 100));
//
//     mockingjay
//         .verify(() => navigator.push(mockingjay.any(
//             that: mockingjay.isRoute(
//                 whereName: equals("/settings/walletdeletemnemonicview")))))
//         .called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
}
