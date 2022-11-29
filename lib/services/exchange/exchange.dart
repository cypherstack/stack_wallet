import 'package:decimal/decimal.dart';
import 'package:epicmobile/models/exchange/response_objects/currency.dart';
import 'package:epicmobile/models/exchange/response_objects/estimate.dart';
import 'package:epicmobile/models/exchange/response_objects/pair.dart';
import 'package:epicmobile/models/exchange/response_objects/range.dart';
import 'package:epicmobile/models/exchange/response_objects/trade.dart';
import 'package:epicmobile/services/exchange/change_now/change_now_exchange.dart';
import 'package:epicmobile/services/exchange/exchange_response.dart';
import 'package:epicmobile/services/exchange/simpleswap/simpleswap_exchange.dart';

abstract class Exchange {
  static Exchange fromName(String name) {
    switch (name) {
      case ChangeNowExchange.exchangeName:
        return ChangeNowExchange();
      case SimpleSwapExchange.exchangeName:
        return SimpleSwapExchange();
      default:
        throw ArgumentError("Unknown exchange name");
    }
  }

  String get name;

  Future<ExchangeResponse<List<Currency>>> getAllCurrencies(bool fixedRate);

  Future<ExchangeResponse<List<Pair>>> getPairsFor(
    String currency,
    bool fixedRate,
  );

  Future<ExchangeResponse<List<Pair>>> getAllPairs(bool fixedRate);

  Future<ExchangeResponse<Trade>> getTrade(String tradeId);
  Future<ExchangeResponse<Trade>> updateTrade(Trade trade);

  Future<ExchangeResponse<List<Trade>>> getTrades();

  Future<ExchangeResponse<Range>> getRange(
    String from,
    String to,
    bool fixedRate,
  );

  Future<ExchangeResponse<Estimate>> getEstimate(
    String from,
    String to,
    Decimal amount,
    bool fixedRate,
    bool reversed,
  );

  Future<ExchangeResponse<Trade>> createTrade({
    required String from,
    required String to,
    required bool fixedRate,
    required Decimal amount,
    required String addressTo,
    String? extraId,
    required String addressRefund,
    required String refundExtraId,
    String? rateId,
    required bool reversed,
  });
}
