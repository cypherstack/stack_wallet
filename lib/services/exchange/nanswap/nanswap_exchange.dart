import 'package:decimal/decimal.dart';
import 'package:uuid/uuid.dart';

import '../../../app_config.dart';
import '../../../exceptions/exchange/exchange_exception.dart';
import '../../../models/exchange/response_objects/estimate.dart';
import '../../../models/exchange/response_objects/range.dart';
import '../../../models/exchange/response_objects/trade.dart';
import '../../../models/isar/exchange_cache/currency.dart';
import '../../../models/isar/exchange_cache/pair.dart';
import '../exchange.dart';
import '../exchange_response.dart';
import 'api_response_models/n_estimate.dart';
import 'nanswap_api.dart';

class NanswapExchange extends Exchange {
  NanswapExchange._();

  static NanswapExchange? _instance;
  static NanswapExchange get instance => _instance ??= NanswapExchange._();

  static const exchangeName = "Nanswap";

  static const filter = ["BTC", "BAN", "XNO"];

  @override
  bool get supportsRefundAddress => false;

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
    Estimate? estimate,
    required bool reversed,
  }) async {
    try {
      if (fixedRate) {
        throw ExchangeException(
          "Nanswap fixedRate not available",
          ExchangeExceptionType.generic,
        );
      }
      if (refundExtraId.isNotEmpty) {
        throw ExchangeException(
          "Nanswap refundExtraId not available",
          ExchangeExceptionType.generic,
        );
      }
      if (addressRefund.isNotEmpty) {
        throw ExchangeException(
          "Nanswap addressRefund not available",
          ExchangeExceptionType.generic,
        );
      }
      if (reversed) {
        throw ExchangeException(
          "Nanswap reversed not available",
          ExchangeExceptionType.generic,
        );
      }

      final response = await NanswapAPI.instance.createOrder(
        from: from,
        to: to,
        fromAmount: amount.toDouble(),
        toAddress: addressTo,
        extraIdOrMemo: extraId,
      );

      if (response.exception != null) {
        return ExchangeResponse(
          exception: response.exception,
        );
      }

      final t = response.value!;

      return ExchangeResponse(
        value: Trade(
          uuid: const Uuid().v1(),
          tradeId: t.id,
          rateType: "estimated",
          direction: "normal",
          timestamp: DateTime.now(),
          updatedAt: DateTime.now(),
          payInCurrency: from,
          payInAmount: t.expectedAmountFrom.toString(),
          payInAddress: t.payinAddress,
          payInNetwork: t.toNetwork ?? t.to,
          payInExtraId: t.payinExtraId ?? "",
          payInTxid: t.payinHash ?? "",
          payOutCurrency: to,
          payOutAmount: t.expectedAmountTo.toString(),
          payOutAddress: t.payoutAddress,
          payOutNetwork: t.fromNetwork ?? t.from,
          payOutExtraId: "",
          payOutTxid: t.payoutHash ?? "",
          refundAddress: "",
          refundExtraId: "",
          status: "waiting",
          exchangeName: exchangeName,
        ),
      );
    } on ExchangeException catch (e) {
      return ExchangeResponse(
        exception: e,
      );
    } catch (e) {
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
      if (fixedRate) {
        throw ExchangeException(
          "Nanswap fixedRate not available",
          ExchangeExceptionType.generic,
        );
      }

      final response = await NanswapAPI.instance.getSupportedCurrencies();

      if (response.exception != null) {
        return ExchangeResponse(
          exception: response.exception,
        );
      }

      return ExchangeResponse(
        value: response.value!
            .where((e) => filter.contains(e.id))
            .map(
              (e) => Currency(
                exchangeName: exchangeName,
                ticker: e.id,
                name: e.name,
                network: e.network,
                image: e.image,
                isFiat: false,
                rateType: SupportedRateType.estimated,
                isStackCoin: AppConfig.isStackCoin(e.id),
                tokenContract: null,
                isAvailable: true,
              ),
            )
            .toList(),
      );
    } on ExchangeException catch (e) {
      return ExchangeResponse(
        exception: e,
      );
    } catch (e) {
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  @override
  Future<ExchangeResponse<List<Pair>>> getAllPairs(bool fixedRate) async {
    throw UnimplementedError();
  }

  @override
  Future<ExchangeResponse<List<Estimate>>> getEstimates(
    String from,
    String to,
    Decimal amount,
    bool fixedRate,
    bool reversed,
  ) async {
    try {
      if (fixedRate) {
        throw ExchangeException(
          "Nanswap fixedRate not available",
          ExchangeExceptionType.generic,
        );
      }

      final ExchangeResponse<NEstimate> response;
      if (reversed) {
        response = await NanswapAPI.instance.getEstimateReversed(
          from: from,
          to: to,
          amountTo: amount.toString(),
        );
      } else {
        response = await NanswapAPI.instance.getEstimate(
          from: from,
          to: to,
          amountFrom: amount.toString(),
        );
      }

      if (response.exception != null) {
        return ExchangeResponse(
          exception: response.exception,
        );
      }

      final t = response.value!;

      return ExchangeResponse(
        value: [
          Estimate(
            estimatedAmount: Decimal.parse(
              (reversed ? t.amountFrom : t.amountTo).toString(),
            ),
            fixedRate: fixedRate,
            reversed: reversed,
            exchangeProvider: exchangeName,
          ),
        ],
      );
    } on ExchangeException catch (e) {
      return ExchangeResponse(
        exception: e,
      );
    } catch (e) {
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  @override
  Future<ExchangeResponse<List<Currency>>> getPairedCurrencies(
    String forCurrency,
    bool fixedRate,
  ) async {
    try {
      if (fixedRate) {
        throw ExchangeException(
          "Nanswap fixedRate not available",
          ExchangeExceptionType.generic,
        );
      }

      final response = await getAllCurrencies(
        fixedRate,
      );

      if (response.exception != null) {
        return ExchangeResponse(
          exception: response.exception,
        );
      }

      return ExchangeResponse(
        value: response.value!..removeWhere((e) => e.ticker == forCurrency),
      );
    } on ExchangeException catch (e) {
      return ExchangeResponse(
        exception: e,
      );
    } catch (e) {
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  @override
  Future<ExchangeResponse<List<Pair>>> getPairsFor(
    String currency,
    bool fixedRate,
  ) async {
    throw UnsupportedError("Not used");
  }

  @override
  Future<ExchangeResponse<Range>> getRange(
    String from,
    String to,
    bool fixedRate,
  ) async {
    try {
      if (fixedRate) {
        throw ExchangeException(
          "Nanswap fixedRate not available",
          ExchangeExceptionType.generic,
        );
      }

      final response = await NanswapAPI.instance.getOrderLimits(
        from: from,
        to: to,
      );

      if (response.exception != null) {
        return ExchangeResponse(
          exception: response.exception,
        );
      }

      final t = response.value!;

      return ExchangeResponse(
        value: Range(
          min: Decimal.parse(t.minFrom.toString()),
          max: Decimal.parse(t.maxFrom.toString()),
        ),
      );
    } on ExchangeException catch (e) {
      return ExchangeResponse(
        exception: e,
      );
    } catch (e) {
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
    try {
      final response = await NanswapAPI.instance.getOrder(
        id: tradeId,
      );

      if (response.exception != null) {
        return ExchangeResponse(
          exception: response.exception,
        );
      }

      final t = response.value!;

      return ExchangeResponse(
        value: Trade(
          uuid: const Uuid().v1(),
          tradeId: t.id,
          rateType: "estimated",
          direction: "normal",
          timestamp: DateTime.now(),
          updatedAt: DateTime.now(),
          payInCurrency: t.from,
          payInAmount: t.expectedAmountFrom.toString(),
          payInAddress: t.payinAddress,
          payInNetwork: t.toNetwork ?? t.to,
          payInExtraId: t.payinExtraId ?? "",
          payInTxid: t.payinHash ?? "",
          payOutCurrency: t.to,
          payOutAmount: t.expectedAmountTo.toString(),
          payOutAddress: t.payoutAddress,
          payOutNetwork: t.fromNetwork ?? t.from,
          payOutExtraId: "",
          payOutTxid: t.payoutHash ?? "",
          refundAddress: "",
          refundExtraId: "",
          status: t.status ?? "unknown",
          exchangeName: exchangeName,
        ),
      );
    } on ExchangeException catch (e) {
      return ExchangeResponse(
        exception: e,
      );
    } catch (e) {
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
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
    try {
      final response = await NanswapAPI.instance.getOrder(
        id: trade.tradeId,
      );

      if (response.exception != null) {
        return ExchangeResponse(
          exception: response.exception,
        );
      }

      final t = response.value!;

      return ExchangeResponse(
        value: Trade(
          uuid: trade.uuid,
          tradeId: t.id,
          rateType: trade.rateType,
          direction: trade.rateType,
          timestamp: trade.timestamp,
          updatedAt: DateTime.now(),
          payInCurrency: t.from,
          payInAmount: t.expectedAmountFrom.toString(),
          payInAddress: t.payinAddress,
          payInNetwork: t.toNetwork ?? trade.payInNetwork,
          payInExtraId: t.payinExtraId ?? trade.payInExtraId,
          payInTxid: t.payinHash ?? trade.payInTxid,
          payOutCurrency: t.to,
          payOutAmount: t.expectedAmountTo.toString(),
          payOutAddress: t.payoutAddress,
          payOutNetwork: t.fromNetwork ?? trade.payOutNetwork,
          payOutExtraId: trade.payOutExtraId,
          payOutTxid: t.payoutHash ?? trade.payOutTxid,
          refundAddress: trade.refundAddress,
          refundExtraId: trade.refundExtraId,
          status: t.status ?? "unknown",
          exchangeName: exchangeName,
        ),
      );
    } on ExchangeException catch (e) {
      return ExchangeResponse(
        exception: e,
      );
    } catch (e) {
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }
}
