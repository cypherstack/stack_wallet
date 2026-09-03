import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/services/exchange/exchange_response.dart';
import 'package:stackwallet/services/exchange/nanswap/api_response_models/n_trade.dart';
import 'package:stackwallet/services/exchange/nanswap/nanswap_exchange.dart';

void main() {
  test('maps Nanswap source and destination networks', () async {
    final nTrade = NTrade(
      id: 'trade-id',
      from: 'BTC',
      to: 'XNO',
      expectedAmountFrom: 1,
      expectedAmountTo: 2,
      payinAddress: 'pay-in',
      payoutAddress: 'pay-out',
    );
    final exchange = NanswapExchange.forTesting(
      getOrder: ({required String id}) async {
        expect(id, nTrade.id);
        return ExchangeResponse(value: nTrade);
      },
    );

    final trade = (await exchange.getTrade(nTrade.id)).value!;
    final staleTrade = trade.copyWith(
      payInNetwork: 'XNO',
      payOutNetwork: 'BTC',
    );
    final updatedTrade = (await exchange.updateTrade(staleTrade)).value!;

    expect((trade.payInNetwork, trade.payOutNetwork), ('BTC', 'XNO'));
    expect(
      (updatedTrade.payInNetwork, updatedTrade.payOutNetwork),
      ('BTC', 'XNO'),
    );
  });
}
