import 'package:decimal/decimal.dart';
import 'package:stackwallet/models/exchange/change_now/estimated_exchange_amount.dart';
import 'package:stackwallet/models/exchange/response_objects/currency.dart';
import 'package:stackwallet/models/exchange/response_objects/pair.dart';
import 'package:stackwallet/models/exchange/response_objects/range.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/services/exchange/change_now/change_now_api.dart';
import 'package:stackwallet/services/exchange/exchange.dart';
import 'package:stackwallet/services/exchange/exchange_response.dart';
import 'package:uuid/uuid.dart';

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
    return await ChangeNowAPI.instance.getAvailableCurrencies(
      fixedRate: fixedRate ? true : null,
      active: true,
    );
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
    bool reversed,
  ) async {
    late final ExchangeResponse<EstimatedExchangeAmount> response;
    if (fixedRate) {
      response =
          await ChangeNowAPI.instance.getEstimatedExchangeAmountFixedRate(
        fromTicker: from,
        toTicker: to,
        fromAmount: amount,
        reversed: reversed,
      );
    } else {
      response = await ChangeNowAPI.instance.getEstimatedExchangeAmount(
        fromTicker: from,
        toTicker: to,
        fromAmount: amount,
      );
    }
    if (response.exception != null) {
      return ExchangeResponse(exception: response.exception);
    }
    return ExchangeResponse(value: response.value?.estimatedAmount);
  }

  @override
  Future<ExchangeResponse<Range>> getRange(
    String from,
    String to,
    bool fixedRate,
  ) async {
    return await ChangeNowAPI.instance.getRange(
      fromTicker: from,
      toTicker: to,
      isFixedRate: fixedRate,
    );
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
    final response =
        await ChangeNowAPI.instance.getTransactionStatus(id: tradeId);
    if (response.exception != null) {
      return ExchangeResponse(exception: response.exception);
    }
    final t = response.value!;
    final timestamp = DateTime.tryParse(t.createdAt) ?? DateTime.now();

    final trade = Trade(
      uuid: const Uuid().v1(),
      tradeId: tradeId,
      rateType: "",
      direction: "",
      timestamp: timestamp,
      updatedAt: DateTime.tryParse(t.updatedAt) ?? timestamp,
      payInCurrency: t.fromCurrency,
      payInAmount: t.expectedSendAmountDecimal,
      payInAddress: t.payinAddress,
      payInNetwork: "",
      payInExtraId: t.payinExtraId,
      payInTxid: "",
      payOutCurrency: t.toCurrency,
      payOutAmount: t.expectedReceiveAmountDecimal,
      payOutAddress: t.payoutAddress,
      payOutNetwork: "",
      payOutExtraId: t.payoutExtraId,
      payOutTxid: "",
      refundAddress: t.refundAddress,
      refundExtraId: t.refundExtraId,
      status: t.status.name,
    );

    return ExchangeResponse(value: trade);
  }

  @override
  Future<ExchangeResponse<Trade>> updateTrade(Trade trade) async {
    final response =
        await ChangeNowAPI.instance.getTransactionStatus(id: trade.tradeId);
    if (response.exception != null) {
      return ExchangeResponse(exception: response.exception);
    }
    final t = response.value!;
    final timestamp = DateTime.tryParse(t.createdAt) ?? DateTime.now();

    final _trade = Trade(
      uuid: trade.uuid,
      tradeId: trade.tradeId,
      rateType: "",
      direction: "",
      timestamp: timestamp,
      updatedAt: DateTime.tryParse(t.updatedAt) ?? timestamp,
      payInCurrency: t.fromCurrency,
      payInAmount: t.expectedSendAmountDecimal,
      payInAddress: t.payinAddress,
      payInNetwork: "",
      payInExtraId: t.payinExtraId,
      payInTxid: "",
      payOutCurrency: t.toCurrency,
      payOutAmount: t.expectedReceiveAmountDecimal,
      payOutAddress: t.payoutAddress,
      payOutNetwork: "",
      payOutExtraId: t.payoutExtraId,
      payOutTxid: "",
      refundAddress: t.refundAddress,
      refundExtraId: t.refundExtraId,
      status: t.status.name,
    );

    return ExchangeResponse(value: _trade);
  }

  @override
  Future<ExchangeResponse<List<Trade>>> getTrades() async {
    // TODO: implement getTrades
    throw UnimplementedError();
  }
}
