import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:stackwallet/external_api_keys.dart';
import 'package:stackwallet/models/exchange/change_now/available_floating_rate_pair.dart';
import 'package:stackwallet/models/exchange/change_now/change_now_response.dart';
import 'package:stackwallet/models/exchange/change_now/currency.dart';
import 'package:stackwallet/models/exchange/change_now/estimated_exchange_amount.dart';
import 'package:stackwallet/models/exchange/change_now/exchange_transaction.dart';
import 'package:stackwallet/models/exchange/change_now/exchange_transaction_status.dart';
import 'package:stackwallet/models/exchange/change_now/fixed_rate_market.dart';
import 'package:stackwallet/utilities/logger.dart';

abstract class ChangeNow {
  static const String scheme = "https";
  static const String authority = "api.changenow.io";
  static const String apiVersion = "/v1";

  static Uri _buildUri(String path, Map<String, dynamic>? params) {
    return Uri.https(authority, apiVersion + path, params);
  }

  static Future<dynamic> _makeGetRequest(Uri uri) async {
    final client = http.Client();
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

  static Future<dynamic> _makePostRequest(
    Uri uri,
    Map<String, String> body,
  ) async {
    final client = http.Client();
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
  static Future<ChangeNowResponse<List<Currency>>> getAvailableCurrencies({
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
        return ChangeNowResponse(
          exception: ChangeNowException(
            "Error: $jsonArray",
            ChangeNowExceptionType.serializeResponseError,
          ),
        );
      }
    } catch (e, s) {
      Logging.instance.log("getAvailableCurrencies exception: $e\n$s",
          level: LogLevel.Error);
      return ChangeNowResponse(
        exception: ChangeNowException(
          e.toString(),
          ChangeNowExceptionType.generic,
        ),
      );
    }
  }

  static ChangeNowResponse<List<Currency>> _parseAvailableCurrenciesJson(
      List<dynamic> jsonArray) {
    try {
      List<Currency> currencies = [];

      for (final json in jsonArray) {
        try {
          currencies
              .add(Currency.fromJson(Map<String, dynamic>.from(json as Map)));
        } catch (_) {
          return ChangeNowResponse(
            exception: ChangeNowException(
              "Failed to serialize $json",
              ChangeNowExceptionType.serializeResponseError,
            ),
          );
        }
      }

      return ChangeNowResponse(value: currencies);
    } catch (_) {
      rethrow;
    }
  }

  /// This API endpoint returns the array of markets available for the specified currency be default.
  /// The availability of a particular pair is determined by the 'isAvailable' field.
  ///
  /// Required [ticker] to fetch paired currencies for.
  /// Set [fixedRate] to true to return only currencies available on a fixed-rate flow.
  static Future<ChangeNowResponse<List<Currency>>> getPairedCurrencies({
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
            return ChangeNowResponse(
              exception: ChangeNowException(
                "Failed to serialize $json",
                ChangeNowExceptionType.serializeResponseError,
              ),
            );
          }
        }
      } catch (e, s) {
        Logging.instance.log("getPairedCurrencies exception: $e\n$s",
            level: LogLevel.Error);
        return ChangeNowResponse(
          exception: ChangeNowException(
            "Error: $jsonArray",
            ChangeNowExceptionType.serializeResponseError,
          ),
        );
      }
      return ChangeNowResponse(value: currencies);
    } catch (e, s) {
      Logging.instance
          .log("getPairedCurrencies exception: $e\n$s", level: LogLevel.Error);
      return ChangeNowResponse(
        exception: ChangeNowException(
          e.toString(),
          ChangeNowExceptionType.generic,
        ),
      );
    }
  }

  /// The API endpoint returns minimal payment amount required to make
  /// an exchange of [fromTicker] to [toTicker].
  /// If you try to exchange less, the transaction will most likely fail.
  static Future<ChangeNowResponse<Decimal>> getMinimalExchangeAmount({
    required String fromTicker,
    required String toTicker,
  }) async {
    Map<String, dynamic>? params = {"api_key": kChangeNowApiKey};

    final uri = _buildUri("/min-amount/${fromTicker}_$toTicker", params);

    try {
      // simple json object is expected here
      final json = await _makeGetRequest(uri);

      try {
        final value = Decimal.parse(json["minAmount"].toString());
        return ChangeNowResponse(value: value);
      } catch (_) {
        return ChangeNowResponse(
          exception: ChangeNowException(
            "Failed to serialize $json",
            ChangeNowExceptionType.serializeResponseError,
          ),
        );
      }
    } catch (e, s) {
      Logging.instance.log("getMinimalExchangeAmount exception: $e\n$s",
          level: LogLevel.Error);
      return ChangeNowResponse(
        exception: ChangeNowException(
          e.toString(),
          ChangeNowExceptionType.generic,
        ),
      );
    }
  }

  /// Get estimated amount of [toTicker] cryptocurrency to receive
  /// for [fromAmount] of [fromTicker]
  static Future<ChangeNowResponse<EstimatedExchangeAmount>>
      getEstimatedExchangeAmount({
    required String fromTicker,
    required String toTicker,
    required Decimal fromAmount,
  }) async {
    Map<String, dynamic> params = {"api_key": kChangeNowApiKey};

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
        return ChangeNowResponse(value: value);
      } catch (_) {
        return ChangeNowResponse(
          exception: ChangeNowException(
            "Failed to serialize $json",
            ChangeNowExceptionType.serializeResponseError,
          ),
        );
      }
    } catch (e, s) {
      Logging.instance.log("getEstimatedExchangeAmount exception: $e\n$s",
          level: LogLevel.Error);
      return ChangeNowResponse(
        exception: ChangeNowException(
          e.toString(),
          ChangeNowExceptionType.generic,
        ),
      );
    }
  }

  /// This API endpoint returns fixed-rate estimated exchange amount of
  /// [toTicker] cryptocurrency to receive for [fromAmount] of [fromTicker]
  static Future<ChangeNowResponse<EstimatedExchangeAmount>>
      getEstimatedFixedRateExchangeAmount({
    required String fromTicker,
    required String toTicker,
    required Decimal fromAmount,
    // (Optional) Use rateId for fixed-rate flow. If this field is true, you
    // could use returned field "rateId" in next method for creating transaction
    // to freeze estimated amount that you got in this method. Current estimated
    // amount would be valid until time in field "validUntil"
    bool useRateId = true,
  }) async {
    Map<String, dynamic> params = {
      "api_key": kChangeNowApiKey,
      "useRateId": useRateId.toString(),
    };

    final uri = _buildUri(
      "/exchange-amount/fixed-rate/${fromAmount.toString()}/${fromTicker}_$toTicker",
      params,
    );

    try {
      // simple json object is expected here
      final json = await _makeGetRequest(uri);

      try {
        final value = EstimatedExchangeAmount.fromJson(
            Map<String, dynamic>.from(json as Map));
        return ChangeNowResponse(value: value);
      } catch (_) {
        return ChangeNowResponse(
          exception: ChangeNowException(
            "Failed to serialize $json",
            ChangeNowExceptionType.serializeResponseError,
          ),
        );
      }
    } catch (e, s) {
      Logging.instance.log(
          "getEstimatedFixedRateExchangeAmount exception: $e\n$s",
          level: LogLevel.Error);
      return ChangeNowResponse(
        exception: ChangeNowException(
          e.toString(),
          ChangeNowExceptionType.generic,
        ),
      );
    }
  }

  /// This API endpoint returns the list of all the pairs available on a
  /// fixed-rate flow. Some currencies get enabled or disabled from time to
  /// time and the market info gets updates, so make sure to refresh the list
  /// occasionally. One time per minute is sufficient.
  static Future<ChangeNowResponse<List<FixedRateMarket>>>
      getAvailableFixedRateMarkets() async {
    final uri = _buildUri("/market-info/fixed-rate/$kChangeNowApiKey", null);

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
        return ChangeNowResponse(
          exception: ChangeNowException(
            "Error: $jsonArray",
            ChangeNowExceptionType.serializeResponseError,
          ),
        );
      }
    } catch (e, s) {
      Logging.instance.log("getAvailableFixedRateMarkets exception: $e\n$s",
          level: LogLevel.Error);
      return ChangeNowResponse(
        exception: ChangeNowException(
          e.toString(),
          ChangeNowExceptionType.generic,
        ),
      );
    }
  }

  static ChangeNowResponse<List<FixedRateMarket>> _parseFixedRateMarketsJson(
      List<dynamic> jsonArray) {
    try {
      List<FixedRateMarket> markets = [];
      for (final json in jsonArray) {
        try {
          markets.add(
              FixedRateMarket.fromJson(Map<String, dynamic>.from(json as Map)));
        } catch (_) {
          return ChangeNowResponse(
            exception: ChangeNowException(
              "Failed to serialize $json",
              ChangeNowExceptionType.serializeResponseError,
            ),
          );
        }
      }
      return ChangeNowResponse(value: markets);
    } catch (_) {
      rethrow;
    }
  }

  /// The API endpoint creates a transaction, generates an address for
  /// sending funds and returns transaction attributes.
  static Future<ChangeNowResponse<ExchangeTransaction>>
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

    final uri = _buildUri("/transactions/$kChangeNowApiKey", null);

    try {
      // simple json object is expected here
      final json = await _makePostRequest(uri, map);

      // pass in date to prevent using default 1970 date
      json["date"] = DateTime.now();

      try {
        final value = ExchangeTransaction.fromJson(
            Map<String, dynamic>.from(json as Map));
        return ChangeNowResponse(value: value);
      } catch (_) {
        return ChangeNowResponse(
          exception: ChangeNowException(
            "Failed to serialize $json",
            ChangeNowExceptionType.serializeResponseError,
          ),
        );
      }
    } catch (e, s) {
      Logging.instance.log(
          "createStandardExchangeTransaction exception: $e\n$s",
          level: LogLevel.Error);
      return ChangeNowResponse(
        exception: ChangeNowException(
          e.toString(),
          ChangeNowExceptionType.generic,
        ),
      );
    }
  }

  /// The API endpoint creates a transaction, generates an address for
  /// sending funds and returns transaction attributes.
  static Future<ChangeNowResponse<ExchangeTransaction>>
      createFixedRateExchangeTransaction({
    required String fromTicker,
    required String toTicker,
    required String receivingAddress,
    required Decimal amount,
    required String rateId,
    String extraId = "",
    String userId = "",
    String contactEmail = "",
    String refundAddress = "",
    String refundExtraId = "",
  }) async {
    final Map<String, String> map = {
      "from": fromTicker,
      "to": toTicker,
      "address": receivingAddress,
      "amount": amount.toString(),
      "flow": "fixed-rate",
      "extraId": extraId,
      "userId": userId,
      "contactEmail": contactEmail,
      "refundAddress": refundAddress,
      "refundExtraId": refundExtraId,
      "rateId": rateId,
    };

    final uri = _buildUri("/transactions/fixed-rate/$kChangeNowApiKey", null);

    try {
      // simple json object is expected here
      final json = await _makePostRequest(uri, map);

      // pass in date to prevent using default 1970 date
      json["date"] = DateTime.now();

      try {
        final value = ExchangeTransaction.fromJson(
            Map<String, dynamic>.from(json as Map));
        return ChangeNowResponse(value: value);
      } catch (_) {
        return ChangeNowResponse(
          exception: ChangeNowException(
            "Failed to serialize $json",
            ChangeNowExceptionType.serializeResponseError,
          ),
        );
      }
    } catch (e, s) {
      Logging.instance.log(
          "createFixedRateExchangeTransaction exception: $e\n$s",
          level: LogLevel.Error);
      return ChangeNowResponse(
        exception: ChangeNowException(
          e.toString(),
          ChangeNowExceptionType.generic,
        ),
      );
    }
  }

  static Future<ChangeNowResponse<ExchangeTransactionStatus>>
      getTransactionStatus({
    required String id,
  }) async {
    final uri = _buildUri("/transactions/$id/$kChangeNowApiKey", null);

    try {
      // simple json object is expected here
      final json = await _makeGetRequest(uri);

      try {
        final value = ExchangeTransactionStatus.fromJson(
            Map<String, dynamic>.from(json as Map));
        return ChangeNowResponse(value: value);
      } catch (_) {
        return ChangeNowResponse(
          exception: ChangeNowException(
            "Failed to serialize $json",
            ChangeNowExceptionType.serializeResponseError,
          ),
        );
      }
    } catch (e, s) {
      Logging.instance
          .log("getTransactionStatus exception: $e\n$s", level: LogLevel.Error);
      return ChangeNowResponse(
        exception: ChangeNowException(
          e.toString(),
          ChangeNowExceptionType.generic,
        ),
      );
    }
  }

  static Future<ChangeNowResponse<List<AvailableFloatingRatePair>>>
      getAvailableFloatingRatePairs({
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
        return ChangeNowResponse(
          exception: ChangeNowException(
            "Error: $jsonArray",
            ChangeNowExceptionType.serializeResponseError,
          ),
        );
      }
    } catch (e, s) {
      Logging.instance.log("getAvailableFloatingRatePairs exception: $e\n$s",
          level: LogLevel.Error);
      return ChangeNowResponse(
        exception: ChangeNowException(
          e.toString(),
          ChangeNowExceptionType.generic,
        ),
      );
    }
  }

  static ChangeNowResponse<List<AvailableFloatingRatePair>>
      _parseAvailableFloatingRatePairsJson(List<dynamic> jsonArray) {
    try {
      List<AvailableFloatingRatePair> pairs = [];
      for (final json in jsonArray) {
        try {
          final List<String> stringPair = (json as String).split("_");
          pairs.add(AvailableFloatingRatePair(
              fromTicker: stringPair[0], toTicker: stringPair[1]));
        } catch (_) {
          return ChangeNowResponse(
            exception: ChangeNowException(
              "Failed to serialize $json",
              ChangeNowExceptionType.serializeResponseError,
            ),
          );
        }
      }
      return ChangeNowResponse(value: pairs);
    } catch (_) {
      rethrow;
    }
  }
}
