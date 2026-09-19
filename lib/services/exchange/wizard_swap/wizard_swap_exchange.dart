import 'package:decimal/decimal.dart';
import 'package:uuid/uuid.dart';

import '../../../app_config.dart';
import '../../../exceptions/exchange/exchange_exception.dart';
import '../../../external_api_keys.dart';
import '../../../models/exchange/response_objects/estimate.dart';
import '../../../models/exchange/response_objects/range.dart';
import '../../../models/exchange/response_objects/trade.dart';
import '../../../models/isar/exchange_cache/currency.dart';
import '../exchange.dart';
import '../exchange_response.dart';
import 'wizard_swap_api.dart';

class WizardSwapExchange extends Exchange {
  WizardSwapExchange._();

  static WizardSwapExchange? _instance;
  static WizardSwapExchange get instance =>
      _instance ??= WizardSwapExchange._();

  static const exchangeName = "Wizard Swap";

  @override
  String get name => exchangeName;

  @override
  Future<ExchangeResponse<Trade>> createTrade({
    required String from,
    required String to,
    required String? fromNetwork,
    required String? toNetwork,
    required Decimal amount,
    required String addressTo,
    String? extraId,
    required String addressRefund,
    required String refundExtraId,
    Estimate? estimate,
    bool fixedRate = false,
    bool reversed = false,
  }) async {
    try {
      if (reversed) {
        throw ExchangeException(
          "$runtimeType does not support reversed trades",
          ExchangeExceptionType.generic,
        );
      }
      if (fixedRate) {
        throw ExchangeException(
          "$runtimeType does not support fixedRate trades",
          ExchangeExceptionType.generic,
        );
      }

      final json = await WizardSwapApi.postExchange(
        from,
        to,
        addressTo,
        amount,
        addressRefund,
        extraId,
        refundExtraId,
        kWizSwapApiKey,
      );

      // since the wizard swap api is somewhat lacking we'll make some
      // assumptions regarding date
      final timestamp = DateTime.parse(
        "${(json["timestamp"] as String).replaceFirst(" ", "T")}Z",
      );

      final trade = Trade(
        uuid: const Uuid().v1(),
        tradeId: json["id"] as String,
        rateType: "estimated",
        direction: "normal",
        timestamp: timestamp,
        updatedAt: timestamp,
        payInCurrency: from,
        payInAmount: json["expected_amount"] as String,
        payInAddress: json["address_from"] as String,
        payInNetwork: from, // need something here...
        payInExtraId: json["extra_id_from"] as String,
        payInTxid: json["tx_from"] as String,
        payOutCurrency: to,
        payOutAmount: json["amount_to"] as String,
        payOutAddress: json["address_to"] as String,
        payOutNetwork: to, // need something here...
        payOutExtraId: json["extra_id_to"] as String,
        payOutTxid: json["tx_to"] as String,
        refundAddress: json["refund_address"] as String? ?? addressRefund,
        refundExtraId: refundExtraId,
        status: json["status"] as String? ?? "unknown",
        exchangeName: exchangeName,
      );

      return ExchangeResponse(value: trade);
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
  Future<ExchangeResponse<List<Currency>>> getAllCurrencies(
    bool fixedRate,
  ) async {
    try {
      if (fixedRate) {
        throw ExchangeException(
          "$runtimeType does not support fixedRate",
          ExchangeExceptionType.generic,
        );
      }

      final response = await WizardSwapApi.getCurrencies();

      final List<Currency> result = [];

      for (final json in response) {
        final ticker = json["symbol"] as String;

        // lol why do we even have to do this??? There is less info returned
        // by this call than in the json response for all currencies????????
        final info = await WizardSwapApi.getCurrencyInfo(ticker);

        final currency = Currency(
          exchangeName: exchangeName,
          ticker: json["symbol"] as String,
          name: json["name"] as String,
          network: json["parent_symbol"] as String? ?? ticker,
          image: info["image"] as String,
          isFiat: false,
          rateType: .estimated,
          isStackCoin: AppConfig.isStackCoin(ticker),
          tokenContract: null,
          isAvailable: json["enabled"] == 1,
        );

        result.add(currency);
      }

      return ExchangeResponse(value: result);
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
      if (reversed) {
        throw ExchangeException(
          "$runtimeType does not support reversed trades",
          ExchangeExceptionType.generic,
        );
      }
      if (fixedRate) {
        throw ExchangeException(
          "$runtimeType does not support fixedRate trades",
          ExchangeExceptionType.generic,
        );
      }

      final response = await WizardSwapApi.postEstimate(
        from,
        to,
        amount,
        kWizSwapApiKey,
      );

      final estimate = Estimate(
        estimatedAmount: response.amountTo,
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
      if (fixedRate) {
        throw ExchangeException(
          "$runtimeType does not support fixedRate trades",
          ExchangeExceptionType.generic,
        );
      }

      /// lol ????
      final all = await WizardSwapApi.getCurrencies();
      final coin = all.firstWhere(
        (e) =>
            e["symbol"].toString().toLowerCase() ==
            from.toString().toLowerCase(),
      );

      return ExchangeResponse(
        value: Range(min: Decimal.tryParse(coin["minamt"].toString())),
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
  Future<ExchangeResponse<List<Trade>>> getTrades() async {
    try {
      throw UnimplementedError("Not currently used in this app");
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
  Future<ExchangeResponse<Trade>> updateTrade(Trade trade) async {
    try {
      final json = await WizardSwapApi.getExchange(trade.tradeId);

      final updated = Trade(
        uuid: trade.uuid,
        tradeId: trade.tradeId,
        rateType: trade.rateType,
        direction: trade.direction,
        timestamp: trade.timestamp,
        updatedAt: DateTime.now(),
        payInCurrency: trade.payInCurrency,
        payInAmount: json["expected_amount"] as String,
        payInAddress: json["address_from"] as String,
        payInNetwork: trade.payInNetwork,
        payInExtraId: json["extra_id_from"] as String,
        payInTxid: json["tx_from"] as String,
        payOutCurrency: trade.payOutCurrency,
        payOutAmount: json["amount_to"] as String,
        payOutAddress: json["address_to"] as String,
        payOutNetwork: trade.payOutNetwork,
        payOutExtraId: json["extra_id_to"] as String,
        payOutTxid: json["tx_to"] as String,
        refundAddress: json["refund_address"] as String? ?? trade.refundAddress,
        refundExtraId: trade.refundExtraId,
        status: json["status"] as String? ?? "unknown",
        exchangeName: exchangeName,
      );

      return ExchangeResponse(value: updated);
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
}
