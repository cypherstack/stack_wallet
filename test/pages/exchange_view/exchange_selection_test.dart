import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/exchange/active_pair.dart';
import 'package:stackwallet/models/exchange/aggregate_currency.dart';
import 'package:stackwallet/models/exchange/response_objects/estimate.dart';
import 'package:stackwallet/models/isar/exchange_cache/currency.dart';
import 'package:stackwallet/models/isar/exchange_cache/pair.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/exchange_selection.dart';
import 'package:stackwallet/services/exchange/change_now/change_now_exchange.dart';
import 'package:stackwallet/services/exchange/exchange.dart';
import 'package:stackwallet/services/exchange/exolix/exolix_exchange.dart';
import 'package:stackwallet/services/exchange/trocador/trocador_exchange.dart';
import 'package:stackwallet/utilities/enums/exchange_rate_type_enum.dart';
import 'package:tuple/tuple.dart';

final changeNow = ChangeNowExchange.instance;
final exolix = ExolixExchange.instance;
final trocador = TrocadorExchange.instance;

Estimate _quote(
  Exchange exchange,
  int amount, {
  String? provider,
  bool fixedRate = false,
  bool reversed = false,
}) => Estimate(
  estimatedAmount: Decimal.fromInt(amount),
  fixedRate: fixedRate,
  reversed: reversed,
  exchangeProvider: provider ?? exchange.name,
);

List<(Exchange, Estimate?)> _rank(
  List<(Exchange, List<Estimate>?)> quotes, {
  int amount = 1,
}) => rankExchangeEstimates(
  quotes,
  amount: Decimal.fromInt(amount),
  receiveTicker: 'BTC',
);

(Exchange, String)? _select(
  List<(Exchange, Estimate?)> ranked, {
  Exchange? current,
  String? currentProvider,
  bool userChose = false,
  bool fixedRate = false,
  bool reversed = false,
}) => exchangeToSelect(
  ranked: ranked,
  currentExchange: current ?? changeNow,
  currentProviderName: currentProvider ?? (current ?? changeNow).name,
  userChose: userChose,
  fixedRate: fixedRate,
  reversed: reversed,
);

AggregateCurrency _currency(String ticker) => AggregateCurrency(
  exchangeCurrencyPairs: [
    Tuple2(
      changeNow.name,
      Currency(
        exchangeName: changeNow.name,
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

void main() {
  group('rankExchangeEstimates', () {
    test('ranks reversed quotes by the lowest amount to send', () {
      final ranked = _rank([
        (changeNow, [_quote(changeNow, 4, reversed: true)]),
        (exolix, [_quote(exolix, 2, reversed: true)]),
      ]);

      expect(ranked.map((e) => e.$1), [exolix, changeNow]);
    });

    test('ranks each of several quotes from one exchange', () {
      final ranked = _rank([
        (changeNow, [_quote(changeNow, 3)]),
        (
          trocador,
          [
            _quote(trocador, 2, provider: 'A'),
            _quote(trocador, 5, provider: 'B'),
          ],
        ),
      ]);

      expect(ranked.map((e) => e.$2!.exchangeProvider), [
        'B',
        changeNow.name,
        'A',
      ]);
    });
  });

  group('exchangeToSelect', () {
    final ranked = _rank([
      (changeNow, [_quote(changeNow, 3)]),
      (exolix, [_quote(exolix, 5)]),
      (trocador, null),
    ]);

    test('selects the best rate when the user has not chosen', () {
      expect(_select(ranked), (exolix, exolix.name));
    });

    test("keeps the user's provider while it still has a quote", () {
      expect(_select(ranked, current: changeNow, userChose: true), isNull);
    });

    test("moves off the user's provider when it has no quote", () {
      expect(_select(ranked, current: trocador, userChose: true), (
        exolix,
        exolix.name,
      ));
    });

    test('keeps a chosen sub-provider of a multi-quote exchange', () {
      final trocadorRanked = _rank([
        (exolix, [_quote(exolix, 9)]),
        (
          trocador,
          [
            _quote(trocador, 2, provider: 'A'),
            _quote(trocador, 5, provider: 'B'),
          ],
        ),
      ]);

      expect(
        _select(
          trocadorRanked,
          current: trocador,
          currentProvider: 'A',
          userChose: true,
        ),
        isNull,
      );
      expect(
        _select(
          trocadorRanked,
          current: trocador,
          currentProvider: 'C',
          userChose: true,
        ),
        (exolix, exolix.name),
      );
    });

    test('ignores quotes for the other rate type', () {
      final mixed = _rank([
        (exolix, [_quote(exolix, 9, fixedRate: true)]),
        (changeNow, [_quote(changeNow, 3)]),
      ]);

      expect(_select(mixed, current: exolix), (changeNow, changeNow.name));
    });

    test('keeps the selection when no provider has a quote', () {
      final none = _rank([(changeNow, null), (exolix, null)]);

      expect(_select(none, current: exolix), isNull);
    });
  });

  group('exchangeChoiceContext', () {
    ActivePair pair(String send, String receive) => ActivePair()
      ..setSend(_currency(send), notifyListeners: false)
      ..setReceive(_currency(receive), notifyListeners: false);

    test('is the same for the same pair and rate type', () {
      expect(
        exchangeChoiceContext(pair('BTC', 'XMR'), ExchangeRateType.estimated),
        exchangeChoiceContext(pair('btc', 'XMR'), ExchangeRateType.estimated),
      );
    });

    test('changes with the pair, its direction or the rate type', () {
      final base = exchangeChoiceContext(
        pair('BTC', 'XMR'),
        ExchangeRateType.estimated,
      );

      expect(
        exchangeChoiceContext(pair('BTC', 'ETH'), ExchangeRateType.estimated),
        isNot(base),
      );
      expect(
        exchangeChoiceContext(pair('XMR', 'BTC'), ExchangeRateType.estimated),
        isNot(base),
      );
      expect(
        exchangeChoiceContext(pair('BTC', 'XMR'), ExchangeRateType.fixed),
        isNot(base),
      );
    });
  });
}
