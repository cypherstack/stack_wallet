import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/exchange_view/trade_details_view.dart';
import 'package:stackwallet/providers/exchange/trade_note_service_provider.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/trades_service_provider.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';

import '../sample_data/theme_json.dart';
import '../screen_tests/exchange/exchange_view_test.mocks.dart';

/// Every asset getter resolves to a path flutter_svg will fail to load in a
/// test bundle; the widgets under test only need it to be non null.
class _FakeAssets implements IThemeAssets {
  @override
  String get bellNew => "";
  @override
  String get buy => "";
  @override
  String get exchange => "";
  @override
  String get personaIncognito => "";
  @override
  String get personaEasy => "";
  @override
  String get stack => "";
  @override
  String get stackIcon => "";
  @override
  String get receive => "";
  @override
  String get receivePending => "";
  @override
  String get receiveCancelled => "";
  @override
  String get send => "";
  @override
  String get sendPending => "";
  @override
  String get sendCancelled => "";
  @override
  String get themeSelector => "";
  @override
  String get themePreview => "";
  @override
  String get txExchange => "";
  @override
  String get txExchangePending => "";
  @override
  String get txExchangeFailed => "";
  @override
  String? get loadingGif => null;
  @override
  String? get background => null;
}

Trade _trade() => Trade(
  uuid: "uuid",
  tradeId: "tradeId",
  rateType: "fixed",
  direction: "direct",
  timestamp: DateTime.fromMillisecondsSinceEpoch(0),
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  payInCurrency: "zzz",
  payInAmount: "1",
  payInAddress: "payInAddress",
  payInNetwork: "zzz",
  payInExtraId: "",
  payInTxid: "",
  payOutCurrency: "zzz",
  payOutAmount: "1",
  payOutAddress: "payOutAddress",
  payOutNetwork: "zzz",
  payOutExtraId: "",
  payOutTxid: "",
  refundAddress: "refundAddress",
  refundExtraId: "",
  status: "finished",
  exchangeName: "ChangeNOW",
);

void main() {
  late MockPrefs prefs;
  late MockTradesService trades;
  late MockTradeNotesService notes;

  setUp(() {
    prefs = MockPrefs();
    trades = MockTradesService();
    notes = MockTradeNotesService();
    when(prefs.externalCalls).thenAnswer((_) => false);
    when(notes.getNote(tradeId: anyNamed("tradeId"))).thenAnswer((_) => "");

    var deleted = false;
    when(trades.get(any)).thenAnswer((_) => deleted ? null : _trade());
    when(
      trades.delete(
        trade: anyNamed("trade"),
        shouldNotifyListeners: anyNamed("shouldNotifyListeners"),
      ),
    ).thenAnswer((_) async => deleted = true);
  });

  tearDown(() => Util.screenWidth = null);

  Widget app(Widget home) => ProviderScope(
    overrides: [
      prefsChangeNotifierProvider.overrideWithProvider(
        ChangeNotifierProvider((_) => prefs),
      ),
      tradesServiceProvider.overrideWithProvider(
        ChangeNotifierProvider((_) => trades),
      ),
      tradeNoteServiceProvider.overrideWithProvider(
        ChangeNotifierProvider((_) => notes),
      ),
      themeAssetsProvider.overrideWithProvider(
        StateProvider((_) => _FakeAssets()),
      ),
      themeProvider.overrideWithProvider(
        StateProvider((_) => StackTheme.fromJson(json: lightThemeJsonMap)),
      ),
    ],
    child: MaterialApp(
      theme: ThemeData(
        extensions: [
          StackColors.fromStackColorTheme(
            StackTheme.fromJson(json: lightThemeJsonMap),
          ),
        ],
      ),
      home: home,
    ),
  );

  // Mirrors the production desktop hosts (desktop_trade_history.dart:128,
  // desktop_all_trades_view.dart:396, transactions_list.dart:114): the details
  // view lives in a nested Navigator owning a single route, inside a
  // showDialog route on the root navigator.
  Widget desktopNestedHost() => Builder(
    builder: (ctx) => Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => showDialog<void>(
            context: ctx,
            builder: (_) => Navigator(
              initialRoute: TradeDetailsView.routeName,
              onGenerateRoute: RouteGenerator.generateRoute,
              onGenerateInitialRoutes: (_, __) => [
                FadePageRoute(
                  const DesktopDialog(
                    maxHeight: null,
                    maxWidth: 580,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: SingleChildScrollView(
                            primary: false,
                            child: TradeDetailsView(
                              tradeId: "tradeId",
                              transactionIfSentFromStack: null,
                              walletName: null,
                              walletId: null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const RouteSettings(name: TradeDetailsView.routeName),
                ),
              ],
            ),
          ),
          child: const Text("open details"),
        ),
      ),
    ),
  );

  testWidgets("desktop delete dismisses the hosting dialog", (tester) async {
    expect(Util.isDesktop, isTrue, reason: "test host must be desktop");
    await tester.binding.setSurfaceSize(const Size(1400, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(app(desktopNestedHost()));
    // MaterialApp's own home route already owns one (transparent) barrier.
    final baselineBarriers = find.byType(ModalBarrier).evaluate().length;

    await tester.tap(find.text("open details"));
    await tester.pumpAndSettle();
    tester.takeException(); // missing svg assets
    expect(find.byType(TradeDetailsView), findsOneWidget);
    expect(find.byType(DesktopDialog), findsOneWidget);

    final deleteButton = find.widgetWithText(SecondaryButton, "Delete trade");
    await tester.ensureVisible(deleteButton);
    await tester.pumpAndSettle();
    tester.takeException();
    await tester.tap(deleteButton, warnIfMissed: false);
    await tester.pumpAndSettle();
    tester.takeException();
    expect(find.text("Delete this trade?"), findsOneWidget);

    await tester.tap(find.byKey(const Key("confirmDeleteTradeButton")));
    await tester.pumpAndSettle();
    tester.takeException();

    verify(
      trades.delete(
        trade: anyNamed("trade"),
        shouldNotifyListeners: anyNamed("shouldNotifyListeners"),
      ),
    ).called(1);

    expect(find.byType(DesktopDialog), findsNothing);
    expect(
      find.byType(ModalBarrier).evaluate().length,
      baselineBarriers,
      reason: "hosting showDialog route must have been dismissed",
    );
  });
}
