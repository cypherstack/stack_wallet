import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:stackwallet/exceptions/exchange/exchange_exception.dart';
import 'package:stackwallet/external_api_keys.dart';
import 'package:stackwallet/models/exchange/change_now/cn_exchange_estimate.dart';
import 'package:stackwallet/models/exchange/change_now/estimated_exchange_amount.dart';
import 'package:stackwallet/models/exchange/change_now/exchange_transaction.dart';
import 'package:stackwallet/models/exchange/change_now/exchange_transaction_status.dart';
import 'package:stackwallet/models/exchange/response_objects/currency.dart';
import 'package:stackwallet/models/exchange/response_objects/estimate.dart';
import 'package:stackwallet/models/exchange/response_objects/fixed_rate_market.dart';
import 'package:stackwallet/models/exchange/response_objects/pair.dart';
import 'package:stackwallet/models/exchange/response_objects/range.dart';
import 'package:stackwallet/services/exchange/exchange_response.dart';
import 'package:stackwallet/utilities/logger.dart';

class ChangeNowAPI {
  static const String scheme = "https";
  static const String authority = "api.changenow.io";
  static const String apiVersion = "/v1";
  static const String apiVersionV2 = "/v2";

  ChangeNowAPI._();
  static final ChangeNowAPI _instance = ChangeNowAPI._();
  static ChangeNowAPI get instance => _instance;

  /// set this to override using standard http client. Useful for testing
  http.Client? client;

  Uri _buildUri(String path, Map<String, dynamic>? params) {
    return Uri.https(authority, apiVersion + path, params);
  }

  Uri _buildUriV2(String path, Map<String, dynamic>? params) {
    return Uri.https(authority, apiVersionV2 + path, params);
  }

  Future<dynamic> _makeGetRequest(Uri uri) async {
    final client = this.client ?? http.Client();
    try {
      final response = await client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final parsed = jsonDecode(response.body);

      return parsed;
    } catch (e, s) {
      Logging.instance
          .log("_makeRequest($uri) threw: $e\n$s", level: LogLevel.Error);
      rethrow;
    }
  }

  Future<dynamic> _makeGetRequestV2(Uri uri, String apiKey) async {
    final client = this.client ?? http.Client();
    try {
      final response = await client.get(
        uri,
        headers: {
          // 'Content-Type': 'application/json',
          'x-changenow-api-key': apiKey,
        },
      );

      final parsed = jsonDecode(response.body);

      return parsed;
    } catch (e, s) {
      Logging.instance
          .log("_makeRequestV2($uri) threw: $e\n$s", level: LogLevel.Error);
      rethrow;
    }
  }

  Future<dynamic> _makePostRequest(
    Uri uri,
    Map<String, String> body,
  ) async {
    final client = this.client ?? http.Client();
    try {
      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final parsed = jsonDecode(response.body);

      return parsed;
    } catch (e, s) {
      Logging.instance
          .log("_makeRequest($uri) threw: $e\n$s", level: LogLevel.Error);
      rethrow;
    }
  }

  /// This API endpoint returns the list of available currencies.
  ///
  /// Set [active] to true to return only active currencies.
  /// Set [fixedRate] to true to return only currencies available on a fixed-rate flow.
  Future<ExchangeResponse<List<Currency>>> getAvailableCurrencies({
    bool? fixedRate,
    bool? active,
  }) async {
    Map<String, dynamic>? params;

    if (active != null || fixedRate != null) {
      params = {};
      if (fixedRate != null) {
        params.addAll({"fixedRate": fixedRate.toString()});
      }
      if (active != null) {
        params.addAll({"active": active.toString()});
      }
    }

    final uri = _buildUri("/currencies", params);

    try {
      // json array is expected here
      final jsonArray = await _makeGetRequest(uri);

      try {
        final result = await compute(
            _parseAvailableCurrenciesJson, jsonArray as List<dynamic>);
        return result;
      } catch (e, s) {
        Logging.instance.log("getAvailableCurrencies exception: $e\n$s",
            level: LogLevel.Error);
        return ExchangeResponse(
          exception: ExchangeException(
            "Error: $jsonArray",
            ExchangeExceptionType.serializeResponseError,
          ),
        );
      }
    } catch (e, s) {
      Logging.instance.log("getAvailableCurrencies exception: $e\n$s",
          level: LogLevel.Error);
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  ExchangeResponse<List<Currency>> _parseAvailableCurrenciesJson(
      List<dynamic> jsonArray) {
    try {
      List<Currency> currencies = [];

      for (final json in jsonArray) {
        try {
          currencies
              .add(Currency.fromJson(Map<String, dynamic>.from(json as Map)));
        } catch (_) {
          return ExchangeResponse(
              exception: ExchangeException("Failed to serialize $json",
                  ExchangeExceptionType.serializeResponseError));
        }
      }

      return ExchangeResponse(value: currencies);
    } catch (_) {
      rethrow;
    }
  }

  /// This API endpoint returns the array of markets available for the specified currency be default.
  /// The availability of a particular pair is determined by the 'isAvailable' field.
  ///
  /// Required [ticker] to fetch paired currencies for.
  /// Set [fixedRate] to true to return only currencies available on a fixed-rate flow.
  Future<ExchangeResponse<List<Currency>>> getPairedCurrencies({
    required String ticker,
    bool? fixedRate,
  }) async {
    Map<String, dynamic>? params;

    if (fixedRate != null) {
      params = {};
      params.addAll({"fixedRate": fixedRate.toString()});
    }

    final uri = _buildUri("/currencies-to/$ticker", params);

    try {
      // json array is expected here
      final jsonArray = (await _makeGetRequest(uri)) as List;

      List<Currency> currencies = [];
      try {
        for (final json in jsonArray) {
          try {
            currencies
                .add(Currency.fromJson(Map<String, dynamic>.from(json as Map)));
          } catch (_) {
            return ExchangeResponse(
              exception: ExchangeException(
                "Failed to serialize $json",
                ExchangeExceptionType.serializeResponseError,
              ),
            );
          }
        }
      } catch (e, s) {
        Logging.instance.log("getPairedCurrencies exception: $e\n$s",
            level: LogLevel.Error);
        return ExchangeResponse(
            exception: ExchangeException("Error: $jsonArray",
                ExchangeExceptionType.serializeResponseError));
      }
      return ExchangeResponse(value: currencies);
    } catch (e, s) {
      Logging.instance
          .log("getPairedCurrencies exception: $e\n$s", level: LogLevel.Error);
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  /// The API endpoint returns minimal payment amount required to make
  /// an exchange of [fromTicker] to [toTicker].
  /// If you try to exchange less, the transaction will most likely fail.
  Future<ExchangeResponse<Decimal>> getMinimalExchangeAmount({
    required String fromTicker,
    required String toTicker,
    String? apiKey,
  }) async {
    Map<String, dynamic>? params = {"api_key": apiKey ?? kChangeNowApiKey};

    final uri = _buildUri("/min-amount/${fromTicker}_$toTicker", params);

    try {
      // simple json object is expected here
      final json = await _makeGetRequest(uri);

      try {
        final value = Decimal.parse(json["minAmount"].toString());
        return ExchangeResponse(value: value);
      } catch (_) {
        return ExchangeResponse(
          exception: ExchangeException(
            "Failed to serialize $json",
            ExchangeExceptionType.serializeResponseError,
          ),
        );
      }
    } catch (e, s) {
      Logging.instance.log("getMinimalExchangeAmount exception: $e\n$s",
          level: LogLevel.Error);
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  /// The API endpoint returns minimal payment amount and maximum payment amount
  /// required to make an exchange. If you try to exchange less than minimum or
  /// more than maximum, the transaction will most likely fail. Any pair of
  /// assets has minimum amount and some of pairs have maximum amount.
  Future<ExchangeResponse<Range>> getRange({
    required String fromTicker,
    required String toTicker,
    required bool isFixedRate,
    String? apiKey,
  }) async {
    Map<String, dynamic>? params = {"api_key": apiKey ?? kChangeNowApiKey};

    final uri = _buildUri(
        "/exchange-range${isFixedRate ? "/fixed-rate" : ""}/${fromTicker}_$toTicker",
        params);

    try {
      final jsonObject = await _makeGetRequest(uri);

      final json = Map<String, dynamic>.from(jsonObject as Map);
      return ExchangeResponse(
        value: Range(
          max: Decimal.tryParse(json["maxAmount"]?.toString() ?? ""),
          min: Decimal.tryParse(json["minAmount"]?.toString() ?? ""),
        ),
      );
    } catch (e, s) {
      Logging.instance.log(
        "getRange exception: $e\n$s",
        level: LogLevel.Error,
      );
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  /// Get estimated amount of [toTicker] cryptocurrency to receive
  /// for [fromAmount] of [fromTicker]
  Future<ExchangeResponse<Estimate>> getEstimatedExchangeAmount({
    required String fromTicker,
    required String toTicker,
    required Decimal fromAmount,
    String? apiKey,
  }) async {
    Map<String, dynamic> params = {"api_key": apiKey ?? kChangeNowApiKey};

    final uri = _buildUri(
      "/exchange-amount/${fromAmount.toString()}/${fromTicker}_$toTicker",
      params,
    );

    try {
      // simple json object is expected here
      final json = await _makeGetRequest(uri);

      try {
        final value = EstimatedExchangeAmount.fromJson(
            Map<String, dynamic>.from(json as Map));
        return ExchangeResponse(
          value: Estimate(
            estimatedAmount: value.estimatedAmount,
            fixedRate: false,
            reversed: false,
            rateId: value.rateId,
            warningMessage: value.warningMessage,
          ),
        );
      } catch (_) {
        return ExchangeResponse(
          exception: ExchangeException(
            "Failed to serialize $json",
            ExchangeExceptionType.serializeResponseError,
          ),
        );
      }
    } catch (e, s) {
      Logging.instance.log("getEstimatedExchangeAmount exception: $e\n$s",
          level: LogLevel.Error);
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  /// Get estimated amount of [toTicker] cryptocurrency to receive
  /// for [fromAmount] of [fromTicker]
  Future<ExchangeResponse<Estimate>> getEstimatedExchangeAmountFixedRate({
    required String fromTicker,
    required String toTicker,
    required Decimal fromAmount,
    required bool reversed,
    bool useRateId = true,
    String? apiKey,
  }) async {
    Map<String, dynamic> params = {
      "api_key": apiKey ?? kChangeNowApiKey,
      "useRateId": useRateId.toString(),
    };

    late final Uri uri;
    if (reversed) {
      uri = _buildUri(
        "/exchange-deposit/fixed-rate/${fromAmount.toString()}/${fromTicker}_$toTicker",
        params,
      );
    } else {
      uri = _buildUri(
        "/exchange-amount/fixed-rate/${fromAmount.toString()}/${fromTicker}_$toTicker",
        params,
      );
    }

    try {
      // simple json object is expected here
      final json = await _makeGetRequest(uri);

      try {
        final value = EstimatedExchangeAmount.fromJson(
            Map<String, dynamic>.from(json as Map));
        return ExchangeResponse(
          value: Estimate(
            estimatedAmount: value.estimatedAmount,
            fixedRate: true,
            reversed: reversed,
            rateId: value.rateId,
            warningMessage: value.warningMessage,
          ),
        );
      } catch (_) {
        return ExchangeResponse(
          exception: ExchangeException(
            "Failed to serialize $json",
            ExchangeExceptionType.serializeResponseError,
          ),
        );
      }
    } catch (e, s) {
      Logging.instance.log("getEstimatedExchangeAmount exception: $e\n$s",
          level: LogLevel.Error);
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  // old v1 version
  /// This API endpoint returns fixed-rate estimated exchange amount of
  /// [toTicker] cryptocurrency to receive for [fromAmount] of [fromTicker]
  // Future<ExchangeResponse<EstimatedExchangeAmount>>
  //     getEstimatedFixedRateExchangeAmount({
  //   required String fromTicker,
  //   required String toTicker,
  //   required Decimal fromAmount,
  //   // (Optional) Use rateId for fixed-rate flow. If this field is true, you
  //   // could use returned field "rateId" in next method for creating transaction
  //   // to freeze estimated amount that you got in this method. Current estimated
  //   // amount would be valid until time in field "validUntil"
  //   bool useRateId = true,
  //   String? apiKey,
  // }) async {
  //   Map<String, dynamic> params = {
  //     "api_key": apiKey ?? kChangeNowApiKey,
  //     "useRateId": useRateId.toString(),
  //   };
  //
  //   final uri = _buildUri(
  //     "/exchange-amount/fixed-rate/${fromAmount.toString()}/${fromTicker}_$toTicker",
  //     params,
  //   );
  //
  //   try {
  //     // simple json object is expected here
  //     final json = await _makeGetRequest(uri);
  //
  //     try {
  //       final value = EstimatedExchangeAmount.fromJson(
  //           Map<String, dynamic>.from(json as Map));
  //       return ExchangeResponse(value: value);
  //     } catch (_) {
  //       return ExchangeResponse(
  //         exception: ExchangeException(
  //           "Failed to serialize $json",
  //           ExchangeExceptionType.serializeResponseError,
  //         ),
  //       );
  //     }
  //   } catch (e, s) {
  //     Logging.instance.log(
  //         "getEstimatedFixedRateExchangeAmount exception: $e\n$s",
  //         level: LogLevel.Error);
  //     return ExchangeResponse(
  //       exception: ExchangeException(
  //         e.toString(),
  //         ExchangeExceptionType.generic,
  //       ),
  //     );
  //   }
  // }

  /// Get estimated amount of [toTicker] cryptocurrency to receive
  /// for [fromAmount] of [fromTicker]
  Future<ExchangeResponse<CNExchangeEstimate>> getEstimatedExchangeAmountV2({
    required String fromTicker,
    required String toTicker,
    required CNEstimateType fromOrTo,
    required Decimal amount,
    String? fromNetwork,
    String? toNetwork,
    CNFlowType flow = CNFlowType.standard,
    String? apiKey,
  }) async {
    Map<String, dynamic>? params = {
      "fromCurrency": fromTicker,
      "toCurrency": toTicker,
      "flow": flow.value,
      "type": fromOrTo.name,
    };

    switch (fromOrTo) {
      case CNEstimateType.direct:
        params["fromAmount"] = amount.toString();
        break;
      case CNEstimateType.reverse:
        params["toAmount"] = amount.toString();
        break;
    }

    if (fromNetwork != null) {
      params["fromNetwork"] = fromNetwork;
    }

    if (toNetwork != null) {
      params["toNetwork"] = toNetwork;
    }

    if (flow == CNFlowType.fixedRate) {
      params["useRateId"] = "true";
    }

    final uri = _buildUriV2("/exchange/estimated-amount", params);

    try {
      // simple json object is expected here
      final json = await _makeGetRequestV2(uri, apiKey ?? kChangeNowApiKey);

      try {
        final value =
            CNExchangeEstimate.fromJson(Map<String, dynamic>.from(json as Map));
        return ExchangeResponse(value: value);
      } catch (_) {
        return ExchangeResponse(
          exception: ExchangeException(
            "Failed to serialize $json",
            ExchangeExceptionType.serializeResponseError,
          ),
        );
      }
    } catch (e, s) {
      Logging.instance.log("getEstimatedExchangeAmountV2 exception: $e\n$s",
          level: LogLevel.Error);
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  /// This API endpoint returns the list of all the pairs available on a
  /// fixed-rate flow. Some currencies get enabled or disabled from time to
  /// time and the market info gets updates, so make sure to refresh the list
  /// occasionally. One time per minute is sufficient.
  Future<ExchangeResponse<List<FixedRateMarket>>> getAvailableFixedRateMarkets({
    String? apiKey,
  }) async {
    final uri = _buildUri(
        "/market-info/fixed-rate/${apiKey ?? kChangeNowApiKey}", null);

    try {
      // json array is expected here
      final jsonArray = await _makeGetRequest(uri);

      try {
        final result =
            await compute(_parseFixedRateMarketsJson, jsonArray as List);
        return result;
      } catch (e, s) {
        Logging.instance.log("getAvailableFixedRateMarkets exception: $e\n$s",
            level: LogLevel.Error);
        return ExchangeResponse(
          exception: ExchangeException(
            "Error: $jsonArray",
            ExchangeExceptionType.serializeResponseError,
          ),
        );
      }
    } catch (e, s) {
      Logging.instance.log("getAvailableFixedRateMarkets exception: $e\n$s",
          level: LogLevel.Error);
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  ExchangeResponse<List<FixedRateMarket>> _parseFixedRateMarketsJson(
      List<dynamic> jsonArray) {
    try {
      List<FixedRateMarket> markets = [];
      for (final json in jsonArray) {
        try {
          markets.add(
              FixedRateMarket.fromMap(Map<String, dynamic>.from(json as Map)));
        } catch (_) {
          return ExchangeResponse(
              exception: ExchangeException("Failed to serialize $json",
                  ExchangeExceptionType.serializeResponseError));
        }
      }
      return ExchangeResponse(value: markets);
    } catch (_) {
      rethrow;
    }
  }

  /// The API endpoint creates a transaction, generates an address for
  /// sending funds and returns transaction attributes.
  Future<ExchangeResponse<ExchangeTransaction>>
      createStandardExchangeTransaction({
    required String fromTicker,
    required String toTicker,
    required String receivingAddress,
    required Decimal amount,
    String extraId = "",
    String userId = "",
    String contactEmail = "",
    String refundAddress = "",
    String refundExtraId = "",
    String? apiKey,
  }) async {
    final Map<String, String> map = {
      "from": fromTicker,
      "to": toTicker,
      "address": receivingAddress,
      "amount": amount.toString(),
      "flow": "standard",
      "extraId": extraId,
      "userId": userId,
      "contactEmail": contactEmail,
      "refundAddress": refundAddress,
      "refundExtraId": refundExtraId,
    };

    final uri = _buildUri("/transactions/${apiKey ?? kChangeNowApiKey}", null);

    try {
      // simple json object is expected here
      final json = await _makePostRequest(uri, map);

      // pass in date to prevent using default 1970 date
      json["date"] = DateTime.now().toString();

      try {
        final value = ExchangeTransaction.fromJson(
            Map<String, dynamic>.from(json as Map));
        return ExchangeResponse(value: value);
      } catch (_) {
        return ExchangeResponse(
          exception: ExchangeException(
            "Failed to serialize $json",
            ExchangeExceptionType.serializeResponseError,
          ),
        );
      }
    } catch (e, s) {
      Logging.instance.log(
          "createStandardExchangeTransaction exception: $e\n$s",
          level: LogLevel.Error);
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  /// The API endpoint creates a transaction, generates an address for
  /// sending funds and returns transaction attributes.
  Future<ExchangeResponse<ExchangeTransaction>>
      createFixedRateExchangeTransaction({
    required String fromTicker,
    required String toTicker,
    required String receivingAddress,
    required Decimal amount,
    required String rateId,
    required bool reversed,
    String extraId = "",
    String userId = "",
    String contactEmail = "",
    String refundAddress = "",
    String refundExtraId = "",
    String? apiKey,
  }) async {
    final Map<String, String> map = {
      "from": fromTicker,
      "to": toTicker,
      "address": receivingAddress,
      "flow": "fixed-rate",
      "extraId": extraId,
      "userId": userId,
      "contactEmail": contactEmail,
      "refundAddress": refundAddress,
      "refundExtraId": refundExtraId,
      "rateId": rateId,
    };

    if (reversed) {
      map["result"] = amount.toString();
    } else {
      map["amount"] = amount.toString();
    }

    final uri = _buildUri(
      "/transactions/fixed-rate${reversed ? "/from-result" : ""}/${apiKey ?? kChangeNowApiKey}",
      null,
    );

    try {
      // simple json object is expected here
      final json = await _makePostRequest(uri, map);

      // pass in date to prevent using default 1970 date
      json["date"] = DateTime.now().toString();

      try {
        final value = ExchangeTransaction.fromJson(
            Map<String, dynamic>.from(json as Map));
        return ExchangeResponse(value: value);
      } catch (_) {
        return ExchangeResponse(
          exception: ExchangeException(
            "Failed to serialize $json",
            ExchangeExceptionType.serializeResponseError,
          ),
        );
      }
    } catch (e, s) {
      Logging.instance.log(
          "createFixedRateExchangeTransaction exception: $e\n$s",
          level: LogLevel.Error);
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  Future<ExchangeResponse<ExchangeTransactionStatus>> getTransactionStatus({
    required String id,
    String? apiKey,
  }) async {
    final uri =
        _buildUri("/transactions/$id/${apiKey ?? kChangeNowApiKey}", null);

    try {
      // simple json object is expected here
      final json = await _makeGetRequest(uri);

      try {
        final value = ExchangeTransactionStatus.fromJson(
            Map<String, dynamic>.from(json as Map));
        return ExchangeResponse(value: value);
      } catch (_) {
        return ExchangeResponse(
          exception: ExchangeException(
            "Failed to serialize $json",
            ExchangeExceptionType.serializeResponseError,
          ),
        );
      }
    } catch (e, s) {
      Logging.instance
          .log("getTransactionStatus exception: $e\n$s", level: LogLevel.Error);
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  Future<ExchangeResponse<List<Pair>>> getAvailableFloatingRatePairs({
    bool includePartners = false,
  }) async {
    final uri = _buildUri("/market-info/available-pairs",
        {"includePartners": includePartners.toString()});

    try {
      // json array is expected here
      final jsonArray = await _makeGetRequest(uri);

      try {
        final result = await compute(
            _parseAvailableFloatingRatePairsJson, jsonArray as List);
        return result;
      } catch (e, s) {
        Logging.instance.log("getAvailableFloatingRatePairs exception: $e\n$s",
            level: LogLevel.Error);
        return ExchangeResponse(
          exception: ExchangeException(
            "Error: $jsonArray",
            ExchangeExceptionType.serializeResponseError,
          ),
        );
      }
    } catch (e, s) {
      Logging.instance.log("getAvailableFloatingRatePairs exception: $e\n$s",
          level: LogLevel.Error);
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  ExchangeResponse<List<Pair>> _parseAvailableFloatingRatePairsJson(
      List<dynamic> jsonArray) {
    try {
      List<Pair> pairs = [];
      for (final json in jsonArray) {
        try {
          final List<String> stringPair = (json as String).split("_");
          pairs.add(
            Pair(
              from: stringPair[0],
              to: stringPair[1],
              fromNetwork: "",
              toNetwork: "",
              fixedRate: false,
              floatingRate: true,
            ),
          );
        } catch (_) {
          return ExchangeResponse(
              exception: ExchangeException("Failed to serialize $json",
                  ExchangeExceptionType.serializeResponseError));
        }
      }
      return ExchangeResponse(value: pairs);
    } catch (_) {
      rethrow;
    }
  }
}
