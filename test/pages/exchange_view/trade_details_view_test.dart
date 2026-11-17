import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/exchange_view/trade_details_view.dart';
import 'package:stackwallet/providers/exchange/trade_note_service_provider.dart';
import 'package:stackwallet/providers/global/locale_provider.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/trades_service_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/services/exchange/exolix/exolix_exchange.dart';
import 'package:stackwallet/services/locale_service.dart';
import 'package:stackwallet/services/trade_notes_service.dart';
import 'package:stackwallet/services/trade_service.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_service.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

import '../../sample_data/theme_json.dart';

class _ThemeService extends Mock implements ThemeService {}

class _Prefs extends Mock implements Prefs {
  _Prefs(this.unit);

  final AmountUnit unit;

  @override
  bool get externalCalls => false;

  @override
  bool get useTor => false;

  @override
  AmountUnit amountUnit(CryptoCurrency coin) => unit;

  @override
  int maxDecimals(CryptoCurrency coin) => 8;
}

class _LocaleService extends LocaleService {
  @override
  String get locale => 'en_US';
}

class _Trades extends TradesService {
  _Trades(this._trades);

  final List<Trade> _trades;

  @override
  List<Trade> get trades => _trades;
}

class _Notes extends TradeNotesService {
  @override
  String getNote({required String tradeId}) => "";
}

Trade _trade({required String payInCurrency}) => Trade(
  uuid: "uuid",
  tradeId: "trade-1",
  rateType: "estimated",
  direction: "direct",
  timestamp: DateTime.utc(2026, 11, 15),
  updatedAt: DateTime.utc(2026, 11, 15),
  payInCurrency: payInCurrency,
  payInAmount: "0.02",
  payInAddress: "deposit-address",
  payInNetwork: "",
  payInExtraId: "",
  payInTxid: "",
  payOutCurrency: "ETH",
  payOutAmount: "0.7",
  payOutAddress: "payout-address",
  payOutNetwork: "",
  payOutExtraId: "",
  payOutTxid: "",
  refundAddress: "refund-address",
  refundExtraId: "",
  status: "Waiting",
  exchangeName: ExolixExchange.exchangeName,
);

Future<void> _pump(
  WidgetTester tester,
  Trade trade, {
  AmountUnit unit = AmountUnit.normal,
}) async {
  // The full details layout does not fit the default 800x600 test surface.
  tester.view.physicalSize = const Size(1400, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final theme = StackTheme.fromJson(json: lightThemeJsonMap);
  final themeService = _ThemeService();
  when(themeService.getTheme(themeId: 'light')).thenReturn(theme);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pThemeService.overrideWithValue(themeService),
        prefsChangeNotifierProvider.overrideWithValue(_Prefs(unit)),
        localeServiceChangeNotifierProvider.overrideWithValue(_LocaleService()),
        tradesServiceProvider.overrideWithValue(_Trades([trade])),
        tradeNoteServiceProvider.overrideWithValue(_Notes()),
        pWallets.overrideWithValue(Wallets.sharedInstance),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: [StackColors.fromStackColorTheme(theme)]),
        home: TradeDetailsView(
          tradeId: trade.tradeId,
          transactionIfSentFromStack: null,
          walletId: null,
          walletName: null,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets("shows the pay-in ticker once for a known coin", (tester) async {
    await _pump(tester, _trade(payInCurrency: "BTC"));

    expect(find.text("-0.02000000 BTC"), findsOneWidget);
    expect(find.textContaining("BTC BTC"), findsNothing);
  });

  testWidgets("shows the user's display unit instead of the ticker", (
    tester,
  ) async {
    await _pump(tester, _trade(payInCurrency: "BTC"), unit: AmountUnit.nano);

    // 0.02 BTC in sats; the ticker must not be appended to a shifted amount.
    expect(find.textContaining(RegExp(r"^-[\d,]+ sats$")), findsOneWidget);
    expect(find.textContaining(RegExp(r"^-.*BTC")), findsNothing);
  });

  testWidgets("shows the pay-in ticker for an unknown coin", (tester) async {
    await _pump(tester, _trade(payInCurrency: "FOO"));

    expect(find.text("-0.02000000 FOO"), findsOneWidget);
  });
}
