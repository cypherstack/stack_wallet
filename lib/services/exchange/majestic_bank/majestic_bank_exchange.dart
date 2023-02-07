import 'package:decimal/decimal.dart';
import 'package:stackwallet/exceptions/exchange/exchange_exception.dart';
import 'package:stackwallet/exceptions/exchange/majestic_bank/mb_exception.dart';
import 'package:stackwallet/models/exchange/majestic_bank/mb_order.dart';
import 'package:stackwallet/models/exchange/response_objects/currency.dart';
import 'package:stackwallet/models/exchange/response_objects/estimate.dart';
import 'package:stackwallet/models/exchange/response_objects/pair.dart';
import 'package:stackwallet/models/exchange/response_objects/range.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/services/exchange/exchange.dart';
import 'package:stackwallet/services/exchange/exchange_response.dart';
import 'package:stackwallet/services/exchange/majestic_bank/majestic_bank_api.dart';
import 'package:uuid/uuid.dart';

class MajesticBankExchange extends Exchange {
  static const exchangeName = "MajesticBank";

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
    ExchangeResponse<MBOrder>? response;

    if (fixedRate) {
      response = await MajesticBankAPI.instance.createFixedRateOrder(
        amount: amount.toString(),
        fromCurrency: from,
        receiveCurrency: to,
        receiveAddress: addressTo,
        reversed: reversed,
      );
    } else {
      if (reversed) {
        return ExchangeResponse(
          exception: MBException(
            "Reversed trade not available",
            ExchangeExceptionType.generic,
          ),
        );
      }
      response = await MajesticBankAPI.instance.createOrder(
        fromAmount: amount.toString(),
        fromCurrency: from,
        receiveCurrency: to,
        receiveAddress: addressTo,
      );
    }

    if (response.value != null) {
      final order = response.value!;
      final trade = Trade(
        uuid: const Uuid().v1(),
        tradeId: order.orderId,
        rateType: fixedRate ? "fixed" : "floating",
        direction: reversed ? "reversed" : "direct",
        timestamp: order.createdAt,
        updatedAt: order.createdAt,
        payInCurrency: order.fromCurrency,
        payInAmount: order.fromAmount.toString(),
        payInAddress: order.address,
        payInNetwork: "",
        payInExtraId: "",
        payInTxid: "",
        payOutCurrency: order.receiveCurrency,
        payOutAmount: order.receiveAmount.toString(),
        payOutAddress: addressTo,
        payOutNetwork: "",
        payOutExtraId: "",
        payOutTxid: "",
        refundAddress: addressRefund,
        refundExtraId: refundExtraId,
        status: "Waiting",
        exchangeName: exchangeName,
      );

      return ExchangeResponse(value: trade);
    } else {
      return ExchangeResponse(exception: response.exception!);
    }
  }

  @override
  Future<ExchangeResponse<List<Currency>>> getAllCurrencies(
    bool fixedRate,
  ) async {
    final response = await MajesticBankAPI.instance.getLimits();
    if (response.value == null) {
      return ExchangeResponse(exception: response.exception);
    }

    final List<Currency> currencies = [];
    final limits = response.value!;

    for (final limit in limits) {
      final currency = Currency(
        ticker: limit.currency,
        name: limit.currency,
        network: "",
        image: "",
        hasExternalId: false,
        isFiat: false,
        featured: false,
        isStable: false,
        supportsFixedRate: true,
      );
      currencies.add(currency);
    }

    return ExchangeResponse(value: currencies);
  }

  @override
  Future<ExchangeResponse<List<Pair>>> getAllPairs(bool fixedRate) async {
    final response = await MajesticBankAPI.instance.getRates();
    if (response.value == null) {
      return ExchangeResponse(exception: response.exception);
    }

    final List<Pair> pairs = [];
    final rates = response.value!;

    for (final rate in rates) {
      final pair = Pair(
        from: rate.fromCurrency,
        fromNetwork: "",
        to: rate.toCurrency,
        toNetwork: "",
        fixedRate: true,
        floatingRate: true,
      );
      pairs.add(pair);
    }

    return ExchangeResponse(value: pairs);
  }

  @override
  Future<ExchangeResponse<Estimate>> getEstimate(
    String from,
    String to,
    Decimal amount,
    bool fixedRate,
    bool reversed,
  ) async {
    final response = await MajesticBankAPI.instance.calculateOrder(
      amount: amount.toString(),
      reversed: reversed,
      fromCurrency: from,
      receiveCurrency: to,
    );
    if (response.value == null) {
      return ExchangeResponse(exception: response.exception);
    }

    final calc = response.value!;
    final estimate = Estimate(
      estimatedAmount: reversed ? calc.fromAmount : calc.receiveAmount,
      fixedRate: fixedRate,
      reversed: reversed,
    );
    return ExchangeResponse(value: estimate);
  }

  @override
  Future<ExchangeResponse<List<Pair>>> getPairsFor(
    String currency,
    bool fixedRate,
  ) async {
    final response = await getAllPairs(fixedRate);
    if (response.value == null) {
      return ExchangeResponse(exception: response.exception);
    }

    final pairs = response.value!.where(
      (e) =>
          e.from.toUpperCase() == currency.toUpperCase() ||
          e.to.toUpperCase() == currency.toUpperCase(),
    );

    return ExchangeResponse(value: pairs.toList());
  }

  @override
  Future<ExchangeResponse<Range>> getRange(
    String from,
    String to,
    bool fixedRate,
  ) async {
    final response =
        await MajesticBankAPI.instance.getLimit(fromCurrency: from);
    if (response.value == null) {
      return ExchangeResponse(exception: response.exception);
    }

    final limit = response.value!;
    final range = Range(min: limit.min, max: limit.max);

    return ExchangeResponse(value: range);
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

  @override
  String get name => exchangeName;

  @override
  Future<ExchangeResponse<Trade>> updateTrade(Trade trade) async {
    final response = await MajesticBankAPI.instance.trackOrder(
      orderId: trade.tradeId,
    );

    if (response.value != null) {
      final status = response.value!;
      final updatedTrade = Trade(
        uuid: trade.uuid,
        tradeId: status.orderId,
        rateType: trade.rateType,
        direction: trade.direction,
        timestamp: trade.timestamp,
        updatedAt: DateTime.now(),
        payInCurrency: status.fromCurrency,
        payInAmount: status.fromAmount.toString(),
        payInAddress: status.address,
        payInNetwork: trade.payInNetwork,
        payInExtraId: trade.payInExtraId,
        payInTxid: trade.payInTxid,
        payOutCurrency: status.receiveCurrency,
        payOutAmount: status.receiveAmount.toString(),
        payOutAddress: trade.payOutAddress,
        payOutNetwork: trade.payOutNetwork,
        payOutExtraId: trade.payOutExtraId,
        payOutTxid: trade.payOutTxid,
        refundAddress: trade.refundAddress,
        refundExtraId: trade.refundExtraId,
        status: status.status,
        exchangeName: exchangeName,
      );

      return ExchangeResponse(value: updatedTrade);
    } else {
      return ExchangeResponse(exception: response.exception);
    }
  }
}
