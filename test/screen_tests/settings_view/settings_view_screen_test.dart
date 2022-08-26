// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
// import 'package:stackwallet/notifications/modal_popup_dialog.dart';
// import 'package:stackwallet/pages/settings_view/settings_view.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/services/wallets_service.dart';
// import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
// import 'package:stackwallet/widgets/custom_buttons/gradient_button.dart';
// import 'package:stackwallet/widgets/custom_buttons/simple_button.dart';
// import 'package:provider/provider.dart';
//
// import 'settings_view_screen_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<WalletsService>(returnNullOnMissingStub: true),
  MockSpec<Manager>(returnNullOnMissingStub: true),
])
void main() {
//   testWidgets("SettingsView builds correctly", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: SettingsView(),
//         ),
//       ),
//     );
//
//     expect(find.byType(AppBarIconButton), findsNWidgets(2));
//     expect(find.byType(SvgPicture), findsNWidgets(7));
//     expect(find.byType(SingleChildScrollView), findsOneWidget);
//     expect(
//         find.byWidgetPredicate((widget) =>
//             widget is Container && widget.color == Color(0xFFF0F3FA)),
//         findsNWidgets(4));
//
//     expect(find.text("Settings"), findsOneWidget);
//     expect(find.text("Address Book"), findsOneWidget);
//     expect(find.text("Network"), findsOneWidget);
//     expect(find.text("Wallet Backup"), findsOneWidget);
//     expect(find.text("Wallet Settings"), findsOneWidget);
//     expect(find.text("Currency"), findsOneWidget);
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
//           child: SettingsView(),
//         ),
//       ),
//     );
//
//     expect(find.byType(AppBarIconButton), findsNWidgets(2));
//     expect(find.byType(SvgPicture), findsNWidgets(7));
//     expect(find.byType(SingleChildScrollView), findsOneWidget);
//     expect(
//         find.byWidgetPredicate((widget) =>
//             widget is Container && widget.color == Color(0xFFF0F3FA)),
//         findsNWidgets(4));
//
//     expect(find.text("Settings"), findsOneWidget);
//     expect(find.text("Address Book"), findsOneWidget);
//     expect(find.text("Network"), findsOneWidget);
//     expect(find.text("Wallet Backup"), findsOneWidget);
//     expect(find.text("Wallet Settings"), findsOneWidget);
//     expect(find.text("Currency"), findsOneWidget);
//
//     await tester.tap(find.byKey(Key("settingsAppBarBackButton")));
//     await tester.pump(Duration(milliseconds: 100));
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap log out and confirm log out", (tester) async {
//     final manager = MockManager();
//     final walletsService = MockWalletsService();
//     final navigator = mockingjay.MockNavigator();
//
//     when(manager.exitCurrentWallet()).thenAnswer((_) async {});
//     when(walletsService.setCurrentWalletName("")).thenAnswer((_) async {});
//     when(walletsService.refreshWallets()).thenAnswer((_) async {});
//     when(walletsService.currentWalletName)
//         .thenAnswer((_) async => "My Firo Wallet");
//
//     mockingjay
//         .when(() =>
//             navigator.pushAndRemoveUntil(mockingjay.any(), mockingjay.any()))
//         .thenAnswer((_) async {});
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
//             child: SettingsView(),
//           ),
//         ),
//       ),
//     );
//
//     await tester.tap(find.byKey(Key("settingsLogoutAppBarButton")));
//     await tester.pump(Duration(milliseconds: 100));
//
//     expect(find.byType(ModalPopupDialog), findsOneWidget);
//     expect(find.text("Do you want to log out from My Firo Wallet Wallet?"),
//         findsOneWidget);
//     expect(find.text("CANCEL"), findsOneWidget);
//     expect(find.text("LOG OUT"), findsOneWidget);
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle();
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.exitCurrentWallet()).called(1);
//
//     verify(walletsService.addListener(any)).called(1);
//     verify(walletsService.setCurrentWalletName("")).called(1);
//     verify(walletsService.refreshWallets()).called(1);
//     verify(walletsService.currentWalletName).called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(walletsService);
//
//     mockingjay
//         .verify(() =>
//             navigator.pushAndRemoveUntil(mockingjay.any(), mockingjay.any()))
//         .called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap log out and cancel log out", (tester) async {
//     final manager = MockManager();
//     final walletsService = MockWalletsService();
//     final navigator = mockingjay.MockNavigator();
//
//     when(walletsService.currentWalletName)
//         .thenAnswer((_) async => "My Firo Wallet");
//
//     mockingjay
//         .when(() =>
//             navigator.pushAndRemoveUntil(mockingjay.any(), mockingjay.any()))
//         .thenAnswer((_) async {});
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
//             child: SettingsView(),
//           ),
//         ),
//       ),
//     );
//
//     await tester.tap(find.byKey(Key("settingsLogoutAppBarButton")));
//     await tester.pump(Duration(milliseconds: 100));
//
//     expect(find.byType(ModalPopupDialog), findsOneWidget);
//     expect(find.text("Do you want to log out from My Firo Wallet Wallet?"),
//         findsOneWidget);
//     expect(find.text("CANCEL"), findsOneWidget);
//     expect(find.text("LOG OUT"), findsOneWidget);
//
//     await tester.tap(find.byType(SimpleButton));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(ModalPopupDialog), findsNothing);
//
//     verify(walletsService.addListener(any)).called(1);
//     verify(walletsService.currentWalletName).called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(walletsService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap address book", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//
//     mockingjay
//         .when(() => navigator.push(mockingjay.any()))
//         .thenAnswer((_) async {});
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: SettingsView(),
//         ),
//       ),
//     );
//
//     expect(find.byType(AppBarIconButton), findsNWidgets(2));
//     expect(find.byType(SvgPicture), findsNWidgets(7));
//     expect(find.byType(SingleChildScrollView), findsOneWidget);
//     expect(
//         find.byWidgetPredicate((widget) =>
//             widget is Container && widget.color == Color(0xFFF0F3FA)),
//         findsNWidgets(4));
//
//     expect(find.text("Settings"), findsOneWidget);
//     expect(find.text("Address Book"), findsOneWidget);
//     expect(find.text("Network"), findsOneWidget);
//     expect(find.text("Wallet Backup"), findsOneWidget);
//     expect(find.text("Wallet Settings"), findsOneWidget);
//     expect(find.text("Currency"), findsOneWidget);
//
//     await tester.tap(find.byKey(Key("settingsOptionAddressBook")));
//     await tester.pump(Duration(milliseconds: 100));
//
//     mockingjay
//         .verify(() => navigator.push(mockingjay.any(
//             that: mockingjay.isRoute(
//                 whereName: equals("/settings/addressbook")))))
//         .called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap network", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//
//     mockingjay
//         .when(() => navigator.push(mockingjay.any()))
//         .thenAnswer((_) async {});
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: SettingsView(),
//         ),
//       ),
//     );
//
//     expect(find.byType(AppBarIconButton), findsNWidgets(2));
//     expect(find.byType(SvgPicture), findsNWidgets(7));
//     expect(find.byType(SingleChildScrollView), findsOneWidget);
//     expect(
//         find.byWidgetPredicate((widget) =>
//             widget is Container && widget.color == Color(0xFFF0F3FA)),
//         findsNWidgets(4));
//
//     expect(find.text("Settings"), findsOneWidget);
//     expect(find.text("Address Book"), findsOneWidget);
//     expect(find.text("Network"), findsOneWidget);
//     expect(find.text("Wallet Backup"), findsOneWidget);
//     expect(find.text("Wallet Settings"), findsOneWidget);
//     expect(find.text("Currency"), findsOneWidget);
//
//     await tester.tap(find.byKey(Key("settingsOptionNetwork")));
//     await tester.pump(Duration(milliseconds: 100));
//
//     mockingjay
//         .verify(() => navigator.push(mockingjay.any(
//             that: mockingjay.isRoute(whereName: equals("/settings/network")))))
//         .called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap wallet backup", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//
//     mockingjay
//         .when(() => navigator.push(mockingjay.any()))
//         .thenAnswer((_) async {});
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: SettingsView(),
//         ),
//       ),
//     );
//
//     expect(find.byType(AppBarIconButton), findsNWidgets(2));
//     expect(find.byType(SvgPicture), findsNWidgets(7));
//     expect(find.byType(SingleChildScrollView), findsOneWidget);
//     expect(
//         find.byWidgetPredicate((widget) =>
//             widget is Container && widget.color == Color(0xFFF0F3FA)),
//         findsNWidgets(4));
//
//     expect(find.text("Settings"), findsOneWidget);
//     expect(find.text("Address Book"), findsOneWidget);
//     expect(find.text("Network"), findsOneWidget);
//     expect(find.text("Wallet Backup"), findsOneWidget);
//     expect(find.text("Wallet Settings"), findsOneWidget);
//     expect(find.text("Currency"), findsOneWidget);
//
//     await tester.tap(find.byKey(Key("settingsOptionWalletBackup")));
//     await tester.pump(Duration(milliseconds: 100));
//
//     mockingjay
//         .verify(() => navigator.push(mockingjay.any(
//             that: mockingjay.isRoute(
//                 whereName: equals("/settings/walletbackupoption")))))
//         .called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap wallet settings", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//     final manager = MockManager();
//
//     mockingjay
//         .when(() => navigator.push(mockingjay.any()))
//         .thenAnswer((_) async {});
//
//     when(manager.useBiometrics).thenAnswer((_) async => true);
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
//             child: SettingsView(),
//           ),
//         ),
//       ),
//     );
//
//     expect(find.byType(AppBarIconButton), findsNWidgets(2));
//     expect(find.byType(SvgPicture), findsNWidgets(7));
//     expect(find.byType(SingleChildScrollView), findsOneWidget);
//     expect(
//         find.byWidgetPredicate((widget) =>
//             widget is Container && widget.color == Color(0xFFF0F3FA)),
//         findsNWidgets(4));
//
//     expect(find.text("Settings"), findsOneWidget);
//     expect(find.text("Address Book"), findsOneWidget);
//     expect(find.text("Network"), findsOneWidget);
//     expect(find.text("Wallet Backup"), findsOneWidget);
//     expect(find.text("Wallet Settings"), findsOneWidget);
//     expect(find.text("Currency"), findsOneWidget);
//
//     await tester.tap(find.byKey(Key("settingsOptionWalletSettings")));
//     await tester.pump(Duration(milliseconds: 100));
//
//     mockingjay
//         .verify(() => navigator.push(mockingjay.any(
//             that: mockingjay.isRoute(
//                 whereName: equals("/settings/walletsettingsoption")))))
//         .called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.useBiometrics).called(1);
//     verifyNoMoreInteractions(manager);
//   });
//
//   testWidgets("tap currency", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//
//     mockingjay
//         .when(() => navigator.push(mockingjay.any()))
//         .thenAnswer((_) async {});
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: SettingsView(),
//         ),
//       ),
//     );
//
//     expect(find.byType(AppBarIconButton), findsNWidgets(2));
//     expect(find.byType(SvgPicture), findsNWidgets(7));
//     expect(find.byType(SingleChildScrollView), findsOneWidget);
//     expect(
//         find.byWidgetPredicate((widget) =>
//             widget is Container && widget.color == Color(0xFFF0F3FA)),
//         findsNWidgets(4));
//
//     expect(find.text("Settings"), findsOneWidget);
//     expect(find.text("Address Book"), findsOneWidget);
//     expect(find.text("Network"), findsOneWidget);
//     expect(find.text("Wallet Backup"), findsOneWidget);
//     expect(find.text("Wallet Settings"), findsOneWidget);
//     expect(find.text("Currency"), findsOneWidget);
//
//     await tester.tap(find.byKey(Key("settingsOptionCurrency")));
//     await tester.pump(Duration(milliseconds: 100));
//
//     mockingjay
//         .verify(() => navigator.push(mockingjay.any(
//             that: mockingjay.isRoute(whereName: equals("/settings/currency")))))
//         .called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
}
