import 'package:mockito/annotations.dart';
import 'package:stackwallet/services/change_now/change_now.dart';
import 'package:stackwallet/services/trade_notes_service.dart';
import 'package:stackwallet/services/trade_service.dart';
import 'package:stackwallet/utilities/prefs.dart';

@GenerateMocks([Prefs, TradesService, TradeNotesService, ChangeNow])
void main() {
  // testWidgets("ExchangeView builds correctly with no trade history",
  //     (widgetTester) async {
  //   final prefs = MockPrefs();
  //   final tradeService = MockTradesService();
  //
  //   when(prefs.exchangeRateType)
  //       .thenAnswer((realInvocation) => ExchangeRateType.estimated);
  //
  //   when(tradeService.trades).thenAnswer((realInvocation) => []);
  //
  //   await widgetTester.pumpWidget(
  //     ProviderScope(
  //       overrides: [
  //         prefsChangeNotifierProvider
  //             .overrideWithProvider(ChangeNotifierProvider((ref) => prefs)),
  //         tradesServiceProvider.overrideWithProvider(
  //             ChangeNotifierProvider((ref) => tradeService)),
  //       ],
  //       child: const MaterialApp(
  //         home: Material(child: ExchangeView()),
  //       ),
  //     ),
  //   );
  //
  //   await widgetTester.pumpAndSettle();
  //
  //   expect(find.byType(TextFormField), findsNWidgets(2));
  //   expect(find.byType(SvgPicture), findsNWidgets(6));
  //
  //   expect(find.text("You will send"), findsOneWidget);
  //   expect(find.text("You will receive"), findsOneWidget);
  //   expect(find.text("Exchange"), findsOneWidget);
  //   expect(find.text("Estimated rate"), findsOneWidget);
  //   expect(find.text("Trades"), findsOneWidget);
  //   expect(find.text("-"), findsNWidgets(2));
  //
  //   expect(find.text("Trades will appear here"), findsOneWidget);
  //
  //   expect(find.byType(TextButton), findsNWidgets(2));
  //   expect(find.byType(TradeCard), findsNothing);
  // });
  //
  // testWidgets("ExchangeView builds correctly with one trade history",
  //     (widgetTester) async {
  //   final prefs = MockPrefs();
  //   final tradeService = MockTradesService();
  //
  //   when(prefs.exchangeRateType)
  //       .thenAnswer((realInvocation) => ExchangeRateType.estimated);
  //
  //   when(tradeService.trades).thenAnswer((realInvocation) => [
  //         ExchangeTransaction(
  //             id: "some id",
  //             payinAddress: "adr",
  //             payoutAddress: "adr2",
  //             payinExtraId: "",
  //             payoutExtraId: "",
  //             fromCurrency: "btc",
  //             toCurrency: "xmr",
  //             amount: "42",
  //             refundAddress: "",
  //             refundExtraId: "refundExtraId",
  //             payoutExtraIdName: "",
  //             uuid: "dhjkfg872tr8yugsd",
  //             date: DateTime(1999),
  //             statusString: "Waiting",
  //             statusObject: null)
  //       ]);
  //
  //   await widgetTester.pumpWidget(
  //     ProviderScope(
  //       overrides: [
  //         prefsChangeNotifierProvider
  //             .overrideWithProvider(ChangeNotifierProvider((ref) => prefs)),
  //         tradesServiceProvider.overrideWithProvider(
  //             ChangeNotifierProvider((ref) => tradeService)),
  //       ],
  //       child: const MaterialApp(
  //         home: Material(child: ExchangeView()),
  //       ),
  //     ),
  //   );
  //
  //   await widgetTester.pumpAndSettle();
  //
  //   expect(find.byType(TextFormField), findsNWidgets(2));
  //   expect(find.byType(SvgPicture), findsNWidgets(7));
  //
  //   expect(find.text("You will send"), findsOneWidget);
  //   expect(find.text("You will receive"), findsOneWidget);
  //   expect(find.text("Exchange"), findsOneWidget);
  //   expect(find.text("Estimated rate"), findsOneWidget);
  //   expect(find.text("Trades"), findsOneWidget);
  //   expect(find.text("-"), findsNWidgets(2));
  //
  //   expect(find.text("Trades will appear here"), findsNothing);
  //
  //   expect(find.byType(TextButton), findsNWidgets(2));
  //   expect(find.byType(TradeCard), findsOneWidget);
  // });
}
