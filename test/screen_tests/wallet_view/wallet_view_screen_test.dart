// import 'package:decimal/decimal.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_feather_icons/flutter_feather_icons.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
// import 'package:epicmobile/pages/transaction_subviews/transaction_search_view.dart';
// import 'package:epicmobile/pages/wallet_view/wallet_view.dart';
import 'package:epicmobile/services/coins/manager.dart';
// import 'package:epicmobile/services/event_bus/events/node_connection_status_changed_event.dart';
// import 'package:epicmobile/services/event_bus/global_event_bus.dart';
import 'package:epicmobile/services/locale_service.dart';
import 'package:epicmobile/services/notes_service.dart';
// import 'package:epicmobile/widgets/custom_buttons/draggable_switch_button.dart';
// import 'package:epicmobile/widgets/gradient_card.dart';
// import 'package:epicmobile/widgets/transaction_card.dart';
// import 'package:provider/provider.dart';
//
// import '../../sample_data/transaction_data_samples.dart';
// import 'wallet_view_screen_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<Manager>(returnNullOnMissingStub: true),
  MockSpec<NotesService>(returnNullOnMissingStub: true),
  MockSpec<LocaleService>(returnNullOnMissingStub: true),
])
void main() {
//   testWidgets("WalletView builds correctly with no transactions",
//       (tester) async {
//     final manager = MockManager();
//
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//
//     when(manager.balance).thenAnswer((_) async => Decimal.one);
//     when(manager.totalBalance).thenAnswer((_) async => Decimal.ten);
//     when(manager.fiatBalance).thenAnswer((_) async => Decimal.ten);
//     when(manager.fiatTotalBalance)
//         .thenAnswer((_) async => Decimal.fromInt(100));
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: Material(
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//             ],
//             child: WalletView(),
//           ),
//         ),
//       ),
//     );
//
//     expect(find.text("... FIRO"), findsOneWidget);
//     expect(find.text("... USD"), findsOneWidget);
//
//     expect(find.text("AVAILABLE"), findsOneWidget);
//     expect(find.text("FULL"), findsOneWidget);
//
//     expect(find.byType(SvgPicture), findsNWidgets(2));
//     expect(find.byType(GradientCard), findsOneWidget);
//     expect(find.byType(DraggableSwitchButton), findsOneWidget);
//
//     expect(find.text("TRANSACTIONS"), findsOneWidget);
//     expect(find.text("NO TRANSACTIONS YET"), findsOneWidget);
//
//     expect(find.byIcon(FeatherIcons.search), findsOneWidget);
//
//     await tester.pumpAndSettle();
//
//     expect(find.text("10.00000000 FIRO"), findsOneWidget);
//     expect(find.text("100.00000000 USD"), findsOneWidget);
//     expect(find.text("NO TRANSACTIONS YET"), findsOneWidget);
//     expect(find.byType(SvgPicture), findsNWidgets(2));
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.totalBalance).called(1);
//     verify(manager.fiatTotalBalance).called(1);
//     verify(manager.coinTicker).called(2);
//     verify(manager.fiatCurrency).called(1);
//     verify(manager.transactionData).called(1);
//
//     verifyNoMoreInteractions(manager);
//   });
//
//   testWidgets("WalletView builds correctly with transaction history",
//       (tester) async {
//     final navigator = mockingjay.MockNavigator();
//     final manager = MockManager();
//     final notesService = MockNotesService();
//     final localeService = MockLocaleService();
//
//     when(localeService.locale).thenAnswer((_) => "en_US");
//
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//
//     when(manager.balance).thenAnswer((_) async => Decimal.one);
//     when(manager.fiatPrice).thenAnswer((_) async => Decimal.one);
//     when(manager.totalBalance).thenAnswer((_) async => Decimal.ten);
//     when(manager.fiatBalance).thenAnswer((_) async => Decimal.ten);
//     when(manager.fiatTotalBalance)
//         .thenAnswer((_) async => Decimal.fromInt(100));
//
//     when(manager.refresh()).thenAnswer((_) async {});
//
//     when(manager.transactionData)
//         .thenAnswer((_) async => transactionDataFromJsonChunks);
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: Material(
//             child: MultiProvider(
//               providers: [
//                 ChangeNotifierProvider<Manager>(
//                   create: (_) => manager,
//                 ),
//                 ChangeNotifierProvider<NotesService>(
//                   create: (_) => notesService,
//                 ),
//                 ChangeNotifierProvider<LocaleService>(
//                   create: (_) => localeService,
//                 ),
//               ],
//               child: WalletView(),
//             ),
//           ),
//         ),
//       ),
//     );
//
//     expect(find.text("... FIRO"), findsOneWidget);
//     expect(find.text("... USD"), findsOneWidget);
//
//     expect(find.text("AVAILABLE"), findsOneWidget);
//     expect(find.text("FULL"), findsOneWidget);
//
//     expect(find.byType(SvgPicture), findsNWidgets(2));
//     expect(find.byType(GradientCard), findsOneWidget);
//     expect(find.byType(DraggableSwitchButton), findsOneWidget);
//
//     expect(find.text("TRANSACTIONS"), findsOneWidget);
//     expect(find.text("NO TRANSACTIONS YET"), findsOneWidget);
//
//     expect(find.byIcon(FeatherIcons.search), findsOneWidget);
//
//     await tester.pumpAndSettle();
//
//     expect(find.text("10.00000000 FIRO"), findsOneWidget);
//     expect(find.text("100.00000000 USD"), findsOneWidget);
//     expect(find.text("NO TRANSACTIONS YET"), findsNothing);
//     expect(find.byType(SvgPicture), findsNWidgets(1));
//     expect(find.byType(TransactionCard), findsNWidgets(6));
//
//     verify(notesService.addListener(any)).called(1);
//
//     verify(localeService.addListener(any)).called(1);
//     verify(localeService.locale).called(18);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.totalBalance).called(1);
//     verify(manager.fiatPrice).called(9);
//     verify(manager.fiatTotalBalance).called(1);
//     verify(manager.coinTicker).called(11);
//     verify(manager.fiatCurrency).called(10);
//     verify(manager.transactionData).called(1);
//
//     verifyNoMoreInteractions(localeService);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(notesService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap tx search", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//     final manager = MockManager();
//     final notesService = MockNotesService();
//     final localeService = MockLocaleService();
//
//     when(localeService.locale).thenAnswer((_) => "en_US");
//
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//
//     when(manager.balance).thenAnswer((_) async => Decimal.one);
//     when(manager.totalBalance).thenAnswer((_) async => Decimal.ten);
//     when(manager.fiatBalance).thenAnswer((_) async => Decimal.ten);
//     when(manager.fiatTotalBalance)
//         .thenAnswer((_) async => Decimal.fromInt(100));
//
//     when(manager.refresh()).thenAnswer((_) async {});
//
//     when(manager.transactionData)
//         .thenAnswer((_) async => transactionDataFromJsonChunks);
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: Material(
//             child: MultiProvider(
//               providers: [
//                 ChangeNotifierProvider<Manager>(
//                   create: (_) => manager,
//                 ),
//                 ChangeNotifierProvider<NotesService>(
//                   create: (_) => notesService,
//                 ),
//                 ChangeNotifierProvider<LocaleService>(
//                   create: (_) => localeService,
//                 ),
//               ],
//               child: WalletView(),
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byType(IconButton));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(TransactionSearchView), findsOneWidget);
//
//     verify(notesService.addListener(any)).called(1);
//
//     verify(localeService.addListener(any)).called(1);
//     verify(localeService.locale).called(18);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.totalBalance).called(1);
//     verify(manager.fiatPrice).called(9);
//     verify(manager.fiatTotalBalance).called(1);
//     verify(manager.coinTicker).called(12);
//     verify(manager.fiatCurrency).called(1);
//     verify(manager.transactionData).called(1);
//
//     verifyNoMoreInteractions(localeService);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(notesService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("scroll transactions and test pull down refresh", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//     final manager = MockManager();
//     final notesService = MockNotesService();
//     final localeService = MockLocaleService();
//
//     when(localeService.locale).thenAnswer((_) => "en_US");
//
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//
//     when(manager.balance).thenAnswer((_) async => Decimal.one);
//     when(manager.totalBalance).thenAnswer((_) async => Decimal.ten);
//     when(manager.fiatBalance).thenAnswer((_) async => Decimal.ten);
//     when(manager.fiatTotalBalance)
//         .thenAnswer((_) async => Decimal.fromInt(100));
//
//     when(manager.refresh()).thenAnswer((_) async {});
//
//     when(manager.transactionData)
//         .thenAnswer((_) async => transactionDataFromJsonChunks);
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: Material(
//             child: MultiProvider(
//               providers: [
//                 ChangeNotifierProvider<Manager>(
//                   create: (_) => manager,
//                 ),
//                 ChangeNotifierProvider<NotesService>(
//                   create: (_) => notesService,
//                 ),
//                 ChangeNotifierProvider<LocaleService>(
//                   create: (_) => localeService,
//                 ),
//               ],
//               child: WalletView(),
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.fling(find.byType(ListView), Offset(0, 500), 10000);
//     await tester.pumpAndSettle();
//     await tester.fling(find.byType(ListView), Offset(0, -500), 10000);
//     await tester.pumpAndSettle();
//
//     verify(notesService.addListener(any)).called(1);
//
//     verify(localeService.addListener(any)).called(1);
//     verify(localeService.locale).called(48);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.totalBalance).called(1);
//     verify(manager.fiatPrice).called(24);
//     verify(manager.fiatTotalBalance).called(1);
//     verify(manager.coinTicker).called(26);
//     verify(manager.fiatCurrency).called(1);
//     verify(manager.transactionData).called(1);
//     verify(manager.refresh()).called(1);
//
//     verifyNoMoreInteractions(localeService);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(notesService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("node events", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//     final manager = MockManager();
//     final notesService = MockNotesService();
//     final localeService = MockLocaleService();
//
//     when(localeService.locale).thenAnswer((_) => "en_US");
//
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//
//     when(manager.balance).thenAnswer((_) async => Decimal.one);
//     when(manager.totalBalance).thenAnswer((_) async => Decimal.ten);
//     when(manager.fiatBalance).thenAnswer((_) async => Decimal.ten);
//     when(manager.fiatTotalBalance)
//         .thenAnswer((_) async => Decimal.fromInt(100));
//
//     when(manager.refresh()).thenAnswer((_) async {});
//
//     when(manager.transactionData)
//         .thenAnswer((_) async => transactionDataFromJsonChunks);
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: Material(
//             child: MultiProvider(
//               providers: [
//                 ChangeNotifierProvider<Manager>(
//                   create: (_) => manager,
//                 ),
//                 ChangeNotifierProvider<NotesService>(
//                   create: (_) => notesService,
//                 ),
//                 ChangeNotifierProvider<LocaleService>(
//                   create: (_) => localeService,
//                 ),
//               ],
//               child: WalletView(),
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(SpinKitThreeBounce), findsNothing);
//
//     GlobalEventBus.instance
//         .fire(NodeConnectionStatusChangedEvent(NodeConnectionStatus.loading));
//     await tester.pump(Duration(seconds: 1));
//
//     expect(find.byType(SpinKitThreeBounce), findsOneWidget);
//
//     GlobalEventBus.instance
//         .fire(NodeConnectionStatusChangedEvent(NodeConnectionStatus.synced));
//     await tester.pump();
//
//     expect(find.byType(SpinKitThreeBounce), findsNothing);
//
//     verify(notesService.addListener(any)).called(1);
//
//     verify(localeService.addListener(any)).called(1);
//     verify(localeService.locale).called(54);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.totalBalance).called(3);
//     verify(manager.fiatPrice).called(27);
//     verify(manager.fiatTotalBalance).called(3);
//     verify(manager.coinTicker).called(31);
//     verify(manager.fiatCurrency).called(3);
//     verify(manager.transactionData).called(3);
//
//     verifyNoMoreInteractions(localeService);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(notesService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("select full/available balances", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//     final manager = MockManager();
//     final notesService = MockNotesService();
//     final localeService = MockLocaleService();
//
//     when(localeService.locale).thenAnswer((_) => "en_US");
//
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//
//     when(manager.balance).thenAnswer((_) async => Decimal.one);
//     when(manager.fiatTotalBalance).thenAnswer((_) async => Decimal.one);
//     when(manager.totalBalance).thenAnswer((_) async => Decimal.ten);
//     when(manager.fiatBalance).thenAnswer((_) async => Decimal.ten);
//     when(manager.fiatTotalBalance)
//         .thenAnswer((_) async => Decimal.fromInt(100));
//
//     when(manager.refresh()).thenAnswer((_) async {});
//
//     when(manager.transactionData)
//         .thenAnswer((_) async => transactionDataFromJsonChunks);
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: Material(
//             child: MultiProvider(
//               providers: [
//                 ChangeNotifierProvider<Manager>(
//                   create: (_) => manager,
//                 ),
//                 ChangeNotifierProvider<NotesService>(
//                   create: (_) => notesService,
//                 ),
//                 ChangeNotifierProvider<LocaleService>(
//                   create: (_) => localeService,
//                 ),
//               ],
//               child: WalletView(),
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.text("10.00000000 FIRO"), findsOneWidget);
//     expect(find.text("100.00000000 USD"), findsOneWidget);
//
//     await tester.tap(find.byType(DraggableSwitchButton));
//     await tester.pumpAndSettle();
//
//     expect(find.text("1.00000000 FIRO"), findsOneWidget);
//     expect(find.text("10.00000000 USD"), findsOneWidget);
//
//     await tester.tap(find.byType(DraggableSwitchButton));
//     await tester.pumpAndSettle();
//
//     expect(find.text("10.00000000 FIRO"), findsOneWidget);
//     expect(find.text("100.00000000 USD"), findsOneWidget);
//
//     verify(notesService.addListener(any)).called(1);
//
//     verify(localeService.addListener(any)).called(1);
//     verify(localeService.locale).called(90);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.balance).called(1);
//     verify(manager.fiatPrice).called(45);
//     verify(manager.fiatTotalBalance).called(2);
//     verify(manager.totalBalance).called(2);
//     verify(manager.fiatBalance).called(1);
//     verify(manager.coinTicker).called(51);
//     verify(manager.fiatCurrency).called(3);
//     verify(manager.transactionData).called(3);
//
//     verifyNoMoreInteractions(localeService);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(notesService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
}
