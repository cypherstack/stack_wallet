import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/exchange/response_objects/estimate.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/exchange_selection.dart';
import 'package:stackwallet/services/exchange/exchange.dart';

void main() {
  test('exchange rates sort highest first with failed providers last', () {
    final exchange = Exchange.defaultExchange;

    Estimate estimate(int rate) => Estimate(
      estimatedAmount: Decimal.fromInt(rate),
      fixedRate: false,
      reversed: false,
      exchangeProvider: exchange.name,
    );

    final result = rankExchangeEstimates(
      <(Exchange, List<Estimate>?)>[
        (exchange, [estimate(1)]),
        (exchange, null),
        (exchange, [estimate(3)]),
      ],
      amount: Decimal.one,
      receiveTicker: 'BTC',
    );

    expect(result.map((entry) => entry.$2?.estimatedAmount).toList(), [
      Decimal.fromInt(3),
      Decimal.fromInt(1),
      null,
    ]);
  });
}
