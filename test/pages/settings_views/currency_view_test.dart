import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart' as platform;
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/currency_view.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/price_provider.dart';
import 'package:stackwallet/services/price_service.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/utilities/util.dart';

import '../../sample_data/theme_json.dart';

class _TestPrefs extends ChangeNotifier implements Prefs {
  String _currency = 'USD';

  @override
  String get currency => _currency;

  @override
  set currency(String value) {
    _currency = value;
    notifyListeners();
  }

  @override
  bool get externalCalls => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PollingPriceService extends PriceService {
  _PollingPriceService(super.baseTicker);
  int requests = 0;

  @override
  Future<void> updatePrice() async {
    requests++;
  }
}

class _PollingTimer implements Timer {
  @override
  bool isActive = true;

  @override
  int get tick => 0;

  @override
  void cancel() => isActive = false;
}

void main() {
  test('a preference change outside settings preserves provider polling', () {
    final timers = <_PollingTimer>[];
    runZoned(
      () {
        final prefs = _TestPrefs();
        final container = ProviderContainer(
          overrides: [prefsChangeNotifierProvider.overrideWithValue(prefs)],
        );
        final previous = container.read(priceAnd24hChangeNotifierProvider);
        previous.start(false);
        expect(timers.where((timer) => timer.isActive), hasLength(1));

        prefs.currency = 'EUR';
        final current = container.read(priceAnd24hChangeNotifierProvider);
        expect(current.baseTicker, 'EUR');
        expect(timers.where((timer) => timer.isActive), hasLength(1));
        container.dispose();
        expect(timers.where((timer) => timer.isActive), isEmpty);
      },
      zoneSpecification: ZoneSpecification(
        createPeriodicTimer: (self, parent, zone, duration, callback) {
          final timer = _PollingTimer();
          timers.add(timer);
          return timer;
        },
      ),
    );
  });

  testWidgets('starting after provider polling fetches once with one timer', (
    tester,
  ) async {
    final service = _PollingPriceService('USD');
    service.start(false);
    expect(service.requests, 0);
    service.start(true);
    expect(service.requests, 1);
    await tester.pump(service.updateInterval);
    expect(service.requests, 2);
    service.dispose();
  });

  for (final desktop in [false, true]) {
    testWidgets(
      '${desktop ? 'desktop' : 'mobile'} currency change keeps polling',
      (tester) async {
        final previousPlatform = Util.layoutPlatform;
        final previousWidth = Util.screenWidth;
        final previousIsIpad = Util.isIpad;
        Util.layoutPlatform = platform.FakePlatform(
          operatingSystem: desktop ? 'macos' : 'android',
        );
        Util.screenWidth = null;
        Util.isIpad = false;
        addTearDown(() {
          Util.layoutPlatform = previousPlatform;
          Util.screenWidth = previousWidth;
          Util.isIpad = previousIsIpad;
        });
        final prefs = _TestPrefs();
        final theme = StackTheme.fromJson(json: lightThemeJsonMap);
        final container = ProviderContainer(
          overrides: [
            prefsChangeNotifierProvider.overrideWithValue(prefs),
            themeProvider.overrideWithProvider(
              StateProvider<StackTheme>((ref) => theme),
            ),
            priceAnd24hChangeNotifierProvider.overrideWithProvider(
              ChangeNotifierProvider<PriceService>((ref) {
                return _PollingPriceService(
                  ref.watch(
                    prefsChangeNotifierProvider.select((p) => p.currency),
                  ),
                );
              }),
            ),
          ],
        );
        addTearDown(container.dispose);
        final previousService = container.read(
          priceAnd24hChangeNotifierProvider,
        ) as _PollingPriceService;
        previousService.start(false);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: ThemeData(
                extensions: [StackColors.fromStackColorTheme(theme)],
              ),
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const Scaffold(body: BaseCurrencySettingsView()),
                      ),
                    ),
                    child: const Text('Open currencies'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open currencies'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'EUR');
        await tester.pump();
        await tester.tap(
          find.byWidgetPredicate(
            (widget) => widget is Text && widget.data == 'EUR',
          ),
        );
        await tester.pump();
        if (desktop) {
          await tester.tap(find.text('Save changes'));
          await tester.pumpAndSettle();
        }

        final service = container.read(
          priceAnd24hChangeNotifierProvider,
        ) as _PollingPriceService;
        expect(prefs.currency, 'EUR');
        expect(service.baseTicker, 'EUR');
        expect(service.requests, 1);
        await tester.pump(service.updateInterval);
        expect(service.requests, 2);
        expect(previousService.requests, 0);
        service.cancel();
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
