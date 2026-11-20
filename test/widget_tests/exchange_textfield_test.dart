import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/models/exchange/aggregate_currency.dart';
import 'package:stackwallet/models/isar/exchange_cache/currency.dart';
import 'package:stackwallet/models/isar/exchange_cache/pair.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/networking/tor_aware_network_image.dart';
import 'package:stackwallet/providers/global/locale_provider.dart';
import 'package:stackwallet/services/locale_service.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_service.dart';
import 'package:stackwallet/widgets/textfields/exchange_textfield.dart';
import 'package:tuple/tuple.dart';

import '../sample_data/theme_json.dart';

class _ThemeService extends Mock implements ThemeService {}

class _LocaleService extends LocaleService {
  @override
  String get locale => 'en_US';
}

/// Serves the sample PNG for `.png` URLs and the sample SVG otherwise, so
/// remote icons load without network access.
class _IconHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _HttpClient();
}

class _HttpClient extends Mock implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _Request(url);

  @override
  void close({bool force = false}) {}
}

class _Request extends Mock implements HttpClientRequest {
  _Request(this.url);

  final Uri url;

  @override
  HttpHeaders get headers => _Headers();

  @override
  Future<HttpClientResponse> close() async => _Response(
    File(
      "${Directory.current.path}/test/sample_data/light/assets/"
      "${url.path.endsWith(".png") ? "dummy.png" : "dummy.svg"}",
    ).readAsBytesSync(),
  );
}

class _Headers extends Mock implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void forEach(void Function(String, List<String>) action) {}
}

class _Response extends Mock implements HttpClientResponse {
  _Response(this._bytes);

  final List<int> _bytes;

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _bytes.length;

  @override
  HttpHeaders get headers => _Headers();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream.value(_bytes).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
}

AggregateCurrency _currency(String ticker, String image) => AggregateCurrency(
  exchangeCurrencyPairs: [
    Tuple2(
      "Some Exchange",
      Currency(
        exchangeName: "Some Exchange",
        ticker: ticker,
        name: ticker,
        network: ticker.toLowerCase(),
        image: image,
        isFiat: false,
        rateType: SupportedRateType.estimated,
        isStackCoin: false,
        tokenContract: null,
      ),
    ),
  ],
);

final _remoteSvgIcon = find.byWidgetPredicate(
  (w) => w is SvgPicture && w.bytesLoader is TorAwareSvgNetworkLoader,
);

final _remoteRasterIcon = find.byWidgetPredicate(
  (w) => w is Image && w.image is TorAwareNetworkImage,
);

void main() {
  final controller = TextEditingController();
  final focusNode = FocusNode();

  Future<void> pump(WidgetTester tester, AggregateCurrency currency) async {
    final previous = HttpOverrides.current;
    HttpOverrides.global = _IconHttpOverrides();
    addTearDown(() => HttpOverrides.global = previous);

    final theme = StackTheme.fromJson(json: lightThemeJsonMap);
    final themeService = _ThemeService();
    when(themeService.getTheme(themeId: 'light')).thenReturn(theme);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pThemeService.overrideWithValue(themeService),
          localeServiceChangeNotifierProvider.overrideWithValue(
            _LocaleService(),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [StackColors.fromStackColorTheme(theme)],
          ),
          home: Material(
            child: ExchangeTextField(
              key: const Key("receive"),
              controller: controller,
              focusNode: focusNode,
              textStyle: const TextStyle(),
              isWalletCoin: false,
              currency: currency,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets("loads a PNG icon as an image, not as an SVG", (tester) async {
    await pump(tester, _currency("aioz", "https://example.com/aioz.png"));

    expect(_remoteRasterIcon, findsOneWidget);
    expect(_remoteSvgIcon, findsNothing);
  });

  testWidgets("loads an SVG icon as an SVG", (tester) async {
    await pump(tester, _currency("aioz", "https://example.com/aioz.svg"));

    expect(_remoteSvgIcon, findsOneWidget);
    expect(_remoteRasterIcon, findsNothing);
  });

  testWidgets("does not carry the previous icon over to a new selection", (
    tester,
  ) async {
    await pump(tester, _currency("aaa", "https://example.com/aaa.svg"));
    final before = tester.element(_remoteSvgIcon);

    await pump(tester, _currency("bbb", "https://example.com/bbb.svg"));
    final after = tester.element(_remoteSvgIcon);

    // A reused element keeps the old decoded picture when the new load fails.
    expect(identical(before, after), isFalse);
  });

  testWidgets("replaces an SVG icon with a PNG icon on a new selection", (
    tester,
  ) async {
    await pump(tester, _currency("aaa", "https://example.com/aaa.svg"));
    expect(_remoteSvgIcon, findsOneWidget);

    await pump(tester, _currency("bbb", "https://example.com/bbb.png"));

    // Loaded as an SVG, the PNG fails to decode and the reused element keeps
    // showing the previous coin's icon.
    expect(_remoteSvgIcon, findsNothing);
    final image = tester.widget<Image>(_remoteRasterIcon).image;
    expect((image as TorAwareNetworkImage).url, "https://example.com/bbb.png");
  });
}
