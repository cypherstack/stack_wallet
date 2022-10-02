import 'package:decimal/decimal.dart';
import 'package:stackwallet/models/exchange/response_objects/currency.dart';
import 'package:stackwallet/models/exchange/response_objects/pair.dart';
import 'package:stackwallet/models/exchange/response_objects/range.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/services/exchange/exchange_response.dart';

abstract class Exchange {
  //

  Future<ExchangeResponse<List<Currency>>> getAllCurrencies(bool fixedRate);

  Future<ExchangeResponse<List<Pair>>> getPairsFor(
    String currency,
    bool fixedRate,
  );

  Future<ExchangeResponse<List<Pair>>> getAllPairs(bool fixedRate);

  Future<ExchangeResponse<Trade>> getTrade(String tradeId);

  Future<ExchangeResponse<List<Trade>>> getTrades();

  Future<ExchangeResponse<Range>> getMinMaxExchangeAmounts(
    String from,
    String to,
    bool fixedRate,
  );

  Future<ExchangeResponse<Decimal>> getEstimate(
    String from,
    String to,
    Decimal amount,
    bool fixedRate,
  );

  Future<ExchangeResponse<Trade>> createTrade({
    required String from,
    required String to,
    required bool fixedRate,
    required Decimal amount,
    required String addressTo,
    required String addressRefund,
    required String refundExtraId,
  });
}
