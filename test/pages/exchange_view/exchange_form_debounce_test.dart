import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/models/exchange/aggregate_currency.dart';
import 'package:stackwallet/models/isar/exchange_cache/currency.dart';
import 'package:stackwallet/models/isar/exchange_cache/pair.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/exchange_view/exchange_form.dart';
import 'package:stackwallet/providers/exchange/exchange_form_state_provider.dart';
import 'package:stackwallet/providers/global/locale_provider.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/services/locale_service.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_service.dart';
import 'package:stackwallet/utilities/enums/exchange_rate_type_enum.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:tuple/tuple.dart';

import '../../sample_data/theme_json.dart';

class _MockThemeService extends Mock implements ThemeService {}

class _MockPrefs extends Mock implements Prefs {
  @override
  bool get useTor => false;
}

class _TestLocaleService extends LocaleService {
  String _testLocale = "en_US";

  @override
  String get locale => _testLocale;

  void setLocale(String locale) {
    _testLocale = locale;
    notifyListeners();
  }
}

void main() {
  // A recognized legacy exchange name that ExchangeForm does not query.
  const testExchangeName = "Majestic Bank";

  AggregateCurrency currency(String ticker) {
    return AggregateCurrency(
      exchangeCurrencyPairs: [
        Tuple2(
          testExchangeName,
          Currency(
            exchangeName: testExchangeName,
            ticker: ticker,
            name: ticker,
            network: ticker.toLowerCase(),
            image: "",
            isFiat: false,
            rateType: SupportedRateType.both,
            isStackCoin: false,
            tokenContract: null,
          ),
        ),
      ],
    );
  }

  Future<ProviderContainer> pumpForm(
    WidgetTester tester, {
    AggregateCurrency? receive,
    Decimal? sendAmount,
    Decimal? receiveAmount,
    bool fixedRate = false,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final stackTheme = StackTheme.fromJson(json: lightThemeJsonMap);
    final themeService = _MockThemeService();
    when(themeService.getTheme(themeId: "light")).thenReturn(stackTheme);
    final prefs = _MockPrefs();
    final localeService = _TestLocaleService();
    final container = ProviderContainer(
      overrides: [
        pThemeService.overrideWithValue(themeService),
        prefsChangeNotifierProvider.overrideWithValue(prefs),
        localeServiceChangeNotifierProvider.overrideWithValue(localeService),
      ],
    );
    addTearDown(container.dispose);
    if (fixedRate) {
      container.read(efRateTypeProvider.notifier).state =
          ExchangeRateType.fixed;
    }
    container.read(efSendAmountProvider.notifier).state = sendAmount;
    container.read(efReceiveAmountProvider.notifier).state = receiveAmount;
    final pair = container.read(efCurrencyPairProvider);
    pair.setSend(currency("UNKNOWN"));
    pair.setReceive(receive);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData(
            extensions: [StackColors.fromStackColorTheme(stackTheme)],
          ),
          home: const Scaffold(body: ExchangeForm()),
        ),
      ),
    );
    await tester.pump();
    return container;
  }

  Future<(ProviderContainer, Finder, Finder)> enterBothAmountsWithinDebounce(
    WidgetTester tester,
  ) async {
    final container = await pumpForm(
      tester,
      receive: currency("RECEIVE"),
      sendAmount: Decimal.one,
      receiveAmount: Decimal.fromInt(2),
      fixedRate: true,
    );
    final sendField = find.byType(TextField).first;
    final receiveField = find.byType(TextField).last;

    await tester.tap(sendField);
    await tester.pump();
    await tester.enterText(sendField, "3.12345678");

    await tester.tap(receiveField);
    await tester.pump();
    // The focus-driven provider refresh runs on the following frame and may
    // rewrite the unfocused send controller from its still-stale provider.
    await tester.pump();
    await tester.enterText(receiveField, "4.87654321");

    return (container, sendField, receiveField);
  }

  testWidgets("currency change cancels stale amount debounce", (tester) async {
    final container = await pumpForm(tester);
    final pair = container.read(efCurrencyPairProvider);

    final sendField = find.byType(TextField).first;
    await tester.tap(sendField);
    await tester.pump();
    await tester.enterText(sendField, "1.12345678");
    FocusManager.instance.primaryFocus?.unfocus();

    pair.setSend(currency("LOW"), notifyListeners: true);
    await tester.pump();

    expect(container.read(efSendAmountProvider), Decimal.parse("1.12345678"));
    expect(tester.widget<TextField>(sendField).controller!.text, "1.12345678");

    await tester.pump(const Duration(seconds: 2));

    expect(container.read(efSendAmountProvider), Decimal.parse("1.12345678"));
    expect(tester.widget<TextField>(sendField).controller!.text, "1.12345678");
  });

  testWidgets("swap commits amount before canceling its debounce", (
    tester,
  ) async {
    final container = await pumpForm(tester, receive: currency("LOW"));

    final sendField = find.byType(TextField).first;
    await tester.tap(sendField);
    await tester.pump();
    await tester.enterText(sendField, "1.12345678");

    await tester.tap(
      find.bySemanticsLabel("Swap Button. Reverse The Exchange Currencies."),
    );
    await tester.pump();

    expect(
      container.read(efReceiveAmountProvider),
      Decimal.parse("1.12345678"),
    );

    await tester.pump(const Duration(seconds: 2));

    expect(
      container.read(efReceiveAmountProvider),
      Decimal.parse("1.12345678"),
    );
  });

  testWidgets("exchange input remains limited to eight fractional digits", (
    tester,
  ) async {
    final container = await pumpForm(tester);
    final sendField = find.byType(TextField).first;

    await tester.tap(sendField);
    await tester.pump();
    await tester.enterText(sendField, "1.12345678");
    await tester.enterText(sendField, "1.123456789");

    expect(tester.widget<TextField>(sendField).controller!.text, "1.12345678");

    await tester.pump(const Duration(seconds: 2));

    expect(container.read(efSendAmountProvider), Decimal.parse("1.12345678"));
  });

  testWidgets("swap preserves pending edits from both amount fields", (
    tester,
  ) async {
    final (container, _, _) = await enterBothAmountsWithinDebounce(tester);

    await tester.tap(
      find.bySemanticsLabel("Swap Button. Reverse The Exchange Currencies."),
    );
    await tester.pump();

    expect(container.read(efSendAmountProvider), Decimal.parse("4.87654321"));
    expect(
      container.read(efReceiveAmountProvider),
      Decimal.parse("3.12345678"),
    );
  });

  testWidgets("currency change preserves pending edits from both fields", (
    tester,
  ) async {
    final (container, _, _) = await enterBothAmountsWithinDebounce(tester);

    container
        .read(efCurrencyPairProvider)
        .setReceive(currency("NEXT"), notifyListeners: true);
    await tester.pump();

    expect(container.read(efSendAmountProvider), Decimal.parse("3.12345678"));
    expect(
      container.read(efReceiveAmountProvider),
      Decimal.parse("4.87654321"),
    );

    await tester.pump(const Duration(seconds: 2));

    expect(container.read(efSendAmountProvider), Decimal.parse("3.12345678"));
    expect(
      container.read(efReceiveAmountProvider),
      Decimal.parse("4.87654321"),
    );
  });

  testWidgets("locale change relocalizes and flushes pending user text", (
    tester,
  ) async {
    final container = await pumpForm(tester);
    final sendField = find.byType(TextField).first;

    await tester.tap(sendField);
    await tester.pump();
    await tester.enterText(sendField, "3.12000001");

    (container.read(localeServiceChangeNotifierProvider) as _TestLocaleService)
        .setLocale("de_DE");
    await tester.pump();
    await tester.pump();

    final amount = container.read(efSendAmountProvider);
    expect(amount, Decimal.parse("3.12000001"));
    expect(amount?.scale, 8);
    expect(tester.widget<TextField>(sendField).controller!.text, "3,12000001");

    await tester.pump(const Duration(seconds: 2));

    expect(container.read(efSendAmountProvider), amount);
  });
}
