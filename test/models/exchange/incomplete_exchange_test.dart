import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/exchange/incomplete_exchange.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/models/isar/exchange_cache/currency.dart';
import 'package:stackwallet/utilities/enums/exchange_rate_type_enum.dart';

class _Currency implements Currency {
  @override
  String get exchangeName => "exchange";

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Trade implements Trade {
  _Trade(this.payInAmount);

  @override
  final String payInAmount;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test("pay-in amount follows the created trade", () {
    final currency = _Currency();
    final model = IncompleteExchangeModel(
      sendCurrency: currency,
      receiveCurrency: currency,
      rateInfo: "",
      sendAmount: Decimal.parse("1.2"),
      receiveAmount: Decimal.one,
      rateType: ExchangeRateType.estimated,
      reversed: false,
      walletInitiated: false,
    );
    final trade = _Trade("1.23456789");

    expect(model.payInAmount, "1.2");
    model.trade = trade;
    expect(model.payInAmount, "1.23456789");
  });
}
