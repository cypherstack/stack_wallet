// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
// import 'package:stackwallet/pages/settings_view/settings_subviews/wallet_settings_subviews/change_pin_view.dart';
import 'package:stackwallet/services/wallets_service.dart';
// import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
// import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
// import 'package:stackwallet/widgets/custom_pin_put/custom_pin_put.dart';
// import 'package:stackwallet/widgets/custom_pin_put/pin_keyboard.dart';
// import 'package:provider/provider.dart';
//
// import 'change_pin_view_screen_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<WalletsService>(returnNullOnMissingStub: true),
])
void main() {
//   testWidgets("ChangePinView builds correctly", (tester) async {
//     final walletsService = MockWalletsService();
//
//     when(walletsService.currentWalletName).thenAnswer((_) async => "my wallet");
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<WalletsService>(
//               create: (_) => walletsService,
//             ),
//           ],
//           child: ChangePinView(),
//         ),
//       ),
//     );
//
//     expect(find.text("..."), findsOneWidget);
//
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(SvgPicture), findsOneWidget);
//     expect(find.byType(CustomPinPut), findsOneWidget);
//     expect(find.byType(Text), findsNWidgets(16));
//     expect(find.text("my wallet"), findsOneWidget);
//     expect(find.text("New PIN"), findsOneWidget);
//     expect(find.text(""), findsNWidgets(5));
//     for (int i = 0; i < 10; i++) {
//       expect(find.text("$i"), findsOneWidget);
//     }
//
//     verify(walletsService.addListener(any)).called(1);
//     verify(walletsService.currentWalletName).called(2);
//
//     verifyNoMoreInteractions(walletsService);
//   });
//
//   testWidgets("tap back", (tester) async {
//     final walletsService = MockWalletsService();
//     final navigator = mockingjay.MockNavigator();
//
//     when(walletsService.currentWalletName).thenAnswer((_) async => "my wallet");
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) {});
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
//             child: ChangePinView(),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byType(AppBarIconButton));
//     await tester.pump(Duration(milliseconds: 100));
//
//     verify(walletsService.addListener(any)).called(1);
//     verify(walletsService.currentWalletName).called(2);
//
//     verifyNoMoreInteractions(walletsService);
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("enter a pin and confirm a different pin", (tester) async {
//     final walletsService = MockWalletsService();
//     final navigator = mockingjay.MockNavigator();
//
//     when(walletsService.currentWalletName).thenAnswer((_) async => "my wallet");
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) {});
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
//             child: ChangePinView(),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "0"));
//     await tester.pumpAndSettle();
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "1"));
//     await tester.pumpAndSettle();
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "2"));
//     await tester.pumpAndSettle();
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "3"));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(SvgPicture), findsOneWidget);
//     expect(find.byType(CustomPinPut), findsOneWidget);
//     expect(find.byType(Text), findsNWidgets(16));
//     expect(find.text("my wallet"), findsOneWidget);
//     expect(find.text("Confirm new PIN"), findsOneWidget);
//     expect(find.text(""), findsNWidgets(5));
//     for (int i = 0; i < 10; i++) {
//       expect(find.text("$i"), findsOneWidget);
//     }
//
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "0"));
//     await tester.pumpAndSettle();
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "1"));
//     await tester.pumpAndSettle();
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "2"));
//     await tester.pumpAndSettle();
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "4"));
//     await tester.pump(Duration(seconds: 1));
//
//     expect(find.text("PIN codes do not match. Try again."), findsOneWidget);
//
//     await tester.pumpAndSettle(Duration(seconds: 2));
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(SvgPicture), findsOneWidget);
//     expect(find.byType(CustomPinPut), findsOneWidget);
//     expect(find.byType(Text), findsNWidgets(16));
//     expect(find.text("my wallet"), findsOneWidget);
//     expect(find.text("PIN codes do not match. Try again."), findsNothing);
//     expect(find.text("New PIN"), findsOneWidget);
//     expect(find.text(""), findsNWidgets(5));
//     for (int i = 0; i < 10; i++) {
//       expect(find.text("$i"), findsOneWidget);
//     }
//
//     verify(walletsService.addListener(any)).called(1);
//     verify(walletsService.currentWalletName).called(2);
//
//     verifyNoMoreInteractions(walletsService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("enter a pin and confirm the same pin", (tester) async {
//     final walletsService = MockWalletsService();
//     final navigator = mockingjay.MockNavigator();
//     final secureStore = FakeSecureStorage();
//
//     await secureStore.write(key: "walletID_pin", value: "0000");
//
//     when(walletsService.currentWalletName).thenAnswer((_) async => "my wallet");
//     when(walletsService.getWalletId("my wallet"))
//         .thenAnswer((_) async => "walletID");
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) {});
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
//             child: ChangePinView(
//               secureStore: secureStore,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "0"));
//     await tester.pumpAndSettle();
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "1"));
//     await tester.pumpAndSettle();
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "2"));
//     await tester.pumpAndSettle();
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "3"));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(SvgPicture), findsOneWidget);
//     expect(find.byType(CustomPinPut), findsOneWidget);
//     expect(find.byType(Text), findsNWidgets(16));
//     expect(find.text("my wallet"), findsOneWidget);
//     expect(find.text("Confirm new PIN"), findsOneWidget);
//     expect(find.text(""), findsNWidgets(5));
//     for (int i = 0; i < 10; i++) {
//       expect(find.text("$i"), findsOneWidget);
//     }
//
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "0"));
//     await tester.pumpAndSettle();
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "1"));
//     await tester.pumpAndSettle();
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "2"));
//     await tester.pumpAndSettle();
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "3"));
//     await tester.pump(Duration(seconds: 1));
//
//     expect(find.text("New PIN is set up"), findsOneWidget);
//
//     await tester.pumpAndSettle(Duration(seconds: 2));
//
//     expect(find.text("New PIN is set up"), findsNothing);
//     expect(await secureStore.read(key: "walletID_pin"), "0123");
//
//     verify(walletsService.addListener(any)).called(1);
//     verify(walletsService.currentWalletName).called(3);
//     verify(walletsService.getWalletId("my wallet")).called(1);
//
//     verifyNoMoreInteractions(walletsService);
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
}
