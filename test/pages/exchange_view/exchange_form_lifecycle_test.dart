import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart' as platform;
import 'package:stackwallet/models/exchange/aggregate_currency.dart';
import 'package:stackwallet/models/exchange/incomplete_exchange.dart';
import 'package:stackwallet/models/isar/exchange_cache/currency.dart';
import 'package:stackwallet/models/isar/exchange_cache/pair.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/exchange_view/exchange_form.dart';
import 'package:stackwallet/providers/exchange/exchange_form_state_provider.dart';
import 'package:stackwallet/providers/global/locale_provider.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/services/exchange/change_now/change_now_exchange.dart';
import 'package:stackwallet/services/locale_service.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_service.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/utilities/enums/exchange_rate_type_enum.dart';
import 'package:tuple/tuple.dart';

import '../../sample_data/theme_json.dart';

class _ThemeService extends Mock implements ThemeService {}

class _Prefs extends Mock implements Prefs {
  @override
  bool get useTor => false;
}

class _LocaleService extends LocaleService {
  @override
  String get locale => 'en_US';
}

class _Headers extends Mock implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void forEach(void Function(String, List<String>) action) {}
}

class _Response extends Mock implements HttpClientResponse {
  _Response(Map<String, dynamic> body)
    : _body = Stream.value(utf8.encode(jsonEncode(body)));

  final Stream<List<int>> _body;

  @override
  int get statusCode => 200;

  @override
  HttpHeaders get headers => _Headers();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _body.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
}

class _PendingRequest {
  _PendingRequest(this.uri);

  final Uri uri;
  final response = Completer<HttpClientResponse>();

  bool get isEstimate => uri.path.endsWith('/estimated-amount');

  void complete({int amount = 2}) {
    response.complete(
      _Response(
        isEstimate
            ? {
                'fromCurrency': uri.queryParameters['fromCurrency'],
                'fromNetwork': uri.queryParameters['fromNetwork'],
                'toCurrency': uri.queryParameters['toCurrency'],
                'toNetwork': uri.queryParameters['toNetwork'],
                'fromAmount': uri.queryParameters['fromAmount'] ?? '1',
                'toAmount': '$amount',
                'flow': uri.queryParameters['flow'],
                'type': uri.queryParameters['type'],
                'depositFee': '0',
                'withdrawalFee': '0',
              }
            : {'minAmount': '0.1', 'maxAmount': '100'},
      ),
    );
  }
}

class _Request extends Mock implements HttpClientRequest {
  _Request(this.pending);

  final _PendingRequest pending;

  @override
  HttpHeaders get headers => _Headers();

  @override
  Future<HttpClientResponse> close() => pending.response.future;
}

class _HttpClient extends Mock implements HttpClient {
  _HttpClient(this.requests);

  final List<_PendingRequest> requests;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    final pending = _PendingRequest(url);
    requests.add(pending);
    return _Request(pending);
  }

  @override
  void close({bool force = false}) {}
}

class _HttpOverrides extends HttpOverrides {
  final requests = <_PendingRequest>[];

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _HttpClient(requests);

  Future<void> completeQuote(
    WidgetTester tester,
    _PendingRequest range, {
    int amount = 2,
  }) async {
    final previousCount = requests.length;
    range.complete();
    await tester.pump();
    // A retired/superseded request stops after its range; the old implementation
    // still asks for an estimate, which we complete to avoid stranded tests.
    for (final request in requests.skip(previousCount)) {
      expect(request.isEstimate, isTrue);
      request.complete(amount: amount);
    }
    await tester.pump();
  }
}

const _first = ValueKey('first form');
const _second = ValueKey('second form');

AggregateCurrency _currency(String ticker, String exchange) =>
    AggregateCurrency(
      exchangeCurrencyPairs: [
        Tuple2(
          exchange,
          Currency(
            exchangeName: exchange,
            ticker: ticker,
            name: ticker,
            network: ticker.toLowerCase(),
            image: '',
            isFiat: false,
            rateType: SupportedRateType.both,
            isStackCoin: false,
            tokenContract: null,
          ),
        ),
      ],
    );

class _Harness {
  _Harness({required bool quotes}) {
    final themeService = _ThemeService();
    when(themeService.getTheme(themeId: 'light')).thenReturn(theme);
    container = ProviderContainer(
      overrides: [
        pThemeService.overrideWithValue(themeService),
        prefsChangeNotifierProvider.overrideWithValue(_Prefs()),
        localeServiceChangeNotifierProvider.overrideWithValue(_LocaleService()),
      ],
    );
    addTearDown(container.dispose);
    setPair(quotes: quotes);
    container.read(efSendAmountProvider.notifier).state = quotes
        ? Decimal.one
        : null;
  }

  void setPair({required bool quotes}) {
    final exchange = quotes ? ChangeNowExchange.exchangeName : 'Majestic Bank';
    container.read(efCurrencyPairProvider)
      ..setSend(_currency('UNKNOWN', exchange))
      ..setReceive(_currency('RECEIVE', exchange));
  }

  final theme = StackTheme.fromJson(json: lightThemeJsonMap);
  late final ProviderContainer container;
  Object? navigationArguments;
  bool _surfaceSet = false;

  bool get refreshing => container.read(efRefreshingProvider);

  Decimal? get estimate => container
      .read(efEstimatesListProvider(ChangeNowExchange.exchangeName))
      ?.item1
      .value
      ?.single
      .estimatedAmount;

  Future<void> pump(WidgetTester tester, List<Key> keys) async {
    if (!_surfaceSet) {
      _surfaceSet = true;
      await tester.binding.setSurfaceSize(const Size(1200, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
    }
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          onGenerateRoute: (settings) {
            navigationArguments = settings.arguments;
            return MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('Next exchange step')),
            );
          },
          theme: ThemeData(
            extensions: [StackColors.fromStackColorTheme(theme)],
          ),
          home: Scaffold(
            body: Column(
              children: [for (final key in keys) ExchangeForm(key: key)],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> update(WidgetTester tester, Key key) {
    final dynamic state = tester.state(find.byKey(key));
    return state.update() as Future<void>;
  }
}

void main() {
  test('a loading listener can begin a replacement refresh', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(efRefreshingProvider.notifier);
    final first = Object();
    final second = Object();
    controller.begin(first);
    controller.addListener((loading) {
      if (!loading) controller.begin(second);
    }, fireImmediately: false);
    controller.finish(first);
    expect(container.read(efRefreshingProvider), isTrue);
    expect(controller.owns(second), isTrue);
    // Repeated cleanup for the previous request must leave the successor alone.
    controller.finish(first);
    expect(container.read(efRefreshingProvider), isTrue);
  });

  testWidgets('reopening clears a retired form refresh', (tester) async {
    final harness = _Harness(quotes: false);
    await harness.pump(tester, [_first]);
    await harness.update(tester, _first);
    expect(harness.refreshing, isTrue);
    await harness.pump(tester, []);
    await harness.pump(tester, [_second]);
    await tester.pump(const Duration(seconds: 5));
    expect(harness.refreshing, isFalse);
  });

  for (final duringEstimate in [false, true]) {
    testWidgets(
      'disposal during ${duringEstimate ? 'estimate' : 'range'} clears refresh',
      (tester) async {
        final http = _HttpOverrides();
        await HttpOverrides.runWithHttpOverrides(() async {
          final harness = _Harness(quotes: true);
          await harness.pump(tester, [_first]);
          final Future<void> pending = harness.update(tester, _first);
          await tester.pump();
          expect(http.requests, hasLength(1));
          if (duringEstimate) {
            http.requests.single.complete();
            await tester.pump();
            expect(http.requests, hasLength(2));
          }
          final request = http.requests.last;
          await harness.pump(tester, []);
          expect(harness.refreshing, isFalse);
          request.complete();
          await pending;
          await tester.pump();
          expect(harness.estimate, isNull);
          expect(tester.takeException(), isNull);
        }, http);
      },
    );
  }

  testWidgets('latest quote finishes while an older quote is pending', (
    tester,
  ) async {
    final http = _HttpOverrides();
    await HttpOverrides.runWithHttpOverrides(() async {
      final harness = _Harness(quotes: true);
      await harness.pump(tester, [_first]);
      final Future<void> older = harness.update(tester, _first);
      await tester.pump();
      final firstRange = http.requests.single;
      final Future<void> newer = harness.update(tester, _first);
      await tester.pump();
      await http.completeQuote(tester, http.requests.last, amount: 2);
      await newer;
      await tester.pump();
      expect(harness.refreshing, isFalse);
      expect(harness.estimate, Decimal.fromInt(2));
      await http.completeQuote(tester, firstRange, amount: 99);
      await older;
      await tester.pump();
      expect(harness.estimate, Decimal.fromInt(2));
    }, http);
  });

  testWidgets('estimated output updates while its read-only field has focus', (
    tester,
  ) async {
    final http = _HttpOverrides();
    await HttpOverrides.runWithHttpOverrides(() async {
      final harness = _Harness(quotes: true);
      await harness.pump(tester, [_first]);
      final pending = harness.update(tester, _first);
      await tester.pump();
      final range = http.requests.single;
      final receiveField = find.byType(TextField).last;
      await tester.tap(receiveField);
      await tester.pump();
      expect(tester.widget<TextField>(receiveField).readOnly, isTrue);
      expect(harness.container.read(efReversedProvider), isFalse);

      await http.completeQuote(tester, range, amount: 6);
      await pending;
      await tester.pump();

      expect(harness.refreshing, isFalse);
      expect(
        harness.container.read(efReceiveAmountProvider),
        Decimal.fromInt(6),
      );
      final field = tester.widget<TextField>(receiveField);
      expect(field.focusNode!.hasFocus, isTrue);
      expect(field.controller!.text, '6');
    }, http);
  });

  for (final reversed in [false, true]) {
    testWidgets(
      'a completed quote preserves ${reversed ? 'receive' : 'send'} text '
      'edited during debounce',
      (tester) async {
        final http = _HttpOverrides();
        await HttpOverrides.runWithHttpOverrides(() async {
          final harness = _Harness(quotes: true);
          if (reversed) {
            harness.container.read(efRateTypeProvider.notifier).state =
                ExchangeRateType.fixed;
            harness.container.read(efReversedProvider.notifier).state = true;
            harness.container.read(efReceiveAmountProvider.notifier).state =
                Decimal.one;
          }
          await harness.pump(tester, [_first]);
          final pending = harness.update(tester, _first);
          await tester.pump();
          final range = http.requests.single;
          final field = reversed
              ? find.byType(TextField).last
              : find.byType(TextField).first;
          await tester.tap(field);
          await tester.pump();
          await tester.enterText(field, '3.12000001');
          final controller = tester.widget<TextField>(field).controller!;
          controller.selection = const TextSelection.collapsed(offset: 3);
          await http.completeQuote(tester, range);
          await pending;
          await tester.pump();
          expect(
            tester.widget<TextField>(field).controller!.text,
            '3.12000001',
          );
          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 3),
          );
          await tester.pump(const Duration(milliseconds: 1500));
          expect(
            harness.container.read(
              reversed ? efReceiveAmountProvider : efSendAmountProvider,
            ),
            Decimal.parse('3.12000001'),
          );
          await http.completeQuote(tester, http.requests.last);
          await tester.pumpWidget(const SizedBox.shrink());
          expect(tester.takeException(), isNull);
        }, http);
      },
    );
  }

  testWidgets('swap commits pending text and waits for its refreshed quote', (
    tester,
  ) async {
    final previousPlatform = Util.layoutPlatform;
    Util.layoutPlatform = platform.FakePlatform(operatingSystem: 'android');
    addTearDown(() => Util.layoutPlatform = previousPlatform);
    final http = _HttpOverrides();
    await HttpOverrides.runWithHttpOverrides(() async {
      final harness = _Harness(quotes: true);
      await harness.pump(tester, [_first]);
      final first = harness.update(tester, _first);
      await tester.pump();
      await http.completeQuote(tester, http.requests.single);
      await first;
      await tester.pump();
      final sendField = find.byType(TextField).first;
      await tester.tap(sendField);
      await tester.pump();
      await tester.enterText(sendField, '3.12000001');
      await tester.tap(find.text('Swap'));
      await tester.pump();
      expect(harness.navigationArguments, isNull);
      final range = http.requests.last;
      range.complete();
      await tester.pump();
      final estimate = http.requests.last;
      expect(estimate.isEstimate, isTrue);
      expect(estimate.uri.queryParameters['fromAmount'], '3.12000001');
      expect(harness.navigationArguments, isNull);
      estimate.complete(amount: 6);
      await tester.pumpAndSettle();
      final model = harness.navigationArguments as IncompleteExchangeModel;
      expect(model.sendAmount, Decimal.parse('3.12000001'));
      expect(model.receiveAmount, Decimal.fromInt(6));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }, http);
  });

  testWidgets('older live form cannot publish or clear a newer form quote', (
    tester,
  ) async {
    final http = _HttpOverrides();
    await HttpOverrides.runWithHttpOverrides(() async {
      final harness = _Harness(quotes: true);
      await harness.pump(tester, [_first, _second]);
      final Future<void> older = harness.update(tester, _first);
      await tester.pump();
      final firstRange = http.requests.single;
      final Future<void> newer = harness.update(tester, _second);
      await tester.pump();
      final secondRange = http.requests.last;
      await http.completeQuote(tester, firstRange, amount: 99);
      await older;
      await tester.pump();
      expect(harness.refreshing, isTrue);
      expect(harness.estimate, isNull);
      await http.completeQuote(tester, secondRange, amount: 2);
      await newer;
      await tester.pump();
      expect(harness.refreshing, isFalse);
      expect(harness.estimate, Decimal.fromInt(2));
    }, http);
  });

  testWidgets('older estimate cannot replace a newer live form result', (
    tester,
  ) async {
    final http = _HttpOverrides();
    await HttpOverrides.runWithHttpOverrides(() async {
      final harness = _Harness(quotes: true);
      await harness.pump(tester, [_first, _second]);
      final older = harness.update(tester, _first);
      await tester.pump();
      http.requests.single.complete();
      await tester.pump();
      final firstEstimate = http.requests.last;
      expect(firstEstimate.isEstimate, isTrue);
      final newer = harness.update(tester, _second);
      await tester.pump();
      await http.completeQuote(tester, http.requests.last, amount: 2);
      await newer;
      await tester.pump();
      expect(harness.estimate, Decimal.fromInt(2));
      firstEstimate.complete(amount: 99);
      await older;
      await tester.pump();
      expect(harness.estimate, Decimal.fromInt(2));
      expect(harness.refreshing, isFalse);
    }, http);
  });

  testWidgets('retired owner cannot clear an active replacement quote', (
    tester,
  ) async {
    final http = _HttpOverrides();
    await HttpOverrides.runWithHttpOverrides(() async {
      final harness = _Harness(quotes: true);
      await harness.pump(tester, [_first, _second]);
      final Future<void> older = harness.update(tester, _first);
      await tester.pump();
      final firstRange = http.requests.single;
      final Future<void> newer = harness.update(tester, _second);
      await tester.pump();
      final secondRange = http.requests.last;
      await harness.pump(tester, [_second]);
      expect(harness.refreshing, isTrue);
      firstRange.complete();
      await older;
      await tester.pump();
      expect(harness.refreshing, isTrue);
      await http.completeQuote(tester, secondRange);
      await newer;
      await tester.pump();
      expect(harness.refreshing, isFalse);
    }, http);
  });

  testWidgets('queued cleanup cannot clear another live form quote', (
    tester,
  ) async {
    final http = _HttpOverrides();
    await HttpOverrides.runWithHttpOverrides(() async {
      final harness = _Harness(quotes: false);
      await harness.pump(tester, [_first, _second]);
      await harness.update(tester, _first);
      // Retain the first form's pending cleanup while a second form starts.
      harness.setPair(quotes: true);
      harness.container.read(efSendAmountProvider.notifier).state = Decimal.one;
      final Future<void> newer = harness.update(tester, _second);
      await tester.pump();
      expect(harness.refreshing, isTrue);
      await http.completeQuote(tester, http.requests.single);
      await newer;
      await tester.pump();
      expect(harness.refreshing, isFalse);
    }, http);
  });

  testWidgets('queued cleanup ignores a disposed provider container', (
    tester,
  ) async {
    final harness = _Harness(quotes: false);
    await harness.pump(tester, [_first]);
    await harness.update(tester, _first);
    harness.container.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}
