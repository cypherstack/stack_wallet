// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
// import 'package:epicmobile/pages/settings_view/settings_subviews/currency_view.dart';
import 'package:epicmobile/services/coins/manager.dart';
// import 'package:provider/provider.dart';
//
// import 'currency_view_screen_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<Manager>(returnNullOnMissingStub: true),
])
void main() {
//   testWidgets("CurrencyView builds correctly", (tester) async {
//     final manager = MockManager();
//
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<Manager>(
//               create: (_) => manager,
//             ),
//           ],
//           child: CurrencyView(),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byKey(Key("settingsAppBarBackButton")), findsOneWidget);
//     final selected = find
//         .byKey(Key("selectedCurrencySettingsCurrencyText"))
//         .evaluate()
//         .first
//         .widget as Text;
//     expect(selected.data, "USD");
//     expect(selected.style!.color, Color(0xFFF94167));
//
//     expect(find.text("Currency"), findsOneWidget);
//     expect(find.text("AUD", skipOffstage: false), findsOneWidget);
//     expect(find.text("CAD", skipOffstage: false), findsOneWidget);
//     expect(find.text("CHF", skipOffstage: false), findsOneWidget);
//     expect(find.text("CNY", skipOffstage: false), findsOneWidget);
//     expect(find.text("EUR", skipOffstage: false), findsOneWidget);
//     expect(find.text("GBP", skipOffstage: false), findsOneWidget);
//     expect(find.text("HKD", skipOffstage: false), findsOneWidget);
//     expect(find.text("INR", skipOffstage: false), findsOneWidget);
//     expect(find.text("JPY", skipOffstage: false), findsOneWidget);
//     expect(find.text("KRW", skipOffstage: false), findsOneWidget);
//     expect(find.text("PHP", skipOffstage: false), findsOneWidget);
//     expect(find.text("SGD", skipOffstage: false), findsOneWidget);
//     expect(find.text("TRY", skipOffstage: false), findsOneWidget);
//     expect(find.text("USD", skipOffstage: false), findsOneWidget);
//     expect(find.text("XAU", skipOffstage: false), findsOneWidget);
//
//     expect(find.byType(Text, skipOffstage: false), findsNWidgets(16));
//
//     expect(find.byType(CurrencyListSeparator, skipOffstage: false),
//         findsNWidgets(14));
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.fiatCurrency).called(1);
//
//     verifyNoMoreInteractions(manager);
//   });
//
//   testWidgets("tap back", (tester) async {
//     final manager = MockManager();
//     final navigator = mockingjay.MockNavigator();
//
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
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
//             ],
//             child: CurrencyView(),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byKey(Key("settingsAppBarBackButton")), findsOneWidget);
//     final selected = find
//         .byKey(Key("selectedCurrencySettingsCurrencyText"))
//         .evaluate()
//         .first
//         .widget as Text;
//     expect(selected.data, "USD");
//     expect(selected.style!.color, Color(0xFFF94167));
//
//     expect(find.text("Currency"), findsOneWidget);
//     expect(find.text("AUD", skipOffstage: false), findsOneWidget);
//     expect(find.text("CAD", skipOffstage: false), findsOneWidget);
//     expect(find.text("CHF", skipOffstage: false), findsOneWidget);
//     expect(find.text("CNY", skipOffstage: false), findsOneWidget);
//     expect(find.text("EUR", skipOffstage: false), findsOneWidget);
//     expect(find.text("GBP", skipOffstage: false), findsOneWidget);
//     expect(find.text("HKD", skipOffstage: false), findsOneWidget);
//     expect(find.text("INR", skipOffstage: false), findsOneWidget);
//     expect(find.text("JPY", skipOffstage: false), findsOneWidget);
//     expect(find.text("KRW", skipOffstage: false), findsOneWidget);
//     expect(find.text("PHP", skipOffstage: false), findsOneWidget);
//     expect(find.text("SGD", skipOffstage: false), findsOneWidget);
//     expect(find.text("TRY", skipOffstage: false), findsOneWidget);
//     expect(find.text("USD", skipOffstage: false), findsOneWidget);
//     expect(find.text("XAU", skipOffstage: false), findsOneWidget);
//
//     expect(find.byType(Text, skipOffstage: false), findsNWidgets(16));
//
//     expect(find.byType(CurrencyListSeparator, skipOffstage: false),
//         findsNWidgets(14));
//
//     await tester.tap(find.byKey(Key("settingsAppBarBackButton")));
//     await tester.pumpAndSettle();
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.fiatCurrency).called(2);
//
//     verifyNoMoreInteractions(manager);
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("separator", (tester) async {
//     final widget = CurrencyListSeparator();
//     await tester.pumpWidget(widget);
//     final container =
//         find.byType(Container).evaluate().first.widget as Container;
//     expect(container.color, Color(0xFFF0F3FA));
//     expect(widget.height, 1.0);
//   });
//
//   testWidgets("tap a currency that is not the current currency",
//       (tester) async {
//     final manager = MockManager();
//
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//     when(manager.changeFiatCurrency("CAD")).thenAnswer((_) {
//       manager.fiatCurrency;
//     });
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<Manager>(
//               create: (_) => manager,
//             ),
//           ],
//           child: CurrencyView(),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byKey(Key("settingsAppBarBackButton")), findsOneWidget);
//     final selected = find
//         .byKey(Key("selectedCurrencySettingsCurrencyText"))
//         .evaluate()
//         .first
//         .widget as Text;
//     expect(selected.data, "USD");
//     expect(selected.style!.color, Color(0xFFF94167));
//
//     expect(find.text("Currency"), findsOneWidget);
//     expect(find.text("AUD", skipOffstage: false), findsOneWidget);
//     expect(find.text("CAD", skipOffstage: false), findsOneWidget);
//     expect(find.text("CHF", skipOffstage: false), findsOneWidget);
//     expect(find.text("CNY", skipOffstage: false), findsOneWidget);
//     expect(find.text("EUR", skipOffstage: false), findsOneWidget);
//     expect(find.text("GBP", skipOffstage: false), findsOneWidget);
//     expect(find.text("HKD", skipOffstage: false), findsOneWidget);
//     expect(find.text("INR", skipOffstage: false), findsOneWidget);
//     expect(find.text("JPY", skipOffstage: false), findsOneWidget);
//     expect(find.text("KRW", skipOffstage: false), findsOneWidget);
//     expect(find.text("PHP", skipOffstage: false), findsOneWidget);
//     expect(find.text("SGD", skipOffstage: false), findsOneWidget);
//     expect(find.text("TRY", skipOffstage: false), findsOneWidget);
//     expect(find.text("USD", skipOffstage: false), findsOneWidget);
//     expect(find.text("XAU", skipOffstage: false), findsOneWidget);
//
//     expect(find.byType(Text, skipOffstage: false), findsNWidgets(16));
//
//     expect(find.byType(CurrencyListSeparator, skipOffstage: false),
//         findsNWidgets(14));
//
//     await tester.tap(find.byKey(Key("currencySelect_CAD")));
//     await tester.pumpAndSettle();
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.fiatCurrency).called(2);
//     verify(manager.changeFiatCurrency("CAD")).called(1);
//
//     verifyNoMoreInteractions(manager);
//   });
//
//   testWidgets("tap the currenct currency", (tester) async {
//     final manager = MockManager();
//
//     when(manager.fiatCurrency).thenAnswer((_) => "USD");
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<Manager>(
//               create: (_) => manager,
//             ),
//           ],
//           child: CurrencyView(),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byKey(Key("settingsAppBarBackButton")), findsOneWidget);
//     final selected = find
//         .byKey(Key("selectedCurrencySettingsCurrencyText"))
//         .evaluate()
//         .first
//         .widget as Text;
//     expect(selected.data, "USD");
//     expect(selected.style!.color, Color(0xFFF94167));
//
//     expect(find.text("Currency"), findsOneWidget);
//     expect(find.text("AUD", skipOffstage: false), findsOneWidget);
//     expect(find.text("CAD", skipOffstage: false), findsOneWidget);
//     expect(find.text("CHF", skipOffstage: false), findsOneWidget);
//     expect(find.text("CNY", skipOffstage: false), findsOneWidget);
//     expect(find.text("EUR", skipOffstage: false), findsOneWidget);
//     expect(find.text("GBP", skipOffstage: false), findsOneWidget);
//     expect(find.text("HKD", skipOffstage: false), findsOneWidget);
//     expect(find.text("INR", skipOffstage: false), findsOneWidget);
//     expect(find.text("JPY", skipOffstage: false), findsOneWidget);
//     expect(find.text("KRW", skipOffstage: false), findsOneWidget);
//     expect(find.text("PHP", skipOffstage: false), findsOneWidget);
//     expect(find.text("SGD", skipOffstage: false), findsOneWidget);
//     expect(find.text("TRY", skipOffstage: false), findsOneWidget);
//     expect(find.text("USD", skipOffstage: false), findsOneWidget);
//     expect(find.text("XAU", skipOffstage: false), findsOneWidget);
//
//     expect(find.byType(Text, skipOffstage: false), findsNWidgets(16));
//
//     expect(find.byType(CurrencyListSeparator, skipOffstage: false),
//         findsNWidgets(14));
//
//     await tester.tap(find.byKey(Key("currencySelect_USD")));
//     await tester.pumpAndSettle();
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.fiatCurrency).called(1);
//     // verify(manager.changeFiatCurrency("CAD")).called(1);
//
//     verifyNoMoreInteractions(manager);
//   });
}
