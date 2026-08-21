import 'package:decimal/decimal.dart';
import 'package:uuid/uuid.dart';

import '../../../app_config.dart';
import '../../../exceptions/exchange/exchange_exception.dart';
import '../../../models/exchange/response_objects/estimate.dart';
import '../../../models/exchange/response_objects/range.dart';
import '../../../models/exchange/response_objects/trade.dart';
import '../../../models/isar/exchange_cache/currency.dart';
import '../../../utilities/logger.dart';
import '../exchange.dart';
import '../exchange_response.dart';
import 'lets_exchange_api.dart';
import 'models/coin_info.dart';
import 'models/transaction.dart';

class LetsExchangeExchange extends Exchange {
  LetsExchangeExchange._();

  static LetsExchangeExchange? _instance;
  static LetsExchangeExchange get instance =>
      _instance ??= LetsExchangeExchange._();

  static const exchangeName = "LetsExchange";

  Trade _buildTrade({
    required Transaction result,
    required String uuid,
    required String rateType,
    required String direction,
    required DateTime timestamp,
  }) {
    return Trade(
      uuid: uuid,
      tradeId: result.transactionId,
      rateType: rateType,
      direction: direction,
      timestamp: timestamp,
      updatedAt: DateTime.now(),
      payInCurrency: result.coinFrom,
      payInAmount: result.depositAmount.toString(),
      payInAddress: result.deposit,
      payInNetwork: result.coinFromNetwork,
      payInExtraId: result.depositExtraId ?? "",
      payInTxid: result.hashIn ?? "",
      payOutCurrency: result.coinTo,
      payOutAmount: result.withdrawalAmount.toString(),
      payOutAddress: result.withdrawal,
      payOutNetwork: result.coinToNetwork,
      payOutExtraId: result.withdrawalExtraId ?? "",
      payOutTxid: result.hashOut ?? "",
      refundAddress: result.returnAddress ?? "",
      refundExtraId: result.returnExtraId ?? "",
      status: result.status,
      exchangeName: exchangeName,
    );
  }

  @override
  Future<ExchangeResponse<Trade>> createTrade({
    required String from,
    required String to,
    required String? fromNetwork,
    required String? toNetwork,
    required bool fixedRate,
    required Decimal amount,
    required String addressTo,
    String? extraId,
    required String addressRefund,
    required String refundExtraId,
    Estimate? estimate,
    required bool reversed,
  }) async {
    try {
      if (fromNetwork == null) throw Exception("fromNetwork must not be null");
      if (toNetwork == null) throw Exception("toNetwork must not be null");

      if (reversed && estimate?.rateId == null) {
        throw Exception("rateId required for reversed trade");
      }

      if (!reversed && fixedRate && estimate?.rateId == null) {
        throw Exception("rateId required for fixed rate trade");
      }

      final Transaction result;
      if (reversed) {
        final request = CreateTransactionRevertRequest(
          float: !fixedRate,
          coinFrom: from.toUpperCase(),
          coinTo: to.toUpperCase(),
          networkFrom: fromNetwork,
          networkTo: toNetwork,
          withdrawalAmount: amount,
          withdrawal: addressTo,
          withdrawalExtraId: extraId ?? "",
          returnAddress: addressRefund,
          returnExtraId: refundExtraId,
          rateId: estimate!.rateId!,
        );
        result = await LetsExchangeApi.createTransactionRevert(request);
      } else {
        final request = CreateTransactionRequest(
          float: !fixedRate,
          coinFrom: from.toUpperCase(),
          coinTo: to.toUpperCase(),
          networkFrom: fromNetwork,
          networkTo: toNetwork,
          depositAmount: amount,
          withdrawal: addressTo,
          withdrawalExtraId: extraId ?? "",
          returnAddress: addressRefund,
          returnExtraId: refundExtraId,
          rateId: estimate?.rateId,
        );
        result = await LetsExchangeApi.createTransaction(request);
      }

      final trade = _buildTrade(
        result: result,
        uuid: const Uuid().v1(),
        rateType: !fixedRate ? "estimated" : "fixed",
        direction: reversed ? "reversed" : "normal",
        timestamp: DateTime.now(),
      );

      return ExchangeResponse(value: trade);
    } catch (e, s) {
      Logging.instance.e("createTrade", error: e, stackTrace: s);
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  @override
  Future<ExchangeResponse<List<Currency>>> getAllCurrencies(
    bool fixedRate,
  ) async {
    try {
      final coins = await LetsExchangeApi.fetchCoins();

      final currencies = [
        for (final coin in coins)
          for (final network in coin.networks)
            Currency(
              exchangeName: exchangeName,
              ticker: coin.code,
              name: coin.name,
              network: network.code,
              image: coin.icon,
              isFiat: false,
              isAvailable: coin.isActive && network.isActive,
              tokenContract: network.contractAddress,
              rateType: .both,
              isStackCoin: AppConfig.isStackCoin(coin.code),
            ),
      ];

      return ExchangeResponse(value: currencies);
    } catch (e, s) {
      Logging.instance.e("getAllCurrencies", error: e, stackTrace: s);
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  @override
  Future<ExchangeResponse<List<Estimate>>> getEstimates(
    String from,
    String? fromNetwork,
    String to,
    String? toNetwork,
    Decimal amount,
    bool fixedRate,
    bool reversed,
  ) async {
    try {
      if (fromNetwork == null) throw Exception("fromNetwork must not be null");
      if (toNetwork == null) throw Exception("toNetwork must not be null");

      final CoinInfo info;
      if (reversed) {
        final request = CoinInfoRequest(
          from: from.toUpperCase(),
          to: to.toUpperCase(),
          networkFrom: fromNetwork,
          networkTo: toNetwork,
          amount: amount,
        );
        info = await LetsExchangeApi.getCoinInfoRevert(request);
      } else {
        final request = CoinInfoRequest(
          from: from.toUpperCase(),
          to: to.toUpperCase(),
          networkFrom: fromNetwork,
          networkTo: toNetwork,
          amount: amount,
          float: !fixedRate,
        );
        info = await LetsExchangeApi.getCoinInfo(request);
      }

      final estimate = Estimate(
        rateId: info.rateId,
        estimatedAmount: info.amount,
        fixedRate: fixedRate,
        reversed: reversed,
        exchangeProvider: exchangeName,
      );

      return ExchangeResponse(value: [estimate]);
    } catch (e, s) {
      Logging.instance.e("getEstimates", error: e, stackTrace: s);
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  @override
  Future<ExchangeResponse<Range>> getRange(
    String from,
    String? fromNetwork,
    String to,
    String? toNetwork,
    bool fixedRate,
  ) async {
    try {
      if (fromNetwork == null) throw Exception("fromNetwork must not be null");
      if (toNetwork == null) throw Exception("toNetwork must not be null");

      // `/v1/info` requires an amount, but the returned min/max are the pair's
      // limits and don't depend on it, so we probe with a nominal value
      final request = CoinInfoRequest(
        from: from.toUpperCase(),
        to: to.toUpperCase(),
        networkFrom: fromNetwork,
        networkTo: toNetwork,
        amount: Decimal.parse("0.1"),
        float: !fixedRate,
      );

      final info = await LetsExchangeApi.getCoinInfo(request);

      return ExchangeResponse(
        value: Range(max: info.maxAmount, min: info.minAmount),
      );
    } catch (e, s) {
      Logging.instance.e("getRange", error: e, stackTrace: s);
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  @override
  Future<ExchangeResponse<Trade>> getTrade(String tradeId) async {
    throw UnimplementedError("Not currently used in this app");
  }

  @override
  Future<ExchangeResponse<List<Trade>>> getTrades() async {
    throw UnimplementedError("Not currently used in this app");
  }

  @override
  String get name => exchangeName;

  @override
  Future<ExchangeResponse<Trade>> updateTrade(Trade trade) async {
    try {
      final result = await LetsExchangeApi.getTransaction(trade.tradeId);

      final updated = _buildTrade(
        result: result,
        uuid: trade.uuid,
        rateType: trade.rateType,
        direction: trade.direction,
        timestamp: trade.timestamp,
      );

      return ExchangeResponse(value: updated);
    } catch (e, s) {
      Logging.instance.e("updateTrade", error: e, stackTrace: s);
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }
}
