// import 'package:decimal/decimal.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
// import 'package:stackwallet/models/lelantus_fee_data.dart';
// import 'package:stackwallet/pages/main_view.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/services/locale_service.dart';
import 'package:stackwallet/services/notes_service.dart';
import 'package:stackwallet/services/wallets_service.dart';
// import 'package:provider/provider.dart';
//
// import '../../sample_data/transaction_data_samples.dart';
// import 'main_view_screen_testC_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<WalletsService>(returnNullOnMissingStub: true),
  MockSpec<Manager>(returnNullOnMissingStub: true),
  MockSpec<NotesService>(returnNullOnMissingStub: true),
  MockSpec<LocaleService>(returnNullOnMissingStub: true),
])
void main() {
//   testWidgets("tap send", (tester) async {
//     final walletsService = MockWalletsService();
//     final manager = MockManager();
//     final notesService = MockNotesService();
//     final localeService = MockLocaleService();
//
//     when(localeService.locale).thenAnswer((_) => "en_US");
//
//     when(walletsService.currentWalletName)
//         .thenAnswer((_) async => "My Firo Wallet");
//
//     when(manager.fiatPrice).thenAnswer((_) async => Decimal.ten);
//     when(manager.refresh()).thenAnswer((_) async {});
//     when(manager.exitCurrentWallet()).thenAnswer((_) async {});
//
//     when(manager.balance).thenAnswer((_) async => Decimal.one);
//     when(manager.totalBalance).thenAnswer((_) async => Decimal.ten);
//     when(manager.fiatBalance).thenAnswer((_) async => Decimal.ten);
//     when(manager.fiatTotalBalance)
//         .thenAnswer((_) async => Decimal.fromInt(100));
//
//     when(manager.coinTicker).thenAnswer((_) => "FIRO");
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//
//     when(manager.maxFee).thenAnswer((_) async => LelantusFeeData(0, 100, []));
//     when(manager.balanceMinusMaxFee).thenAnswer((_) async => Decimal.one);
//
//     when(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .thenAnswer((_) => true);
//
//     when(manager.transactionData)
//         .thenAnswer((_) async => transactionDataFromJsonChunks);
//
//     when(manager.currentReceivingAddress)
//         .thenAnswer((_) async => "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg");
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
//             ChangeNotifierProvider<NotesService>(
//               create: (_) => notesService,
//             ),
//             ChangeNotifierProvider<LocaleService>(
//               create: (_) => localeService,
//             ),
//           ],
//           child: MainView(
//             disableRefreshOnInit: false,
//             args: {
//               "addressBookEntry": {
//                 "address": "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg",
//                 "name": "john doe",
//               }
//             },
//           ),
//         ),
//       ),
//     );
//
//     await tester.pumpAndSettle(Duration(seconds: 3));
//     expect(
//         (find.byType(BottomNavigationBar).evaluate().single.widget
//                 as BottomNavigationBar)
//             .currentIndex,
//         1);
//
//     await tester.tap(find.byKey(Key("mainViewNavBarSendItemKey")));
//     await tester.pumpAndSettle();
//     expect(
//         (find.byType(BottomNavigationBar).evaluate().single.widget
//                 as BottomNavigationBar)
//             .currentIndex,
//         0);
//
//     verify(notesService.addListener(any)).called(1);
//
//     verify(walletsService.addListener(any)).called(1);
//     verify(walletsService.currentWalletName).called(2);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.fiatPrice).called(8);
//     verify(manager.refresh()).called(1);
//     verify(manager.totalBalance).called(1);
//     verify(manager.balanceMinusMaxFee).called(1);
//     verify(manager.fiatTotalBalance).called(1);
//     verify(manager.maxFee).called(1);
//     verify(manager.coinTicker).called(16);
//     verify(manager.fiatCurrency).called(10);
//     verify(manager.transactionData).called(1);
//     verify(manager.currentReceivingAddress).called(2);
//     verify(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
//         .called(1);
//
//     verify(localeService.addListener(any)).called(1);
//     verify(localeService.locale).called(14);
//
//     verifyNoMoreInteractions(localeService);
//     verifyNoMoreInteractions(walletsService);
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(notesService);
//   });
}
