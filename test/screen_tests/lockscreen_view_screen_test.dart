import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
// import 'package:stackwallet/pages/pinpad_views/lock_screen_view.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/wallets_service.dart';

@GenerateMocks([], customMocks: [
  MockSpec<WalletsService>(returnNullOnMissingStub: true),
  MockSpec<NodeService>(returnNullOnMissingStub: true),
  MockSpec<Manager>(returnNullOnMissingStub: true),
])
void main() {
  testWidgets("LockscreenView builds correctly", (tester) async {
    // final navigator = mockingjay.MockNavigator();
    // final walletsService = MockWalletsService();
    // final nodeService = MockNodeService();
    // final manager = MockManager();
    // final secureStore = FakeSecureStorage();
    //
    // secureStore.write(key: "walletID", value: "1234");
    //
    // when(walletsService.getWalletId("My Firo Wallet"))
    //     .thenAnswer((_) async => "walletID");
    //
    // await tester.pumpWidget(
    //   MaterialApp(
    //     home: mockingjay.MockNavigatorProvider(
    //       navigator: navigator,
    //       child: MultiProvider(
    //         providers: [
    //           ChangeNotifierProvider<WalletsService>(
    //             create: (_) => walletsService,
    //           ),
    //           ChangeNotifierProvider<NodeService>(
    //             create: (_) => nodeService,
    //           ),
    //           ChangeNotifierProvider<Manager>(
    //             create: (_) => manager,
    //           ),
    //         ],
    //         child: LockscreenView(
    //           routeOnSuccess: "/mainview",
    //           secureStore: secureStore,
    //         ),
    //       ),
    //     ),
    //   ),
    // );
    //
    // await tester.pumpAndSettle();
    //
    // expect(find.byType(AppBarIconButton), findsOneWidget);
    // expect(find.byType(SvgPicture), findsOneWidget);
    //
    // expect(find.text("My Firo Wallet"), findsOneWidget);
    // expect(find.text("Enter PIN"), findsOneWidget);
    //
    // expect(find.byType(CustomPinPut), findsOneWidget);
  });

  testWidgets("enter valid pin", (tester) async {
    // final navigator = mockingjay.MockNavigator();
    // final walletsService = MockWalletsService();
    // final nodeService = MockNodeService();
    // final manager = MockManager();
    // final secureStore = FakeSecureStorage();
    //
    // secureStore.write(key: "walletID_pin", value: "1234");
    //
    // when(walletsService.getWalletId("My Firo Wallet"))
    //     .thenAnswer((_) async => "walletID");
    //
    // mockingjay
    //     .when(() => navigator.pushReplacementNamed("/mainview"))
    //     .thenAnswer((_) async => {});
    //
    // await tester.pumpWidget(
    //   MaterialApp(
    //     home: mockingjay.MockNavigatorProvider(
    //       navigator: navigator,
    //       child: MultiProvider(
    //         providers: [
    //           ChangeNotifierProvider<WalletsService>(
    //             create: (_) => walletsService,
    //           ),
    //           ChangeNotifierProvider<NodeService>(
    //             create: (_) => nodeService,
    //           ),
    //           ChangeNotifierProvider<Manager>(
    //             create: (_) => manager,
    //           ),
    //         ],
    //         child: LockscreenView(
    //           routeOnSuccess: "/mainview",
    //           secureStore: secureStore,
    //         ),
    //       ),
    //     ),
    //   ),
    // );
    //
    // await tester.pumpAndSettle();
    //
    // await tester.tap(find.byWidgetPredicate(
    //     (widget) => widget is NumberKey && widget.number == "1"));
    // await tester.pump(const Duration(milliseconds: 200));
    // await tester.tap(find.byWidgetPredicate(
    //     (widget) => widget is NumberKey && widget.number == "2"));
    // await tester.pump(const Duration(milliseconds: 200));
    // await tester.tap(find.byWidgetPredicate(
    //     (widget) => widget is NumberKey && widget.number == "3"));
    // await tester.pump(const Duration(milliseconds: 200));
    // await tester.tap(find.byWidgetPredicate(
    //     (widget) => widget is NumberKey && widget.number == "4"));
    // await tester.pump(const Duration(milliseconds: 500));
    //
    // expect(find.text("PIN code correct. Unlocking wallet..."), findsOneWidget);
    //
    // await tester.pump(const Duration(seconds: 2));
    //
    // mockingjay
    //     .verify(() => navigator.pushReplacementNamed("/mainview"))
    //     .called(1);
  });

  testWidgets("wallet initialization fails", (tester) async {
    // final navigator = mockingjay.MockNavigator();
    // final walletsService = MockWalletsService();
    // final nodeService = MockNodeService();
    // final manager = MockManager();
    // final secureStore = FakeSecureStorage();
    //
    // secureStore.write(key: "walletID_pin", value: "1234");
    //
    // when(walletsService.getWalletId("My Firo Wallet"))
    //     .thenAnswer((_) async => "walletID");
    //
    // mockingjay
    //     .when(() => navigator.pushReplacementNamed("/mainview"))
    //     .thenAnswer((_) async => {});
    //
    // await tester.pumpWidget(
    //   MaterialApp(
    //     home: mockingjay.MockNavigatorProvider(
    //       navigator: navigator,
    //       child: MultiProvider(
    //         providers: [
    //           ChangeNotifierProvider<WalletsService>(
    //             create: (_) => walletsService,
    //           ),
    //           ChangeNotifierProvider<NodeService>(
    //             create: (_) => nodeService,
    //           ),
    //           ChangeNotifierProvider<Manager>(
    //             create: (_) => manager,
    //           ),
    //         ],
    //         child: LockscreenView(
    //           routeOnSuccess: "/mainview",
    //           secureStore: secureStore,
    //         ),
    //       ),
    //     ),
    //   ),
    // );
    //
    // await tester.pumpAndSettle();
    //
    // await tester.tap(find.byWidgetPredicate(
    //     (widget) => widget is NumberKey && widget.number == "1"));
    // await tester.pump(const Duration(milliseconds: 200));
    // await tester.tap(find.byWidgetPredicate(
    //     (widget) => widget is NumberKey && widget.number == "2"));
    // await tester.pump(const Duration(milliseconds: 200));
    // await tester.tap(find.byWidgetPredicate(
    //     (widget) => widget is NumberKey && widget.number == "3"));
    // await tester.pump(const Duration(milliseconds: 200));
    // await tester.tap(find.byWidgetPredicate(
    //     (widget) => widget is NumberKey && widget.number == "4"));
    // await tester.pump(const Duration(milliseconds: 500));
    //
    // expect(find.text("PIN code correct. Unlocking wallet..."), findsOneWidget);
    //
    // await tester.pump(const Duration(seconds: 2));
    //
    // expect(
    //     find.text(
    //         "Failed to connect to network. Check your internet connection and make sure the Electrum X node you are connected to is not having any issues."),
    //     findsOneWidget);
    //
    // await tester.tap(find.byKey(Key("campfireAlertOKButtonKey")));
    // await tester.pump(const Duration(seconds: 2));
    // await tester.pump(const Duration(seconds: 2));
    //
    // expect(
    //     find.text(
    //         "Failed to connect to network. Check your internet connection and make sure the Electrum X node you are connected to is not having any issues."),
    //     findsNothing);
    //
    // mockingjay
    //     .verify(() => navigator.pushReplacementNamed("/mainview"))
    //     .called(1);
  });

  testWidgets("enter invalid pin", (tester) async {
    // final navigator = mockingjay.MockNavigator();
    // final walletsService = MockWalletsService();
    // final nodeService = MockNodeService();
    // final manager = MockManager();
    // final secureStore = FakeSecureStorage();
    //
    // secureStore.write(key: "walletID_pin", value: "1234");
    //
    // when(walletsService.getWalletId("My Firo Wallet"))
    //     .thenAnswer((_) async => "walletID");
    //
    // mockingjay
    //     .when(() => navigator.pushReplacementNamed("/mainview"))
    //     .thenAnswer((_) async => {});

    // await tester.pumpWidget(
    //   MaterialApp(
    //     home: mockingjay.MockNavigatorProvider(
    //       navigator: navigator,
    //       child: MultiProvider(
    //         providers: [
    //           ChangeNotifierProvider<WalletsService>(
    //             create: (_) => walletsService,
    //           ),
    //           ChangeNotifierProvider<NodeService>(
    //             create: (_) => nodeService,
    //           ),
    //           ChangeNotifierProvider<Manager>(
    //             create: (_) => manager,
    //           ),
    //         ],
    //         child: LockscreenView(
    //           routeOnSuccess: "/mainview",
    //           secureStore: secureStore,
    //         ),
    //       ),
    //     ),
    //   ),
    // );

    // await tester.pumpAndSettle();
    //
    // await tester.tap(find.byWidgetPredicate(
    //     (widget) => widget is NumberKey && widget.number == "1"));
    // await tester.pump(const Duration(milliseconds: 200));
    // await tester.tap(find.byWidgetPredicate(
    //     (widget) => widget is NumberKey && widget.number == "1"));
    // await tester.pump(const Duration(milliseconds: 200));
    // await tester.tap(find.byWidgetPredicate(
    //     (widget) => widget is NumberKey && widget.number == "3"));
    // await tester.pump(const Duration(milliseconds: 200));
    // await tester.tap(find.byWidgetPredicate(
    //     (widget) => widget is NumberKey && widget.number == "4"));
    // await tester.pump(const Duration(milliseconds: 500));
    //
    // expect(find.text("Incorrect PIN. Please try again"), findsOneWidget);
    //
    // await tester.pump(const Duration(seconds: 2));
    //
    // mockingjay.verifyNever(() => navigator.pushReplacementNamed("/mainview"));
  });

  testWidgets("tap back", (tester) async {
    // final navigator = mockingjay.MockNavigator();
    // final walletsService = MockWalletsService();
    // final nodeService = MockNodeService();
    // final manager = MockManager();
    // final secureStore = FakeSecureStorage();
    //
    // mockingjay.when(() => navigator.pop()).thenAnswer((_) async => {});

    // await tester.pumpWidget(
    //   MaterialApp(
    //     home: mockingjay.MockNavigatorProvider(
    //       navigator: navigator,
    //       child: MultiProvider(
    //         providers: [
    //           ChangeNotifierProvider<WalletsService>(
    //             create: (_) => walletsService,
    //           ),
    //           ChangeNotifierProvider<NodeService>(
    //             create: (_) => nodeService,
    //           ),
    //           ChangeNotifierProvider<Manager>(
    //             create: (_) => manager,
    //           ),
    //         ],
    //         child: LockscreenView(
    //           routeOnSuccess: "/mainview",
    //           secureStore: secureStore,
    //         ),
    //       ),
    //     ),
    //   ),
    // );

    // await tester.pumpAndSettle();
    //
    // await tester.tap(find.byType(AppBarIconButton));
    // await tester.pumpAndSettle();
    //
    // mockingjay.verify(() => navigator.pop()).called(1);
  });
}
