import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:stackwallet/external_api_keys.dart';
import 'package:stackwallet/models/exchange/response_objects/pair.dart';
import 'package:stackwallet/models/exchange/response_objects/range.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/models/exchange/simpleswap/sp_currency.dart';
import 'package:stackwallet/services/exchange/exchange_response.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';

class SimpleSwapAPI {
  static const String scheme = "https";
  static const String authority = "api.simpleswap.io";

  SimpleSwapAPI._();
  static final SimpleSwapAPI _instance = SimpleSwapAPI._();
  static SimpleSwapAPI get instance => _instance;

  /// set this to override using standard http client. Useful for testing
  http.Client? client;

  Uri _buildUri(String path, Map<String, String>? params) {
    return Uri.https(authority, path, params);
  }

  Future<dynamic> _makeGetRequest(Uri uri) async {
    final client = this.client ?? http.Client();
    try {
      final response = await client.get(
        uri,
      );

      final parsed = jsonDecode(response.body);
      print("PARSED: $parsed");

      return parsed;
    } catch (e, s) {
      Logging.instance
          .log("_makeRequest($uri) threw: $e\n$s", level: LogLevel.Error);
      rethrow;
    }
  }

  Future<dynamic> _makePostRequest(
    Uri uri,
    Map<String, dynamic> body,
  ) async {
    final client = this.client ?? http.Client();
    try {
      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        return parsed;
      }

      throw Exception("response: ${response.body}");
    } catch (e, s) {
      Logging.instance
          .log("_makeRequest($uri) threw: $e\n$s", level: LogLevel.Error);
      rethrow;
    }
  }

  Future<ExchangeResponse<Trade>> createNewExchange({
    required bool isFixedRate,
    required String currencyFrom,
    required String currencyTo,
    required String addressTo,
    required String userRefundAddress,
    required String userRefundExtraId,
    required String amount,
    String? extraIdTo,
    String? apiKey,
  }) async {
    Map<String, dynamic> body = {
      "fixed": isFixedRate,
      "currency_from": currencyFrom,
      "currency_to": currencyTo,
      "addressTo": addressTo,
      "userRefundAddress": userRefundAddress,
      "userRefundExtraId": userRefundExtraId,
      "amount": double.parse(amount),
    };

    final uri =
        _buildUri("/create_exchange", {"api_key": apiKey ?? kSimpleSwapApiKey});

    try {
      final jsonObject = await _makePostRequest(uri, body);
      print("================================");
      print(jsonObject);
      print("================================");

      final json = Map<String, dynamic>.from(jsonObject as Map);
      final trade = Trade(
        uuid: const Uuid().v1(),
        tradeId: json["id"] as String,
        rateType: json["type"] as String,
        direction: "direct",
        timestamp: DateTime.parse(json["timestamp"] as String),
        updatedAt: DateTime.parse(json["updated_at"] as String),
        payInCurrency: json["currency_from"] as String,
        payInAmount: json["amount_from"] as String,
        payInAddress: json["address_from"] as String,
        payInNetwork: "",
        payInExtraId: json["extra_id_payIn"] as String,
        payInTxid: json["tx_from"] as String,
        payOutCurrency: json["currency_to"] as String,
        payOutAmount: json["amount_to"] as String,
        payOutAddress: json["address_to"] as String,
        payOutNetwork: "",
        payOutExtraId: json["extra_id_to"] as String? ?? "",
        payOutTxid: json["tx_to"] as String,
        refundAddress: json["user_refund_address"] as String,
        refundExtraId: json["user_refund_extra_id"] as String,
        status: json["status"] as String,
      );
      return ExchangeResponse(value: trade, exception: null);
    } catch (e, s) {
      Logging.instance.log("getAvailableCurrencies exception: $e\n$s",
          level: LogLevel.Error);
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
        value: null,
      );
    }
  }

  Future<ExchangeResponse<List<SPCurrency>>> getAllCurrencies({
    String? apiKey,
    required bool fixedRate,
  }) async {
    final uri = _buildUri(
        "/get_all_currencies", {"api_key": apiKey ?? kSimpleSwapApiKey});

    try {
      final jsonArray = await _makeGetRequest(uri);

      return await compute(_parseAvailableCurrenciesJson, jsonArray as List);
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

  ExchangeResponse<List<SPCurrency>> _parseAvailableCurrenciesJson(
      List<dynamic> jsonArray) {
    try {
      List<SPCurrency> currencies = [];

      for (final json in jsonArray) {
        try {
          currencies
              .add(SPCurrency.fromJson(Map<String, dynamic>.from(json as Map)));
        } catch (_) {
          return ExchangeResponse(
              exception: ExchangeException("Failed to serialize $json",
                  ExchangeExceptionType.serializeResponseError));
        }
      }

      return ExchangeResponse(value: currencies);
    } catch (e, s) {
      Logging.instance.log("_parseAvailableCurrenciesJson exception: $e\n$s",
          level: LogLevel.Error);
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  Future<ExchangeResponse<SPCurrency>> getCurrency({
    required String symbol,
    String? apiKey,
  }) async {
    final uri = _buildUri(
      "/get_currency",
      {
        "api_key": apiKey ?? kSimpleSwapApiKey,
        "symbol": symbol,
      },
    );

    try {
      final jsonObject = await _makeGetRequest(uri);

      return ExchangeResponse(
          value: SPCurrency.fromJson(
              Map<String, dynamic>.from(jsonObject as Map)));
    } catch (e, s) {
      Logging.instance
          .log("getCurrency exception: $e\n$s", level: LogLevel.Error);
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  /// returns a map where the key currency symbol is a valid pair with any of
  /// the symbols in its value list
  Future<ExchangeResponse<List<Pair>>> getAllPairs({
    required bool isFixedRate,
    String? apiKey,
  }) async {
    final uri = _buildUri(
      "/get_all_pairs",
      {
        "api_key": apiKey ?? kSimpleSwapApiKey,
        "fixed": isFixedRate.toString(),
      },
    );

    try {
      final jsonObject = await _makeGetRequest(uri);
      final result = await compute(
        _parseAvailablePairsJson,
        Tuple2(jsonObject as Map, isFixedRate),
      );
      return result;
    } catch (e, s) {
      Logging.instance
          .log("getAllPairs exception: $e\n$s", level: LogLevel.Error);
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  ExchangeResponse<List<Pair>> _parseAvailablePairsJson(
    Tuple2<Map<dynamic, dynamic>, bool> args,
  ) {
    try {
      List<Pair> pairs = [];

      for (final entry in args.item1.entries) {
        try {
          final from = entry.key as String;
          for (final to in entry.value as List) {
            pairs.add(
              Pair(
                from: from,
                fromNetwork: "",
                to: to as String,
                toNetwork: "",
                fixedRate: args.item2,
                floatingRate: !args.item2,
              ),
            );
          }
        } catch (_) {
          return ExchangeResponse(
              exception: ExchangeException("Failed to serialize $json",
                  ExchangeExceptionType.serializeResponseError));
        }
      }

      return ExchangeResponse(value: pairs);
    } catch (e, s) {
      Logging.instance.log("_parseAvailableCurrenciesJson exception: $e\n$s",
          level: LogLevel.Error);
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  /// returns the estimated amount as a string
  Future<ExchangeResponse<String>> getEstimated({
    required bool isFixedRate,
    required String currencyFrom,
    required String currencyTo,
    required String amount,
    String? apiKey,
  }) async {
    final uri = _buildUri(
      "/get_estimated",
      {
        "api_key": apiKey ?? kSimpleSwapApiKey,
        "fixed": isFixedRate.toString(),
        "currency_from": currencyFrom,
        "currency_to": currencyTo,
        "amount": amount,
      },
    );

    try {
      final jsonObject = await _makeGetRequest(uri);

      return ExchangeResponse(value: jsonObject as String);
    } catch (e, s) {
      Logging.instance
          .log("getEstimated exception: $e\n$s", level: LogLevel.Error);
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  /// returns the exchange for the given id
  Future<ExchangeResponse<Trade>> getExchange({
    required String exchangeId,
    String? apiKey,
  }) async {
    final uri = _buildUri(
      "/get_exchange",
      {
        "api_key": apiKey ?? kSimpleSwapApiKey,
        "id": exchangeId,
      },
    );

    try {
      final jsonObject = await _makeGetRequest(uri);

      final json = Map<String, dynamic>.from(jsonObject as Map);
      final ts = DateTime.parse(json["timestamp"] as String);
      final trade = Trade(
        uuid: const Uuid().v1(),
        tradeId: json["id"] as String,
        rateType: json["type"] as String,
        direction: "direct",
        timestamp: ts,
        updatedAt: DateTime.tryParse(json["updated_at"] as String? ?? "") ?? ts,
        payInCurrency: json["currency_from"] as String,
        payInAmount: json["amount_from"] as String,
        payInAddress: json["address_from"] as String,
        payInNetwork: "",
        payInExtraId: json["extra_id_payIn"] as String,
        payInTxid: json["tx_from"] as String,
        payOutCurrency: json["currency_to"] as String,
        payOutAmount: json["amount_to"] as String,
        payOutAddress: json["address_to"] as String,
        payOutNetwork: "",
        payOutExtraId: json["extra_id_to"] as String? ?? "",
        payOutTxid: json["tx_to"] as String,
        refundAddress: json["user_refund_address"] as String,
        refundExtraId: json["user_refund_extra_id"] as String,
        status: json["status"] as String,
      );

      return ExchangeResponse(value: trade);
    } catch (e, s) {
      Logging.instance
          .log("getExchange exception: $e\n$s", level: LogLevel.Error);
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  /// returns the minimal exchange amount
  Future<ExchangeResponse<Range>> getRange({
    required bool isFixedRate,
    required String currencyFrom,
    required String currencyTo,
    String? apiKey,
  }) async {
    final uri = _buildUri(
      "/get_ranges",
      {
        "api_key": apiKey ?? kSimpleSwapApiKey,
        "fixed": isFixedRate.toString(),
        "currency_from": currencyFrom,
        "currency_to": currencyTo,
      },
    );

    try {
      final jsonObject = await _makeGetRequest(uri);

      final json = Map<String, dynamic>.from(jsonObject as Map);
      return ExchangeResponse(
        value: Range(
          max: Decimal.tryParse(json["max"] as String? ?? ""),
          min: Decimal.tryParse(json["min"] as String? ?? ""),
        ),
      );
    } catch (e, s) {
      Logging.instance.log("getRange exception: $e\n$s", level: LogLevel.Error);
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }
}
