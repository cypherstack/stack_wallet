import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/exchange/response_objects/estimate.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/sorted_exchange_providers.dart';
import 'package:stackwallet/services/exchange/exchange.dart';

void main() {
  test('exchange rates sort highest first with failed providers last', () {
    final exchange = Exchange.defaultExchange;
    final dynamic state = SortedExchangeProviders(
      exchangees: [exchange],
      fixedRate: false,
      reversed: false,
    ).createState();

    Estimate estimate(int rate) => Estimate(
      estimatedAmount: Decimal.fromInt(rate),
      fixedRate: false,
      reversed: false,
      exchangeProvider: exchange.name,
    );

    state.estimates.addAll(<(Exchange, List<Estimate>?)>[
      (exchange, [estimate(1)]),
      (exchange, null),
      (exchange, [estimate(3)]),
    ]);

    final result = state.transform(Decimal.one, 'BTC') as List;

    expect(result.map((entry) => entry.$2?.estimatedAmount).toList(), [
      Decimal.fromInt(3),
      Decimal.fromInt(1),
      null,
    ]);
  });
}
