import 'package:decimal/decimal.dart';
import 'package:stackwallet/models/exchange/response_objects/currency.dart';
import 'package:stackwallet/models/exchange/response_objects/pair.dart';
import 'package:stackwallet/models/exchange/response_objects/range.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/services/exchange/exchange.dart';
import 'package:stackwallet/services/exchange/exchange_response.dart';

class ChangeNowExchange extends Exchange {
  @override
  Future<ExchangeResponse<Trade>> createTrade({
    required String from,
    required String to,
    required bool fixedRate,
    required Decimal amount,
    required String addressTo,
    required String addressRefund,
    required String refundExtraId,
  }) async {
    // TODO: implement createTrade
    throw UnimplementedError();
  }

  @override
  Future<ExchangeResponse<List<Currency>>> getAllCurrencies(
    bool fixedRate,
  ) async {
    // TODO: implement getAllCurrencies
    throw UnimplementedError();
  }

  @override
  Future<ExchangeResponse<List<Pair>>> getAllPairs(bool fixedRate) async {
    // TODO: implement getAllPairs
    throw UnimplementedError();
  }

  @override
  Future<ExchangeResponse<Decimal>> getEstimate(
    String from,
    String to,
    Decimal amount,
    bool fixedRate,
  ) async {
    // TODO: implement getEstimate
    throw UnimplementedError();
  }

  @override
  Future<ExchangeResponse<Range>> getMinMaxExchangeAmounts(
    String from,
    String to,
    bool fixedRate,
  ) async {
    // TODO: implement getMinMaxExchangeAmounts
    throw UnimplementedError();
  }

  @override
  Future<ExchangeResponse<List<Pair>>> getPairsFor(
    String currency,
    bool fixedRate,
  ) async {
    // TODO: implement getPairsFor
    throw UnimplementedError();
  }

  @override
  Future<ExchangeResponse<Trade>> getTrade(String tradeId) async {
    // TODO: implement getTrade
    throw UnimplementedError();
  }

  @override
  Future<ExchangeResponse<List<Trade>>> getTrades() async {
    // TODO: implement getTrades
    throw UnimplementedError();
  }
}
