// import 'package:decimal/decimal.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
// import 'package:epicmobile/notifications/campfire_alert.dart';
// import 'package:epicmobile/pages/wallet_view/confirm_send_view.dart';
import 'package:epicmobile/services/coins/manager.dart';
import 'package:epicmobile/services/notes_service.dart';
// import 'package:epicmobile/utilities/flutter_secure_storage_interface.dart';
// import 'package:epicmobile/widgets/custom_buttons/gradient_button.dart';
// import 'package:epicmobile/widgets/custom_pin_put/custom_pin_put.dart';
// import 'package:epicmobile/widgets/custom_pin_put/pin_keyboard.dart';
// import 'package:provider/provider.dart';
//
// import 'confirm_send_view_screen_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<Manager>(returnNullOnMissingStub: true),
  MockSpec<NotesService>(returnNullOnMissingStub: true),
])
void main() {
//   testWidgets("ConfirmSendView builds correctly", (tester) async {
//     final manager = MockManager();
//     final notesService = MockNotesService();
//
//     when(manager.useBiometrics).thenAnswer((_) async => true);
//     when(manager.walletName).thenAnswer((_) => "My Firo Wallet");
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<Manager>(
//               create: (_) => manager,
//             ),
//             ChangeNotifierProvider<NotesService>(
//               create: (_) => notesService,
//             ),
//           ],
//           child: ConfirmSendView(
//             address: "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg",
//             note: "some note",
//             amount: Decimal.ten,
//             fee: Decimal.one,
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.text("Confirm transaction"), findsOneWidget);
//     expect(find.text("Enter PIN"), findsOneWidget);
//     expect(find.byType(CustomPinPut), findsOneWidget);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.walletName).called(1);
//     verify(manager.useBiometrics).called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(notesService);
//   });
//
//   testWidgets("confirm wrong pin", (tester) async {
//     final manager = MockManager();
//     final notesService = MockNotesService();
//     final secureStore = FakeSecureStorage();
//
//     secureStore.write(key: "walletID_pin", value: "1234");
//
//     when(manager.useBiometrics).thenAnswer((_) async => true);
//     when(manager.walletId).thenAnswer((_) => "walletID");
//     when(manager.walletName).thenAnswer((_) => "My Firo Wallet");
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<Manager>(
//               create: (_) => manager,
//             ),
//             ChangeNotifierProvider<NotesService>(
//               create: (_) => notesService,
//             ),
//           ],
//           child: ConfirmSendView(
//             address: "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg",
//             note: "some note",
//             amount: Decimal.ten,
//             fee: Decimal.one,
//             secureStore: secureStore,
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "1"));
//     await tester.pumpAndSettle();
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "2"));
//     await tester.pumpAndSettle();
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "3"));
//     await tester.pumpAndSettle();
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "6"));
//     await tester.pump(Duration(milliseconds: 600));
//
//     expect(find.text("Incorrect PIN. Transaction cancelled."), findsOneWidget);
//     await tester.pump(Duration(seconds: 1));
//
//     expect(find.text("Incorrect PIN. Transaction cancelled."), findsNothing);
//
//     verify(manager.walletId).called(1);
//     verify(manager.useBiometrics).called(1);
//     verify(manager.walletName).called(1);
//     verify(manager.addListener(any)).called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(notesService);
//   });
//
//   testWidgets("confirm correct pin but send fails", (tester) async {
//     final manager = MockManager();
//     final notesService = MockNotesService();
//     final secureStore = FakeSecureStorage();
//     final navigator = mockingjay.MockNavigator();
//
//     secureStore.write(key: "walletID_pin", value: "1234");
//
//     when(manager.walletName).thenAnswer((_) => "My Firo Wallet");
//     when(manager.useBiometrics).thenAnswer((_) async => true);
//     when(manager.send(
//       toAddress: "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg",
//       amount: 1000000000,
//     )).thenThrow(Exception("transaction failed for some reason"));
//
//     when(manager.walletId).thenAnswer((_) => "walletID");
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) {});
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
//               ChangeNotifierProvider<NotesService>(
//                 create: (_) => notesService,
//               ),
//             ],
//             child: ConfirmSendView(
//               address: "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg",
//               note: "some note",
//               amount: Decimal.ten,
//               fee: Decimal.one,
//               secureStore: secureStore,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "1"));
//     await tester.pumpAndSettle();
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "2"));
//     await tester.pumpAndSettle();
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "3"));
//     await tester.pumpAndSettle();
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "4"));
//     await tester.pump(Duration(milliseconds: 300));
//
//     expect(find.text("Incorrect PIN. Transaction cancelled."), findsNothing);
//     expect(find.text("Transaction failed."), findsOneWidget);
//
//     await tester.pump(Duration(seconds: 2));
//
//     expect(find.byType(CampfireAlert), findsOneWidget);
//     expect(find.textContaining("transaction failed for some reason"),
//         findsOneWidget);
//     expect(find.text("Transaction failed."), findsNothing);
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pump(Duration(seconds: 1));
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.send(
//       toAddress: "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg",
//       amount: 1000000000,
//     )).called(1);
//     verify(manager.useBiometrics).called(1);
//     verify(manager.walletId).called(1);
//     verify(manager.walletName).called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(notesService);
//
//     mockingjay.verify(() => navigator.pop()).called(2);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("confirm correct pin and send succeeds", (tester) async {
//     final manager = MockManager();
//     final notesService = MockNotesService();
//     final secureStore = FakeSecureStorage();
//     final navigator = mockingjay.MockNavigator();
//
//     secureStore.write(key: "walletID_pin", value: "1234");
//
//     when(manager.useBiometrics).thenAnswer((_) async => true);
//     when(manager.send(
//       toAddress: "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg",
//       amount: 1000000000,
//     )).thenAnswer((_) async => "some txid");
//
//     when(manager.walletId).thenAnswer((_) => "walletID");
//
//     when(notesService.addNote(txid: "some txid", note: "some note"))
//         .thenAnswer((_) {} as Future<void> Function(Invocation));
//
//     mockingjay
//         .when(() =>
//             navigator.pushNamedAndRemoveUntil("/mainview", (route) => false))
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
//               ChangeNotifierProvider<NotesService>(
//                 create: (_) => notesService,
//               ),
//             ],
//             child: ConfirmSendView(
//               address: "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg",
//               note: "some note",
//               amount: Decimal.ten,
//               fee: Decimal.one,
//               secureStore: secureStore,
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "1"));
//     await tester.pumpAndSettle();
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "2"));
//     await tester.pumpAndSettle();
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "3"));
//     await tester.pumpAndSettle();
//     await tester.tap(find.byWidgetPredicate(
//         (widget) => widget is NumberKey && widget.number == "4"));
//     await tester.pump(Duration(milliseconds: 300));
//
//     expect(find.text("Incorrect PIN. Transaction cancelled."), findsNothing);
//     expect(find.text("Transaction failed."), findsNothing);
//     expect(find.text("Transaction sent"), findsOneWidget);
//
//     await tester.pump(Duration(seconds: 3));
//
//     expect(find.text("Transaction failed."), findsNothing);
//     expect(find.text("Transaction sent"), findsNothing);
//     expect(find.text("Incorrect PIN. Transaction cancelled."), findsNothing);
//
//     verify(notesService.addNote(txid: "some txid", note: "some note"))
//         .called(1);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.send(
//       toAddress: "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg",
//       amount: 1000000000,
//     )).called(1);
//     verify(manager.useBiometrics).called(1);
//     verify(manager.walletId).called(1);
//     verify(manager.walletName).called(1);
//
//     verify(notesService.addListener(any)).called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(notesService);
//
//     mockingjay
//         .verify(() =>
//             navigator.pushNamedAndRemoveUntil("/mainview", mockingjay.any()))
//         .called(1);
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
}
