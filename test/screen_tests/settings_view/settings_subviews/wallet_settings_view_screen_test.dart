// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
// import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
import 'package:epicmobile/electrumx_rpc/cached_electrumx.dart';
// import 'package:epicmobile/notifications/campfire_alert.dart';
// import 'package:epicmobile/pages/settings_view/settings_subviews/wallet_settings_view.dart';
import 'package:epicmobile/services/coins/manager.dart';
import 'package:epicmobile/services/wallets_service.dart';
import 'package:epicmobile/utilities/biometrics.dart';
// import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
// import 'package:epicmobile/widgets/custom_buttons/gradient_button.dart';
// import 'package:epicmobile/widgets/custom_buttons/simple_button.dart';
// import 'package:provider/provider.dart';
//
// import 'wallet_settings_view_screen_test.mocks.dart';

@GenerateMocks([
  CachedElectrumX,
  LocalAuthentication,
  Biometrics,
], customMocks: [
  MockSpec<WalletsService>(returnNullOnMissingStub: true),
  MockSpec<Manager>(returnNullOnMissingStub: true),
])
void main() {
//   testWidgets("WalletSettingsView builds correctly", (tester) async {
//     final manager = MockManager();
//     final walletsService = MockWalletsService();
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<WalletsService>(
//               create: (_) => walletsService,
//             ),
//             ChangeNotifierProvider<Manager>(
//               create: (_) => manager,
//             ),
//           ],
//           child: WalletSettingsView(
//             useBiometrics: true,
//           ),
//         ),
//       ),
//     );
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(SvgPicture), findsOneWidget);
//     expect(find.byType(CFDivider), findsNWidgets(5));
//
//     expect(find.text("Wallet Settings"), findsOneWidget);
//     expect(find.text("Change PIN"), findsOneWidget);
//     expect(find.text("Enable biometric authentication"), findsOneWidget);
//     expect(find.text("Rename wallet"), findsOneWidget);
//     expect(find.text("Delete wallet"), findsOneWidget);
//     expect(find.text("Clear shared transaction cache"), findsOneWidget);
//     expect(find.text("Full Rescan"), findsOneWidget);
//
//     verify(manager.addListener(any)).called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(walletsService);
//   });
//
//   testWidgets("tap back", (tester) async {
//     final manager = MockManager();
//     final walletsService = MockWalletsService();
//     final navigator = mockingjay.MockNavigator();
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
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//             ],
//             child: WalletSettingsView(
//               useBiometrics: true,
//             ),
//           ),
//         ),
//       ),
//     );
//
//     await tester.tap(find.byKey(Key("settingsAppBarBackButton")));
//     await tester.pump(Duration(milliseconds: 100));
//
//     verify(manager.addListener(any)).called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(walletsService);
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap change pin", (tester) async {
//     final manager = MockManager();
//     final walletsService = MockWalletsService();
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
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<WalletsService>(
//                 create: (_) => walletsService,
//               ),
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//             ],
//             child: WalletSettingsView(
//               useBiometrics: true,
//             ),
//           ),
//         ),
//       ),
//     );
//
//     await tester.tap(find.byKey(Key("walletSettingsChangePinButtonKey")));
//     await tester.pump(Duration(milliseconds: 100));
//
//     verify(manager.addListener(any)).called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(walletsService);
//
//     mockingjay
//         .verify(() => navigator.push(mockingjay.any(
//             that: mockingjay.isRoute(
//                 whereName: equals("/settings/changepinlockscreen")))))
//         .called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap rename wallet", (tester) async {
//     final manager = MockManager();
//     final walletsService = MockWalletsService();
//     final navigator = mockingjay.MockNavigator();
//
//     mockingjay
//         .when(() => navigator.push(mockingjay.any()))
//         .thenAnswer((_) async {});
//
//     when(walletsService.currentWalletName)
//         .thenAnswer((realInvocation) async => "My Firo Wallet");
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
//             child: WalletSettingsView(
//               useBiometrics: true,
//             ),
//           ),
//         ),
//       ),
//     );
//
//     await tester.tap(find.byKey(Key("walletSettingsRenameWalletButtonKey")));
//     await tester.pump(Duration(milliseconds: 100));
//
//     verify(manager.addListener(any)).called(1);
//
//     verify(walletsService.addListener(any)).called(1);
//     verify(walletsService.currentWalletName).called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(walletsService);
//
//     mockingjay
//         .verify(() => navigator.push(mockingjay.any(
//             that: mockingjay.isRoute(
//                 whereName: equals("/settings/renamewallet")))))
//         .called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap delete wallet and cancel", (tester) async {
//     final manager = MockManager();
//     final walletsService = MockWalletsService();
//     final navigator = mockingjay.MockNavigator();
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) {});
//
//     when(walletsService.currentWalletName)
//         .thenAnswer((realInvocation) async => "My Firo Wallet");
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
//             child: WalletSettingsView(
//               useBiometrics: true,
//             ),
//           ),
//         ),
//       ),
//     );
//
//     await tester.tap(find.byKey(Key("walletSettingsDeleteWalletButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(ConfirmationDialog), findsOneWidget);
//     expect(find.text("Do you want to delete My Firo Wallet Wallet?"),
//         findsOneWidget);
//     expect(find.text("CANCEL"), findsOneWidget);
//     expect(find.text("DELETE"), findsOneWidget);
//
//     await tester.tap(find.byType(SimpleButton));
//     await tester.pumpAndSettle();
//
//     verify(manager.addListener(any)).called(1);
//
//     verify(walletsService.addListener(any)).called(1);
//     verify(walletsService.currentWalletName).called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(walletsService);
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap delete wallet and continue", (tester) async {
//     final manager = MockManager();
//     final walletsService = MockWalletsService();
//     final navigator = mockingjay.MockNavigator();
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) {});
//     mockingjay
//         .when(() => navigator.push(mockingjay.any()))
//         .thenAnswer((_) async {});
//
//     when(walletsService.currentWalletName)
//         .thenAnswer((realInvocation) async => "My Firo Wallet");
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
//             child: WalletSettingsView(
//               useBiometrics: true,
//             ),
//           ),
//         ),
//       ),
//     );
//
//     await tester.tap(find.byKey(Key("walletSettingsDeleteWalletButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(ConfirmationDialog), findsOneWidget);
//     expect(find.text("Do you want to delete My Firo Wallet Wallet?"),
//         findsOneWidget);
//     expect(find.text("CANCEL"), findsOneWidget);
//     expect(find.text("DELETE"), findsOneWidget);
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle();
//
//     verify(manager.addListener(any)).called(1);
//
//     verify(walletsService.addListener(any)).called(1);
//     verify(walletsService.currentWalletName).called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(walletsService);
//
//     mockingjay
//         .verify(() => navigator.push(mockingjay.any(
//             that: mockingjay.isRoute(
//                 whereName: equals("/settings/deletewalletlockscreen")))))
//         .called(1);
//     mockingjay.verify(() => navigator.pop()).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap clear cache and cancel", (tester) async {
//     final manager = MockManager();
//     final walletsService = MockWalletsService();
//     final navigator = mockingjay.MockNavigator();
//
//     when(manager.coinName).thenAnswer((_) => "Firo");
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
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//             ],
//             child: WalletSettingsView(
//               useBiometrics: true,
//             ),
//           ),
//         ),
//       ),
//     );
//
//     await tester
//         .tap(find.byKey(Key("walletSettingsClearSharedCacheButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(ConfirmationDialog), findsOneWidget);
//     expect(
//         find.text(
//             "Are you sure you want to clear all shared cached Firo transaction data?"),
//         findsOneWidget);
//     expect(find.text("CANCEL"), findsOneWidget);
//     expect(find.text("CLEAR"), findsOneWidget);
//
//     await tester.tap(find.byType(SimpleButton));
//     await tester.pumpAndSettle();
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.coinName).called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(walletsService);
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap clear cache and confirm succeeds", (tester) async {
//     final manager = MockManager();
//     final walletsService = MockWalletsService();
//     final navigator = mockingjay.MockNavigator();
//     final client = MockCachedElectrumX();
//
//     when(manager.coinName).thenAnswer((_) => "Firo");
//
//     when(client.clearSharedTransactionCache(coinName: "Firo"))
//         .thenAnswer((_) async {});
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
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//             ],
//             child: WalletSettingsView(
//               cachedClient: client,
//               useBiometrics: true,
//             ),
//           ),
//         ),
//       ),
//     );
//
//     await tester
//         .tap(find.byKey(Key("walletSettingsClearSharedCacheButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(ConfirmationDialog), findsOneWidget);
//     expect(
//         find.text(
//             "Are you sure you want to clear all shared cached Firo transaction data?"),
//         findsOneWidget);
//     expect(find.text("CANCEL"), findsOneWidget);
//     expect(find.text("CLEAR"), findsOneWidget);
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(CampfireAlert), findsOneWidget);
//     expect(find.text("Transaction cache cleared!"), findsOneWidget);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.coinName).called(1);
//
//     verify(client.clearSharedTransactionCache(coinName: "Firo")).called(1);
//
//     verifyNoMoreInteractions(client);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(walletsService);
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap clear cache and confirm fails", (tester) async {
//     final manager = MockManager();
//     final walletsService = MockWalletsService();
//     final navigator = mockingjay.MockNavigator();
//     final client = MockCachedElectrumX();
//
//     when(manager.coinName).thenAnswer((_) => "Firo");
//
//     when(client.clearSharedTransactionCache(coinName: "Firo"))
//         .thenThrow(Exception("mock throws"));
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
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//             ],
//             child: WalletSettingsView(
//               cachedClient: client,
//               useBiometrics: true,
//             ),
//           ),
//         ),
//       ),
//     );
//
//     await tester
//         .tap(find.byKey(Key("walletSettingsClearSharedCacheButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(ConfirmationDialog), findsOneWidget);
//     expect(
//         find.text(
//             "Are you sure you want to clear all shared cached Firo transaction data?"),
//         findsOneWidget);
//     expect(find.text("CANCEL"), findsOneWidget);
//     expect(find.text("CLEAR"), findsOneWidget);
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(CampfireAlert), findsOneWidget);
//     expect(find.text("Failed to clear transaction cache."), findsOneWidget);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.coinName).called(1);
//
//     verify(client.clearSharedTransactionCache(coinName: "Firo")).called(1);
//
//     verifyNoMoreInteractions(client);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(walletsService);
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap rescan wallet and cancel", (tester) async {
//     final manager = MockManager();
//     final walletsService = MockWalletsService();
//     final navigator = mockingjay.MockNavigator();
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) {});
//
//     when(walletsService.currentWalletName)
//         .thenAnswer((realInvocation) async => "My Firo Wallet");
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
//             child: WalletSettingsView(
//               useBiometrics: true,
//             ),
//           ),
//         ),
//       ),
//     );
//
//     await tester.tap(find.byKey(Key("walletSettingsFullRescanButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(ConfirmationDialog), findsOneWidget);
//     expect(find.text("Are you sure you want to do a full rescan?"),
//         findsOneWidget);
//     expect(find.text("CANCEL"), findsOneWidget);
//     expect(find.text("RESCAN"), findsOneWidget);
//
//     await tester.tap(find.byType(SimpleButton));
//     await tester.pumpAndSettle();
//
//     verify(manager.addListener(any)).called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(walletsService);
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap rescan wallet and continue", (tester) async {
//     final manager = MockManager();
//     final walletsService = MockWalletsService();
//     final navigator = mockingjay.MockNavigator();
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) {});
//     mockingjay
//         .when(() => navigator.push(mockingjay.any()))
//         .thenAnswer((_) async {});
//
//     when(walletsService.currentWalletName)
//         .thenAnswer((realInvocation) async => "My Firo Wallet");
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
//             child: WalletSettingsView(
//               useBiometrics: true,
//             ),
//           ),
//         ),
//       ),
//     );
//
//     await tester.tap(find.byKey(Key("walletSettingsFullRescanButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(ConfirmationDialog), findsOneWidget);
//     expect(find.text("Are you sure you want to do a full rescan?"),
//         findsOneWidget);
//     expect(find.text("CANCEL"), findsOneWidget);
//     expect(find.text("RESCAN"), findsOneWidget);
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle();
//
//     verify(manager.addListener(any)).called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(walletsService);
//
//     mockingjay
//         .verify(() => navigator.push(mockingjay.any(
//             that: mockingjay.isRoute(
//                 whereName: equals("/settings/rescanwalletlockscreen")))))
//         .called(1);
//     mockingjay.verify(() => navigator.pop()).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("biometrics not available on device", (tester) async {
//     final manager = MockManager();
//     final walletsService = MockWalletsService();
//     final navigator = mockingjay.MockNavigator();
//     final localAuth = MockLocalAuthentication();
//
//     when(manager.updateBiometricsUsage(false)).thenAnswer((_) async {});
//
//     when(localAuth.canCheckBiometrics).thenAnswer((_) async => false);
//     when(localAuth.isDeviceSupported()).thenAnswer((_) async => false);
//     when(localAuth.getAvailableBiometrics())
//         .thenAnswer((_) async => <BiometricType>[]);
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
//             child: WalletSettingsList(
//               localAuthentication: localAuth,
//               useBiometrics: false,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(
//         (find.byType(BiometricsSwitch).evaluate().first.widget
//                 as BiometricsSwitch)
//             .useBiometrics,
//         false);
//
//     await tester
//         .tap(find.byKey(Key("walletSettingsEnableBiometricsButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(CampfireAlert), findsOneWidget);
//     expect(
//         find.text(
//             "Biometric security features not available on current device."),
//         findsOneWidget);
//
//     expect(
//         (find.byType(BiometricsSwitch).evaluate().first.widget
//                 as BiometricsSwitch)
//             .useBiometrics,
//         false);
//
//     verify(manager.addListener(any)).called(1);
//
//     verify(localAuth.canCheckBiometrics).called(1);
//     verify(localAuth.isDeviceSupported()).called(1);
//     verify(localAuth.getAvailableBiometrics()).called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(localAuth);
//     verifyNoMoreInteractions(walletsService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap to disable biometrics", (tester) async {
//     final manager = MockManager();
//     final walletsService = MockWalletsService();
//     final navigator = mockingjay.MockNavigator();
//     final localAuth = MockLocalAuthentication();
//
//     when(manager.updateBiometricsUsage(false)).thenAnswer((_) async {});
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
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//             ],
//             child: WalletSettingsList(
//               localAuthentication: localAuth,
//               useBiometrics: true,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(
//         (find.byType(BiometricsSwitch).evaluate().first.widget
//                 as BiometricsSwitch)
//             .useBiometrics,
//         true);
//
//     await tester
//         .tap(find.byKey(Key("walletSettingsEnableBiometricsButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(
//         (find.byType(BiometricsSwitch).evaluate().first.widget
//                 as BiometricsSwitch)
//             .useBiometrics,
//         false);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.updateBiometricsUsage(false)).called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(localAuth);
//     verifyNoMoreInteractions(walletsService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap to enable biometrics succeeds", (tester) async {
//     final manager = MockManager();
//     final walletsService = MockWalletsService();
//     final navigator = mockingjay.MockNavigator();
//     final localAuth = MockLocalAuthentication();
//     final biometrics = MockBiometrics();
//
//     when(manager.updateBiometricsUsage(true)).thenAnswer((_) async {});
//
//     when(biometrics.authenticate(
//             cancelButtonText: "CANCEL",
//             localizedReason:
//                 "Unlock wallet and confirm transactions with your fingerprint",
//             title: "Enable fingerprint authentication"))
//         .thenAnswer((_) async => true);
//
//     when(localAuth.canCheckBiometrics).thenAnswer((_) async => true);
//     when(localAuth.isDeviceSupported()).thenAnswer((_) async => true);
//     when(localAuth.getAvailableBiometrics())
//         .thenAnswer((_) async => <BiometricType>[BiometricType.fingerprint]);
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
//             child: WalletSettingsList(
//               localAuthentication: localAuth,
//               useBiometrics: false,
//               biometrics: biometrics,
//             ),
//           ),
//         ),
//       ),
//     );
//
//     expect(
//         (find.byType(BiometricsSwitch).evaluate().first.widget
//                 as BiometricsSwitch)
//             .useBiometrics,
//         false);
//
//     await tester
//         .tap(find.byKey(Key("walletSettingsEnableBiometricsButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(
//         (find.byType(BiometricsSwitch).evaluate().first.widget
//                 as BiometricsSwitch)
//             .useBiometrics,
//         true);
//
//     verify(localAuth.canCheckBiometrics).called(1);
//     verify(localAuth.isDeviceSupported()).called(1);
//     verify(localAuth.getAvailableBiometrics()).called(1);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.updateBiometricsUsage(true)).called(1);
//
//     verify(biometrics.authenticate(
//             cancelButtonText: "CANCEL",
//             localizedReason:
//                 "Unlock wallet and confirm transactions with your fingerprint",
//             title: "Enable fingerprint authentication"))
//         .called(1);
//
//     verifyNoMoreInteractions(biometrics);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(localAuth);
//     verifyNoMoreInteractions(walletsService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap to enable biometrics and cancel system settings dialog",
//       (tester) async {
//     final manager = MockManager();
//     final walletsService = MockWalletsService();
//     final navigator = mockingjay.MockNavigator();
//     final localAuth = MockLocalAuthentication();
//     final biometrics = MockBiometrics();
//
//     when(biometrics.authenticate(
//             cancelButtonText: "CANCEL",
//             localizedReason:
//                 "Unlock wallet and confirm transactions with your fingerprint",
//             title: "Enable fingerprint authentication"))
//         .thenAnswer((_) async => false);
//
//     when(localAuth.canCheckBiometrics).thenAnswer((_) async => true);
//     when(localAuth.isDeviceSupported()).thenAnswer((_) async => true);
//     when(localAuth.getAvailableBiometrics())
//         .thenAnswer((_) async => <BiometricType>[]);
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
//             child: WalletSettingsList(
//               localAuthentication: localAuth,
//               useBiometrics: false,
//               biometrics: biometrics,
//             ),
//           ),
//         ),
//       ),
//     );
//
//     expect(
//         (find.byType(BiometricsSwitch).evaluate().first.widget
//                 as BiometricsSwitch)
//             .useBiometrics,
//         false);
//
//     await tester
//         .tap(find.byKey(Key("walletSettingsEnableBiometricsButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(
//         find.text(
//             "Biometric security features not enabled on current device. Go to system settings?"),
//         findsOneWidget);
//     expect(find.text("CANCEL"), findsOneWidget);
//     expect(find.text("SETTINGS"), findsOneWidget);
//
//     await tester.tap(find.byType(SimpleButton));
//     await tester.pumpAndSettle();
//
//     expect(
//         find.text(
//             "Biometric security features not enabled on current device. Go to system settings?"),
//         findsNothing);
//     expect(find.byType(SimpleButton), findsNothing);
//     expect(find.text("CANCEL"), findsNothing);
//     expect(find.text("SETTINGS"), findsNothing);
//
//     expect(
//         (find.byType(BiometricsSwitch).evaluate().first.widget
//                 as BiometricsSwitch)
//             .useBiometrics,
//         false);
//
//     verify(localAuth.canCheckBiometrics).called(1);
//     verify(localAuth.isDeviceSupported()).called(1);
//     verify(localAuth.getAvailableBiometrics()).called(1);
//
//     verify(manager.addListener(any)).called(1);
//
//     verify(biometrics.authenticate(
//             cancelButtonText: "CANCEL",
//             localizedReason:
//                 "Unlock wallet and confirm transactions with your fingerprint",
//             title: "Enable fingerprint authentication"))
//         .called(1);
//
//     verifyNoMoreInteractions(biometrics);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(localAuth);
//     verifyNoMoreInteractions(walletsService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap to enable biometrics and open and enable system settings",
//       (tester) async {
//     final manager = MockManager();
//     final walletsService = MockWalletsService();
//     final navigator = mockingjay.MockNavigator();
//     final localAuth = MockLocalAuthentication();
//     final biometrics = MockBiometrics();
//
//     final channel = MethodChannel('app_settings');
//
//     handler(MethodCall methodCall) async {
//       if (methodCall.method == 'security') {
//         return;
//       }
//       fail("Bad AppSettings MethodCall");
//     }
//
//     tester.binding.defaultBinaryMessenger
//         .setMockMethodCallHandler(channel, handler);
//
//     when(manager.updateBiometricsUsage(true)).thenAnswer((_) async {});
//     when(biometrics.authenticate(
//             cancelButtonText: "CANCEL",
//             localizedReason:
//                 "Unlock wallet and confirm transactions with your fingerprint",
//             title: "Enable fingerprint authentication"))
//         .thenAnswer((_) async => true);
//
//     when(localAuth.canCheckBiometrics).thenAnswer((_) async => true);
//     when(localAuth.isDeviceSupported()).thenAnswer((_) async => true);
//     when(localAuth.getAvailableBiometrics())
//         .thenAnswer((_) async => <BiometricType>[]);
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
//             child: WalletSettingsList(
//               localAuthentication: localAuth,
//               useBiometrics: false,
//               biometrics: biometrics,
//             ),
//           ),
//         ),
//       ),
//     );
//
//     expect(
//         (find.byType(BiometricsSwitch).evaluate().first.widget
//                 as BiometricsSwitch)
//             .useBiometrics,
//         false);
//
//     await tester
//         .tap(find.byKey(Key("walletSettingsEnableBiometricsButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(
//         find.text(
//             "Biometric security features not enabled on current device. Go to system settings?"),
//         findsOneWidget);
//     expect(find.text("CANCEL"), findsOneWidget);
//     expect(find.text("SETTINGS"), findsOneWidget);
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle();
//
//     expect(
//         find.text(
//             "Biometric security features not enabled on current device. Go to system settings?"),
//         findsNothing);
//     expect(find.byType(GradientButton), findsNothing);
//     expect(find.text("CANCEL"), findsNothing);
//     expect(find.text("SETTINGS"), findsNothing);
//
//     expect(
//         (find.byType(BiometricsSwitch).evaluate().first.widget
//                 as BiometricsSwitch)
//             .useBiometrics,
//         true);
//
//     verify(localAuth.canCheckBiometrics).called(1);
//     verify(localAuth.isDeviceSupported()).called(1);
//     verify(localAuth.getAvailableBiometrics()).called(1);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.updateBiometricsUsage(true)).called(1);
//
//     verify(biometrics.authenticate(
//             cancelButtonText: "CANCEL",
//             localizedReason:
//                 "Unlock wallet and confirm transactions with your fingerprint",
//             title: "Enable fingerprint authentication"))
//         .called(1);
//
//     verifyNoMoreInteractions(biometrics);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(localAuth);
//     verifyNoMoreInteractions(walletsService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets(
//       "tap to enable biometrics and open but do not enable system settings",
//       (tester) async {
//     final manager = MockManager();
//     final walletsService = MockWalletsService();
//     final navigator = mockingjay.MockNavigator();
//     final localAuth = MockLocalAuthentication();
//     final biometrics = MockBiometrics();
//
//     final channel = MethodChannel('app_settings');
//
//     handler(MethodCall methodCall) async {
//       if (methodCall.method == 'security') {
//         return;
//       }
//       fail("Bad AppSettings MethodCall");
//     }
//
//     tester.binding.defaultBinaryMessenger
//         .setMockMethodCallHandler(channel, handler);
//
//     when(biometrics.authenticate(
//             cancelButtonText: "CANCEL",
//             localizedReason:
//                 "Unlock wallet and confirm transactions with your fingerprint",
//             title: "Enable fingerprint authentication"))
//         .thenAnswer((_) async => false);
//
//     when(localAuth.canCheckBiometrics).thenAnswer((_) async => true);
//     when(localAuth.isDeviceSupported()).thenAnswer((_) async => true);
//     when(localAuth.getAvailableBiometrics())
//         .thenAnswer((_) async => <BiometricType>[]);
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
//             child: WalletSettingsList(
//               localAuthentication: localAuth,
//               useBiometrics: false,
//               biometrics: biometrics,
//             ),
//           ),
//         ),
//       ),
//     );
//
//     expect(
//         (find.byType(BiometricsSwitch).evaluate().first.widget
//                 as BiometricsSwitch)
//             .useBiometrics,
//         false);
//
//     await tester
//         .tap(find.byKey(Key("walletSettingsEnableBiometricsButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(
//         find.text(
//             "Biometric security features not enabled on current device. Go to system settings?"),
//         findsOneWidget);
//     expect(find.text("CANCEL"), findsOneWidget);
//     expect(find.text("SETTINGS"), findsOneWidget);
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle();
//
//     expect(
//         find.text(
//             "Biometric security features not enabled on current device. Go to system settings?"),
//         findsNothing);
//     expect(find.byType(GradientButton), findsNothing);
//     expect(find.text("CANCEL"), findsNothing);
//     expect(find.text("SETTINGS"), findsNothing);
//
//     expect(
//         (find.byType(BiometricsSwitch).evaluate().first.widget
//                 as BiometricsSwitch)
//             .useBiometrics,
//         false);
//
//     verify(localAuth.canCheckBiometrics).called(1);
//     verify(localAuth.isDeviceSupported()).called(1);
//     verify(localAuth.getAvailableBiometrics()).called(1);
//
//     verify(manager.addListener(any)).called(1);
//
//     verify(biometrics.authenticate(
//             cancelButtonText: "CANCEL",
//             localizedReason:
//                 "Unlock wallet and confirm transactions with your fingerprint",
//             title: "Enable fingerprint authentication"))
//         .called(1);
//
//     verifyNoMoreInteractions(biometrics);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(localAuth);
//     verifyNoMoreInteractions(walletsService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
}
