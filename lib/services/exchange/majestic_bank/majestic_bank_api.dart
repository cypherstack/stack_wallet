import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/services/exchange/exchange_response.dart';
import 'package:stackwallet/services/exchange/majestic_bank/majestic_bank_exchange.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:uuid/uuid.dart';

class MajesticBankAPI {
  static const String scheme = "https";
  static const String authority = "majesticbank.sc";
  static const String version = "v1";
  static const String refCode = "";

  MajesticBankAPI._();

  static final MajesticBankAPI _instance = MajesticBankAPI._();

  static MajesticBankAPI get instance => _instance;

  /// set this to override using standard http client. Useful for testing
  http.Client? client;

  Uri _buildUri({required String endpoint, Map<String, String>? params}) {
    return Uri.https(authority, "/api/$version/$endpoint", params);
  }

  String getPrettyJSONString(jsonObject) {
    var encoder = const JsonEncoder.withIndent("     ");
    return encoder.convert(jsonObject);
  }

  Future<dynamic> _makeGetRequest(Uri uri) async {
    final client = this.client ?? http.Client();
    int code = -1;
    try {
      final response = await client.get(
        uri,
      );

      code = response.statusCode;
      print(response.body);

      final parsed = jsonDecode(response.body);

      return parsed;
    } catch (e, s) {
      Logging.instance.log(
        "_makeRequest($uri) HTTP:$code threw: $e\n$s",
        level: LogLevel.Error,
      );
      rethrow;
    }
  }

  Future<dynamic> getRates() async {
    final uri = _buildUri(
      endpoint: "rates",
    );

    try {
      final jsonObject = await _makeGetRequest(uri);

      return getPrettyJSONString(jsonObject);
    } catch (e, s) {
      Logging.instance.log("getRates exception: $e\n$s", level: LogLevel.Error);
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  Future<dynamic> calculateOrder() async {
    final uri = _buildUri(
      endpoint: "calculate",
    );

    try {
      final jsonObject = await _makeGetRequest(uri);

      return getPrettyJSONString(jsonObject);
    } catch (e, s) {
      Logging.instance
          .log("calculateOrder exception: $e\n$s", level: LogLevel.Error);
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  Future<ExchangeResponse<Trade>> createOrder({
    required String amount,
    required String fromCurrency,
    required String receiveCurrency,
    required String receiveAddress,
  }) async {
    final params = {
      "from_amount": amount,
      "from_currency": fromCurrency,
      "receive_currency": receiveCurrency,
      "receive_address": receiveAddress,
      "referral_code": refCode,
    };

    final uri = _buildUri(endpoint: "create", params: params);

    try {
      final now = DateTime.now();
      final jsonObject = await _makeGetRequest(uri);
      final json = Map<String, dynamic>.from(jsonObject as Map);

      final trade = Trade(
        uuid: const Uuid().v1(),
        tradeId: json["trx"] as String,
        rateType: "floating-rate",
        direction: "direct",
        timestamp: now,
        updatedAt: now,
        payInCurrency: json["from_currency"] as String,
        payInAmount: json["from_amount"] as String,
        payInAddress: json["address"] as String,
        payInNetwork: "",
        payInExtraId: "",
        payInTxid: "",
        payOutCurrency: json["receive_currency"] as String,
        payOutAmount: json["receive_amount"] as String,
        payOutAddress: json["receive_address"] as String,
        payOutNetwork: "",
        payOutExtraId: "",
        payOutTxid: "",
        refundAddress: "",
        refundExtraId: "",
        status: "Waiting",
        exchangeName: MajesticBankExchange.exchangeName,
      );
      return ExchangeResponse(value: trade);
    } catch (e, s) {
      Logging.instance
          .log("createOrder exception: $e\n$s", level: LogLevel.Error);
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  Future<ExchangeResponse<Trade>> createFixedRateOrder({
    required String amount,
    required String fromCurrency,
    required String receiveCurrency,
    required String receiveAddress,
    required bool reversed,
  }) async {
    final params = {
      "from_currency": fromCurrency,
      "receive_currency": receiveCurrency,
      "receive_address": receiveAddress,
      "referral_code": refCode,
    };

    if (reversed) {
      params["receive_amount"] = amount;
    } else {
      params["from_amount"] = amount;
    }

    final uri = _buildUri(endpoint: "pay", params: params);

    try {
      final now = DateTime.now();
      final jsonObject = await _makeGetRequest(uri);
      final json = Map<String, dynamic>.from(jsonObject as Map);

      final trade = Trade(
        uuid: const Uuid().v1(),
        tradeId: json["trx"] as String,
        rateType: "fixed-rate",
        direction: reversed ? "reversed" : "direct",
        timestamp: now,
        updatedAt: now,
        payInCurrency: json["from_currency"] as String,
        payInAmount: json["from_amount"] as String,
        payInAddress: json["address"] as String,
        payInNetwork: "",
        payInExtraId: "",
        payInTxid: "",
        payOutCurrency: json["receive_currency"] as String,
        payOutAmount: json["receive_amount"] as String,
        payOutAddress: json["receive_address"] as String,
        payOutNetwork: "",
        payOutExtraId: "",
        payOutTxid: "",
        refundAddress: "",
        refundExtraId: "",
        status: "Waiting",
        exchangeName: MajesticBankExchange.exchangeName,
      );
      return ExchangeResponse(value: trade);
    } catch (e, s) {
      Logging.instance
          .log("createFixedRateOrder exception: $e\n$s", level: LogLevel.Error);
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  Future<dynamic> trackOrder({required String orderId}) async {
    final uri = _buildUri(
      endpoint: "track",
    );

    try {
      final jsonObject = await _makeGetRequest(uri);

      return getPrettyJSONString(jsonObject);
    } catch (e, s) {
      Logging.instance
          .log("createOrder exception: $e\n$s", level: LogLevel.Error);
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }
}
