import 'package:decimal/decimal.dart';
import 'package:stackwallet/models/exchange/response_objects/estimate.dart';
import 'package:stackwallet/models/exchange/response_objects/range.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/models/isar/exchange_cache/currency.dart';
import 'package:stackwallet/models/isar/exchange_cache/pair.dart';
import 'package:stackwallet/services/exchange/exchange.dart';
import 'package:stackwallet/services/exchange/exchange_response.dart';
import 'package:stackwallet/services/exchange/simpleswap/simpleswap_api.dart';

class SimpleSwapExchange extends Exchange {
  SimpleSwapExchange._();

  static SimpleSwapExchange? _instance;
  static SimpleSwapExchange get instance =>
      _instance ??= SimpleSwapExchange._();

  static const exchangeName = "SimpleSwap";

  @override
  String get name => exchangeName;

  @override
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
  }) async {
    return await SimpleSwapAPI.instance.createNewExchange(
      isFixedRate: fixedRate,
      currencyFrom: from,
      currencyTo: to,
      addressTo: addressTo,
      userRefundAddress: addressRefund,
      userRefundExtraId: refundExtraId,
      amount: amount.toString(),
      extraIdTo: extraId,
    );
  }

  @override
  Future<ExchangeResponse<List<Currency>>> getAllCurrencies(
    bool fixedRate,
  ) async {
    final response =
        await SimpleSwapAPI.instance.getAllCurrencies(fixedRate: fixedRate);
    if (response.value != null) {
      final List<Currency> currencies = response.value!
          .map(
            (e) => Currency(
              exchangeName: exchangeName,
              ticker: e.symbol,
              name: e.name,
              network: e.network,
              image: e.image,
              externalId: e.extraId,
              isFiat: false,
              rateType: fixedRate
                  ? SupportedRateType.both
                  : SupportedRateType.estimated,
              isAvailable: true,
              isStackCoin: Currency.checkIsStackCoin(e.symbol),
              tokenContract: null,
            ),
          )
          .toList();
      return ExchangeResponse<List<Currency>>(
        value: currencies,
        exception: response.exception,
      );
    }

    return ExchangeResponse<List<Currency>>(
      value: null,
      exception: response.exception,
    );
  }

  @override
  Future<ExchangeResponse<List<Pair>>> getAllPairs(bool fixedRate) async {
    return await SimpleSwapAPI.instance.getAllPairs(isFixedRate: fixedRate);
  }

  @override
  Future<ExchangeResponse<Estimate>> getEstimate(
    String from,
    String to,
    Decimal amount,
    bool fixedRate,
    bool reversed,
  ) async {
    final response = await SimpleSwapAPI.instance.getEstimated(
      isFixedRate: fixedRate,
      currencyFrom: from,
      currencyTo: to,
      amount: amount.toString(),
    );
    if (response.exception != null) {
      return ExchangeResponse(
        exception: response.exception,
      );
    }

    return ExchangeResponse(
      value: Estimate(
        estimatedAmount: Decimal.parse(response.value!),
        fixedRate: fixedRate,
        reversed: reversed,
      ),
    );
  }

  @override
  Future<ExchangeResponse<Range>> getRange(
    String from,
    String to,
    bool fixedRate,
  ) async {
    return await SimpleSwapAPI.instance.getRange(
      isFixedRate: fixedRate,
      currencyFrom: from,
      currencyTo: to,
    );
  }

  @override
  Future<ExchangeResponse<List<Pair>>> getPairsFor(
    String currency,
    bool fixedRate,
  ) async {
    // return await SimpleSwapAPI.instance.ge
    throw UnimplementedError();
  }

  @override
  Future<ExchangeResponse<Trade>> getTrade(String tradeId) async {
    return await SimpleSwapAPI.instance.getExchange(exchangeId: tradeId);
  }

  @override
  Future<ExchangeResponse<Trade>> updateTrade(Trade trade) async {
    return await SimpleSwapAPI.instance.getExchange(
      exchangeId: trade.tradeId,
      oldTrade: trade,
    );
  }

  @override
  Future<ExchangeResponse<List<Trade>>> getTrades() async {
    // TODO: implement getTrades
    throw UnimplementedError();
  }

  @override
  Future<ExchangeResponse<List<Currency>>> getPairedCurrencies(
      String forCurrency, bool fixedRate) {
    // TODO: implement getPairedCurrencies
    throw UnimplementedError();
  }
}
