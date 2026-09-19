import 'package:decimal/decimal.dart';
import 'package:uuid/uuid.dart';

import '../../../app_config.dart';
import '../../../exceptions/exchange/exchange_exception.dart';
import '../../../models/exchange/response_objects/estimate.dart';
import '../../../models/exchange/response_objects/range.dart';
import '../../../models/exchange/response_objects/trade.dart';
import '../../../models/isar/exchange_cache/currency.dart';
import '../exchange.dart';
import '../exchange_response.dart';
import 'api/dto/exolix_currency.dart';
import 'api/exolix_api.dart';

class ExolixExchange extends Exchange {
  ExolixExchange._();

  static ExolixExchange? _instance;
  static ExolixExchange get instance => _instance ??= ExolixExchange._();

  static const exchangeName = "Exolix";

  @override
  String get name => exchangeName;

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
      if (fromNetwork == null || toNetwork == null) {
        throw ExchangeException("Exolix requires coin network args", .generic);
      }

      final result = await ExolixApi.createTransaction(
        coinFrom: from,
        networkFrom: fromNetwork,
        coinTo: to,
        networkTo: toNetwork,
        withdrawalAddress: addressTo,
        amount: reversed ? null : amount,
        withdrawalAmount: reversed ? amount : null,
        withdrawalExtraId: extraId,
        refundAddress: addressRefund,
        refundExtraId: refundExtraId,
        rateType: fixedRate ? .fixed : .float,
      );

      final trade = Trade(
        uuid: const Uuid().v1(),
        tradeId: result.id,
        rateType: result.rateType == .float ? "estimated" : "fixed",
        direction: reversed ? "reversed" : "normal",
        timestamp: result.createdAt ?? DateTime.now(),
        updatedAt: result.createdAt ?? DateTime.now(),
        payInCurrency: result.coinFrom.coinCode,
        payInAmount: result.amount.toString(),
        payInAddress: result.depositAddress,
        payInNetwork: result.coinFrom.network,
        payInExtraId: result.depositExtraId ?? "",
        payInTxid: result.hashIn.hash ?? "",
        payOutCurrency: result.coinTo.coinCode,
        payOutAmount: result.amountTo.toString(),
        payOutAddress: result.withdrawalAddress,
        payOutNetwork: result.coinTo.network,
        payOutExtraId: result.withdrawalExtraId ?? "",
        payOutTxid: result.hashOut.hash ?? "",
        refundAddress: result.refundAddress ?? addressRefund,
        refundExtraId: result.refundExtraId ?? refundExtraId,
        status: result.status.name,
        exchangeName: exchangeName,
      );

      return ExchangeResponse(value: trade);
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
      const pageSize = 100; // some reasonable value
      final collected = <ExolixCurrency>[];
      int page = 1;

      // First page gives us `count` so we know when to stop.
      final first = await ExolixApi.getCurrencies(
        page: page,
        size: pageSize,
        withNetworks: true,
      );
      collected.addAll(first.data);
      final total = first.count;

      while (collected.length < total && first.data.isNotEmpty) {
        page += 1;
        final next = await ExolixApi.getCurrencies(
          page: page,
          size: pageSize,
          withNetworks: true,
        );
        if (next.data.isEmpty) {
          // Server says we're done even though count disagrees — stop rather
          // than loop forever.
          break;
        }
        collected.addAll(next.data);
      }

      final results = <Currency>[];
      for (final currency in collected) {
        for (final net in currency.networks) {
          results.add(
            Currency(
              exchangeName: exchangeName,
              ticker: currency.code,
              name: net.isDefault
                  ? currency.name
                  : "${currency.name} (${net.shortName})",
              network: net.network,
              image: net.icon ?? currency.icon ?? "",
              isFiat: false,
              rateType: .both,
              isStackCoin: AppConfig.isStackCoin(currency.code),
              tokenContract: net.contract,
              isAvailable: true,
            ),
          );
        }
      }

      return ExchangeResponse(value: results);
    } on ExchangeException catch (e) {
      return ExchangeResponse(exception: e);
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
      final response = await ExolixApi.getRate(
        coinFrom: from,
        coinTo: to,
        networkFrom: fromNetwork,
        networkTo: toNetwork,
        amount: reversed ? null : amount,
        withdrawalAmount: reversed ? amount : null,
        rateType: fixedRate ? .fixed : .float,
      );

      final estimate = Estimate(
        estimatedAmount: reversed ? response.fromAmount : response.toAmount,
        fixedRate: fixedRate,
        reversed: reversed,
        exchangeProvider: exchangeName,
      );

      return ExchangeResponse(value: [estimate]);
    } on ExchangeException catch (e) {
      return ExchangeResponse(exception: e);
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
  Future<ExchangeResponse<Range>> getRange(
    String from,
    String? fromNetwork,
    String to,
    String? toNetwork,
    bool fixedRate,
  ) async {
    try {
      final response = await ExolixApi.getRate(
        coinFrom: from,
        coinTo: to,
        networkFrom: fromNetwork,
        networkTo: toNetwork,
        amount: Decimal.one, // hack in a random value placeholder I guess?
        rateType: fixedRate ? .fixed : .float,
      );

      return ExchangeResponse(
        value: Range(min: response.minAmount, max: response.maxAmount),
      );
    } on ExchangeException catch (e) {
      return ExchangeResponse(exception: e);
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
      throw UnimplementedError("Not currently used in this app");
    } catch (e) {
      return ExchangeResponse<Trade>(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  @override
  Future<ExchangeResponse<List<Trade>>> getTrades() async {
    try {
      throw UnimplementedError("Not currently used in this app");
    } catch (e) {
      return ExchangeResponse<List<Trade>>(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  @override
  Future<ExchangeResponse<Trade>> updateTrade(Trade trade) async {
    try {
      final result = await ExolixApi.getTransaction(id: trade.tradeId);

      return ExchangeResponse(
        value: Trade(
          uuid: trade.uuid,
          tradeId: result.id,
          rateType: result.rateType == .float ? "estimated" : "fixed",
          direction: trade.direction,
          timestamp: result.createdAt ?? DateTime.now(),
          updatedAt: result.createdAt ?? DateTime.now(),
          payInCurrency: result.coinFrom.coinCode,
          payInAmount: result.amount.toString(),
          payInAddress: result.depositAddress,
          payInNetwork: result.coinFrom.network,
          payInExtraId: result.depositExtraId ?? "",
          payInTxid: result.hashIn.hash ?? "",
          payOutCurrency: result.coinTo.coinCode,
          payOutAmount: result.amountTo.toString(),
          payOutAddress: result.withdrawalAddress,
          payOutNetwork: result.coinTo.network,
          payOutExtraId: result.withdrawalExtraId ?? "",
          payOutTxid: result.hashOut.hash ?? "",
          refundAddress: result.refundAddress ?? trade.refundAddress,
          refundExtraId: result.refundExtraId ?? trade.refundExtraId,
          status: result.status.name,
          exchangeName: exchangeName,
        ),
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
