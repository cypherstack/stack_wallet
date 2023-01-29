import 'package:decimal/decimal.dart';
import 'package:stackwallet/models/exchange/response_objects/currency.dart';
import 'package:stackwallet/models/exchange/response_objects/estimate.dart';
import 'package:stackwallet/models/exchange/response_objects/pair.dart';
import 'package:stackwallet/models/exchange/response_objects/range.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/services/exchange/exchange.dart';
import 'package:stackwallet/services/exchange/exchange_response.dart';

class MajesticBankExchange extends Exchange {
  static const exchangeName = "MajesticBank";

  @override
  Future<ExchangeResponse<Trade>> createTrade(
      {required String from,
      required String to,
      required bool fixedRate,
      required Decimal amount,
      required String addressTo,
      String? extraId,
      required String addressRefund,
      required String refundExtraId,
      String? rateId,
      required bool reversed}) {
    // TODO: implement createTrade
    throw UnimplementedError();
  }

  @override
  Future<ExchangeResponse<List<Currency>>> getAllCurrencies(bool fixedRate) {
    // TODO: implement getAllCurrencies
    throw UnimplementedError();
  }

  @override
  Future<ExchangeResponse<List<Pair>>> getAllPairs(bool fixedRate) {
    // TODO: implement getAllPairs
    throw UnimplementedError();
  }

  @override
  Future<ExchangeResponse<Estimate>> getEstimate(
      String from, String to, Decimal amount, bool fixedRate, bool reversed) {
    // TODO: implement getEstimate
    throw UnimplementedError();
  }

  @override
  Future<ExchangeResponse<List<Pair>>> getPairsFor(
      String currency, bool fixedRate) {
    // TODO: implement getPairsFor
    throw UnimplementedError();
  }

  @override
  Future<ExchangeResponse<Range>> getRange(
      String from, String to, bool fixedRate) {
    // TODO: implement getRange
    throw UnimplementedError();
  }

  @override
  Future<ExchangeResponse<Trade>> getTrade(String tradeId) {
    // TODO: implement getTrade
    throw UnimplementedError();
  }

  @override
  Future<ExchangeResponse<List<Trade>>> getTrades() {
    // TODO: implement getTrades
    throw UnimplementedError();
  }

  @override
  String get name => exchangeName;

  @override
  Future<ExchangeResponse<Trade>> updateTrade(Trade trade) {
    // TODO: implement updateTrade
    throw UnimplementedError();
  }
}
