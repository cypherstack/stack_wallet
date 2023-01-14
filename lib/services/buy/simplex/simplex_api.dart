import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:stackwallet/models/buy/response_objects/crypto.dart';
// import 'package:stackwallet/models/exchange/response_objects/fixed_rate_market.dart';
// import 'package:stackwallet/models/exchange/response_objects/pair.dart';
// import 'package:stackwallet/models/exchange/response_objects/range.dart';
// import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/models/buy/response_objects/fiat.dart';
// import 'package:stackwallet/models/buy/response_objects/crypto.dart';
import 'package:stackwallet/services/buy/buy_response.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:tuple/tuple.dart';

class SimplexAPI {
  static const String scheme = "https";
  static const String authority = "sandbox-api.stackwallet.com";

  SimplexAPI._();
  static final SimplexAPI _instance = SimplexAPI._();
  static SimplexAPI get instance => _instance;

  /// set this to override using standard http client. Useful for testing
  http.Client? client;

  Uri _buildUri(String path, Map<String, String>? params) {
    return Uri.https(authority, path, params);
  }

  // Future<dynamic> _makeGetRequest(Uri uri) async {
  //   final client = this.client ?? http.Client();
  //   int code = -1;
  //   try {
  //     final response = await client.get(
  //       uri,
  //     );
  //
  //     code = response.statusCode;
  //
  //     final parsed = jsonDecode(response.body);
  //
  //     return parsed;
  //   } catch (e, s) {
  //     Logging.instance.log(
  //       "_makeRequest($uri) HTTP:$code threw: $e\n$s",
  //       level: LogLevel.Error,
  //     );
  //     rethrow;
  //   }
  // }
  //
  // Future<dynamic> _makePostRequest(
  //   Uri uri,
  //   Map<String, dynamic> body,
  // ) async {
  //   final client = this.client ?? http.Client();
  //   try {
  //     final response = await client.post(
  //       uri,
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode(body),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       final parsed = jsonDecode(response.body);
  //       return parsed;
  //     }
  //
  //     throw Exception("response: ${response.body}");
  //   } catch (e, s) {
  //     Logging.instance
  //         .log("_makeRequest($uri) threw: $e\n$s", level: LogLevel.Error);
  //     rethrow;
  //   }
  // }
  //
  // Future<ExchangeResponse<Trade>> createNewExchange({
  //   required bool isFixedRate,
  //   required String currencyFrom,
  //   required String currencyTo,
  //   required String addressTo,
  //   required String userRefundAddress,
  //   required String userRefundExtraId,
  //   required String amount,
  //   String? extraIdTo,
  //   String? apiKey,
  // }) async {
  //   Map<String, dynamic> body = {
  //     "fixed": isFixedRate,
  //     "currency_from": currencyFrom,
  //     "currency_to": currencyTo,
  //     "addressTo": addressTo,
  //     "userRefundAddress": userRefundAddress,
  //     "userRefundExtraId": userRefundExtraId,
  //     "amount": double.parse(amount),
  //     "extraIdTo": extraIdTo,
  //   };
  //
  //   final uri =
  //       _buildUri("/create_exchange", {"api_key": apiKey ?? kSimplexApiKey});
  //
  //   try {
  //     final jsonObject = await _makePostRequest(uri, body);
  //
  //     final json = Map<String, dynamic>.from(jsonObject as Map);
  //     final trade = Trade(
  //       uuid: const Uuid().v1(),
  //       tradeId: json["id"] as String,
  //       rateType: json["type"] as String,
  //       direction: "direct",
  //       timestamp: DateTime.parse(json["timestamp"] as String),
  //       updatedAt: DateTime.parse(json["updated_at"] as String),
  //       payInCurrency: json["currency_from"] as String,
  //       payInAmount: json["amount_from"] as String,
  //       payInAddress: json["address_from"] as String,
  //       payInNetwork: "",
  //       payInExtraId: json["extra_id_from"] as String? ?? "",
  //       payInTxid: json["tx_from"] as String? ?? "",
  //       payOutCurrency: json["currency_to"] as String,
  //       payOutAmount: json["amount_to"] as String,
  //       payOutAddress: json["address_to"] as String,
  //       payOutNetwork: "",
  //       payOutExtraId: json["extra_id_to"] as String? ?? "",
  //       payOutTxid: json["tx_to"] as String? ?? "",
  //       refundAddress: json["user_refund_address"] as String,
  //       refundExtraId: json["user_refund_extra_id"] as String,
  //       status: json["status"] as String,
  //       exchangeName: SimplexExchange.exchangeName,
  //     );
  //     return ExchangeResponse(value: trade, exception: null);
  //   } catch (e, s) {
  //     Logging.instance.log("getAvailableCurrencies exception: $e\n$s",
  //         level: LogLevel.Error);
  //     return ExchangeResponse(
  //       exception: ExchangeException(
  //         e.toString(),
  //         ExchangeExceptionType.generic,
  //       ),
  //       value: null,
  //     );
  //   }
  // }

  Future<BuyResponse<Tuple2<List<Crypto>, List<Fiat>>>> getSupported() async {
    // example for quote courtesy of @danrmiller
    // curl -H "Content-Type: application/json" -d '{"digital_currency": "BTC", "fiat_currency": "USD", "requested_currency": "USD", "requested_amount": 100}' http://sandbox-api.stackwallet.com/quote
    // official docs reference eg
    // curl --request GET \
    //      --url https://sandbox.test-simplexcc.com/v2/supported_crypto_currencies \
    //      --header 'accept: application/json'

    try {
      Map<String, String> headers = {
        'Content-Type': 'application/json',
      };
      String data =
          '{"digital_currency": "BTC", "fiat_currency": "USD", "requested_currency": "USD", "requested_amount": 100}';
      Uri url = Uri.parse('http://sandbox-api.stackwallet.com/quote');

      var res = await http.post(url, headers: headers, body: data);

      if (res.statusCode != 200) {
        throw Exception(
            'getAvailableCurrencies exception: statusCode= ${res.statusCode}');
      }

      final jsonArray = jsonDecode(res.body);

      return await compute(_parseSupported, jsonArray);
    } catch (e, s) {
      Logging.instance.log("getAvailableCurrencies exception: $e\n$s",
          level: LogLevel.Error);
      return BuyResponse(
        exception: BuyException(
          e.toString(),
          BuyExceptionType.generic,
        ),
      );
    }
  }

  BuyResponse<Tuple2<List<Crypto>, List<Fiat>>> _parseSupported(
      dynamic jsonArray) {
    try {
      List<Crypto> cryptos = [];
      List<Fiat> fiats = [];

      var supportedCryptos =
          jsonArray['result']['supported_digital_currencies'];
      // TODO map List<String> supportedCryptos to List<Crypto>
      for (final ticker in supportedCryptos as List) {
        cryptos.add(Crypto.fromJson({
          'ticker': ticker as String,
          'name': ticker,
          'image': "",
        }));
      }
      var supportedFiats = jsonArray['result']['supported_fiat_currencies'];
      // TODO map List<String> supportedFiats to List<Fiat>
      for (final ticker in supportedFiats as List) {
        fiats.add(Fiat.fromJson({
          'ticker': ticker as String,
          'name': ticker,
          'image': "",
        }));
      }

      return BuyResponse(value: Tuple2(cryptos, fiats));
    } catch (e, s) {
      Logging.instance
          .log("_parseSupported exception: $e\n$s", level: LogLevel.Error);
      return BuyResponse(
        exception: BuyException(
          e.toString(),
          BuyExceptionType.generic,
        ),
      );
    }
  }

  // Future<ExchangeResponse<SPCurrency>> getCurrency({
  //   required String symbol,
  //   String? apiKey,
  // }) async {
  //   final uri = _buildUri(
  //     "/get_currency",
  //     {
  //       "api_key": apiKey ?? kSimplexApiKey,
  //       "symbol": symbol,
  //     },
  //   );
  //
  //   try {
  //     final jsonObject = await _makeGetRequest(uri);
  //
  //     return ExchangeResponse(
  //         value: SPCurrency.fromJson(
  //             Map<String, dynamic>.from(jsonObject as Map)));
  //   } catch (e, s) {
  //     Logging.instance
  //         .log("getCurrency exception: $e\n$s", level: LogLevel.Error);
  //     return ExchangeResponse(
  //       exception: ExchangeException(
  //         e.toString(),
  //         ExchangeExceptionType.generic,
  //       ),
  //     );
  //   }
  // }
  //
  // /// returns a map where the key currency symbol is a valid pair with any of
  // /// the symbols in its value list
  // Future<ExchangeResponse<List<Pair>>> getAllPairs({
  //   required bool isFixedRate,
  //   String? apiKey,
  // }) async {
  //   final uri = _buildUri(
  //     "/get_all_pairs",
  //     {
  //       "api_key": apiKey ?? kSimplexApiKey,
  //       "fixed": isFixedRate.toString(),
  //     },
  //   );
  //
  //   try {
  //     final jsonObject = await _makeGetRequest(uri);
  //     final result = await compute(
  //       _parseAvailablePairsJson,
  //       Tuple2(jsonObject as Map, isFixedRate),
  //     );
  //     return result;
  //   } catch (e, s) {
  //     Logging.instance
  //         .log("getAllPairs exception: $e\n$s", level: LogLevel.Error);
  //     return ExchangeResponse(
  //       exception: ExchangeException(
  //         e.toString(),
  //         ExchangeExceptionType.generic,
  //       ),
  //     );
  //   }
  // }
  //
  // ExchangeResponse<List<Pair>> _parseAvailablePairsJson(
  //   Tuple2<Map<dynamic, dynamic>, bool> args,
  // ) {
  //   try {
  //     List<Pair> pairs = [];
  //
  //     for (final entry in args.item1.entries) {
  //       try {
  //         final from = entry.key as String;
  //         for (final to in entry.value as List) {
  //           pairs.add(
  //             Pair(
  //               from: from,
  //               fromNetwork: "",
  //               to: to as String,
  //               toNetwork: "",
  //               fixedRate: args.item2,
  //               floatingRate: !args.item2,
  //             ),
  //           );
  //         }
  //       } catch (_) {
  //         return ExchangeResponse(
  //             exception: ExchangeException("Failed to serialize $json",
  //                 ExchangeExceptionType.serializeResponseError));
  //       }
  //     }
  //
  //     return ExchangeResponse(value: pairs);
  //   } catch (e, s) {
  //     Logging.instance.log("_parseAvailableCurrenciesJson exception: $e\n$s",
  //         level: LogLevel.Error);
  //     return ExchangeResponse(
  //       exception: ExchangeException(
  //         e.toString(),
  //         ExchangeExceptionType.generic,
  //       ),
  //     );
  //   }
  // }
  //
  // /// returns the estimated amount as a string
  // Future<ExchangeResponse<String>> getEstimated({
  //   required bool isFixedRate,
  //   required String currencyFrom,
  //   required String currencyTo,
  //   required String amount,
  //   String? apiKey,
  // }) async {
  //   final uri = _buildUri(
  //     "/get_estimated",
  //     {
  //       "api_key": apiKey ?? kSimplexApiKey,
  //       "fixed": isFixedRate.toString(),
  //       "currency_from": currencyFrom,
  //       "currency_to": currencyTo,
  //       "amount": amount,
  //     },
  //   );
  //
  //   try {
  //     final jsonObject = await _makeGetRequest(uri);
  //
  //     return ExchangeResponse(value: jsonObject as String);
  //   } catch (e, s) {
  //     Logging.instance
  //         .log("getEstimated exception: $e\n$s", level: LogLevel.Error);
  //     return ExchangeResponse(
  //       exception: ExchangeException(
  //         e.toString(),
  //         ExchangeExceptionType.generic,
  //       ),
  //     );
  //   }
  // }
  //
  // /// returns the exchange for the given id
  // Future<ExchangeResponse<Trade>> getExchange({
  //   required String exchangeId,
  //   String? apiKey,
  //   Trade? oldTrade,
  // }) async {
  //   final uri = _buildUri(
  //     "/get_exchange",
  //     {
  //       "api_key": apiKey ?? kSimplexApiKey,
  //       "id": exchangeId,
  //     },
  //   );
  //
  //   try {
  //     final jsonObject = await _makeGetRequest(uri);
  //
  //     final json = Map<String, dynamic>.from(jsonObject as Map);
  //     final ts = DateTime.parse(json["timestamp"] as String);
  //     final trade = Trade(
  //       uuid: oldTrade?.uuid ?? const Uuid().v1(),
  //       tradeId: json["id"] as String,
  //       rateType: json["type"] as String,
  //       direction: "direct",
  //       timestamp: ts,
  //       updatedAt: DateTime.tryParse(json["updated_at"] as String? ?? "") ?? ts,
  //       payInCurrency: json["currency_from"] as String,
  //       payInAmount: json["amount_from"] as String,
  //       payInAddress: json["address_from"] as String,
  //       payInNetwork: "",
  //       payInExtraId: json["extra_id_from"] as String? ?? "",
  //       payInTxid: json["tx_from"] as String? ?? "",
  //       payOutCurrency: json["currency_to"] as String,
  //       payOutAmount: json["amount_to"] as String,
  //       payOutAddress: json["address_to"] as String,
  //       payOutNetwork: "",
  //       payOutExtraId: json["extra_id_to"] as String? ?? "",
  //       payOutTxid: json["tx_to"] as String? ?? "",
  //       refundAddress: json["user_refund_address"] as String,
  //       refundExtraId: json["user_refund_extra_id"] as String,
  //       status: json["status"] as String,
  //       exchangeName: SimplexExchange.exchangeName,
  //     );
  //
  //     return ExchangeResponse(value: trade);
  //   } catch (e, s) {
  //     Logging.instance
  //         .log("getExchange exception: $e\n$s", level: LogLevel.Error);
  //     return ExchangeResponse(
  //       exception: ExchangeException(
  //         e.toString(),
  //         ExchangeExceptionType.generic,
  //       ),
  //     );
  //   }
  // }
  //
  // /// returns the minimal exchange amount
  // Future<ExchangeResponse<Range>> getRange({
  //   required bool isFixedRate,
  //   required String currencyFrom,
  //   required String currencyTo,
  //   String? apiKey,
  // }) async {
  //   final uri = _buildUri(
  //     "/get_ranges",
  //     {
  //       "api_key": apiKey ?? kSimplexApiKey,
  //       "fixed": isFixedRate.toString(),
  //       "currency_from": currencyFrom,
  //       "currency_to": currencyTo,
  //     },
  //   );
  //
  //   try {
  //     final jsonObject = await _makeGetRequest(uri);
  //
  //     final json = Map<String, dynamic>.from(jsonObject as Map);
  //     return ExchangeResponse(
  //       value: Range(
  //         max: Decimal.tryParse(json["max"] as String? ?? ""),
  //         min: Decimal.tryParse(json["min"] as String? ?? ""),
  //       ),
  //     );
  //   } catch (e, s) {
  //     Logging.instance.log("getRange exception: $e\n$s", level: LogLevel.Error);
  //     return ExchangeResponse(
  //       exception: ExchangeException(
  //         e.toString(),
  //         ExchangeExceptionType.generic,
  //       ),
  //     );
  //   }
  // }
  //
  // Future<ExchangeResponse<List<FixedRateMarket>>> getFixedRateMarketInfo({
  //   String? apiKey,
  // }) async {
  //   final uri = _buildUri(
  //     "/get_market_info",
  //     null,
  //     // {
  //     //   "api_key": apiKey ?? kSimplexApiKey,
  //     //   "fixed": isFixedRate.toString(),
  //     //   "currency_from": currencyFrom,
  //     //   "currency_to": currencyTo,
  //     // },
  //   );
  //
  //   try {
  //     final jsonArray = await _makeGetRequest(uri);
  //
  //     try {
  //       final result = await compute(
  //         _parseFixedRateMarketsJson,
  //         jsonArray as List,
  //       );
  //       return result;
  //     } catch (e, s) {
  //       Logging.instance.log("getAvailableFixedRateMarkets exception: $e\n$s",
  //           level: LogLevel.Error);
  //       return ExchangeResponse(
  //         exception: ExchangeException(
  //           "Error: $jsonArray",
  //           ExchangeExceptionType.serializeResponseError,
  //         ),
  //       );
  //     }
  //   } catch (e, s) {
  //     Logging.instance.log("getAvailableFixedRateMarkets exception: $e\n$s",
  //         level: LogLevel.Error);
  //     return ExchangeResponse(
  //       exception: ExchangeException(
  //         e.toString(),
  //         ExchangeExceptionType.generic,
  //       ),
  //     );
  //   }
  // }
  //
  // ExchangeResponse<List<FixedRateMarket>> _parseFixedRateMarketsJson(
  //     List<dynamic> jsonArray) {
  //   try {
  //     final List<FixedRateMarket> markets = [];
  //     for (final json in jsonArray) {
  //       try {
  //         final map = Map<String, dynamic>.from(json as Map);
  //         markets.add(FixedRateMarket(
  //           from: map["currency_from"] as String,
  //           to: map["currency_to"] as String,
  //           min: Decimal.parse(map["min"] as String),
  //           max: Decimal.parse(map["max"] as String),
  //           rate: Decimal.parse(map["rate"] as String),
  //           minerFee: null,
  //         ));
  //       } catch (_) {
  //         return ExchangeResponse(
  //             exception: ExchangeException("Failed to serialize $json",
  //                 ExchangeExceptionType.serializeResponseError));
  //       }
  //     }
  //     return ExchangeResponse(value: markets);
  //   } catch (_) {
  //     rethrow;
  //   }
  // }
}
