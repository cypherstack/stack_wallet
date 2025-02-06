import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../exceptions/exchange/exchange_exception.dart';
import '../../../external_api_keys.dart';
import '../../../networking/http.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/prefs.dart';
import '../../tor_service.dart';
import '../exchange_response.dart';
import 'api_response_models/n_currency.dart';
import 'api_response_models/n_estimate.dart';
import 'api_response_models/n_trade.dart';

class NanswapAPI {
  NanswapAPI._();

  static const authority = "api.nanswap.com";
  static const version = "v1";

  static NanswapAPI? _instance;
  static NanswapAPI get instance => _instance ??= NanswapAPI._();

  final _client = HTTP();

  Uri _buildUri({required String endpoint, Map<String, String>? params}) {
    return Uri.https(authority, "/$version/$endpoint", params);
  }

  Future<dynamic> _makeGetRequest(Uri uri) async {
    int code = -1;
    try {
      final response = await _client.get(
        url: uri,
        headers: {
          'Accept': 'application/json',
        },
        proxyInfo: Prefs.instance.useTor
            ? TorService.sharedInstance.getProxyInfo()
            : null,
      );

      code = response.code;

      final parsed = jsonDecode(response.body);

      return parsed;
    } catch (e, s) {
      Logging.instance.e(
        "NanswapAPI._makeRequest($uri) HTTP:$code threw: ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  Future<dynamic> _makePostRequest(
    Uri uri,
    Map<String, dynamic> body,
  ) async {
    int code = -1;
    try {
      final response = await _client.post(
        url: uri,
        headers: {
          'nanswap-api-key': kNanswapApiKey,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
        proxyInfo: Prefs.instance.useTor
            ? TorService.sharedInstance.getProxyInfo()
            : null,
      );

      code = response.code;

      final data = response.body;
      final parsed = jsonDecode(data);

      return parsed;
    } catch (e, s) {
      Logging.instance.e(
        "NanswapAPI._makePostRequest($uri) HTTP:$code threw: ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  // ============= API ===================================================

  // GET List of supported currencies
  // https://api.nanswap.com/v1/all-currencies
  //
  // Returns a Key => Value map of available currencies.
  //
  // The Key is the ticker, that can be used in the from and to params of the /get-estimate, /get-limit, /create-order.
  //
  // The Value is the currency info:
  //
  //     name
  //
  //     logo
  //
  //     network Network of the crypto.
  //
  //     hasExternalId Boolean. If the crypto require a memo/id.
  //
  //     feeless Boolean. If crypto has 0 network fees.
  //
  // HEADERS
  // Accept
  //
  // application/json
  Future<ExchangeResponse<List<NCurrency>>> getSupportedCurrencies() async {
    final uri = _buildUri(
      endpoint: "all-currencies",
    );

    try {
      final json = await _makeGetRequest(uri);

      final List<NCurrency> result = [];
      for (final key in (json as Map).keys) {
        final _map = json[key] as Map;
        _map["id"] = key;
        result.add(
          NCurrency.fromJson(
            Map<String, dynamic>.from(_map),
          ),
        );
      }

      return ExchangeResponse(value: result);
    } catch (e, s) {
      Logging.instance.e(
        "Nanswap.getSupportedCurrencies() exception: ",
        error: e,
        stackTrace: s,
      );
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  // GET Get estimate
  // https://api.nanswap.com/v1/get-estimate?from=XNO&to=BAN&amount=10
  //
  // Get estimated exchange amount.
  // HEADERS
  // Accept
  //
  // application/json
  // PARAMS
  //
  // from
  // XNO
  // Ticker from
  //
  // to
  // BAN
  // Ticker to
  //
  // amount
  // 10
  // Amount from
  Future<ExchangeResponse<NEstimate>> getEstimate({
    required String amountFrom,
    required String from,
    required String to,
  }) async {
    final uri = _buildUri(
      endpoint: "get-estimate",
      params: {
        "to": to.toUpperCase(),
        "from": from.toUpperCase(),
        "amount": amountFrom,
      },
    );

    try {
      final json = await _makeGetRequest(uri);

      try {
        final map = Map<String, dynamic>.from(json as Map);

        // not sure why the api responds without these sometimes...
        map["to"] ??= to.toUpperCase();
        map["from"] ??= from.toUpperCase();

        return ExchangeResponse(
          value: NEstimate.fromJson(
            map,
          ),
        );
      } catch (e, s) {
        Logging.instance.e(
          "Nanswap.getEstimate() response was: $json",
          error: e,
          stackTrace: s,
        );
        rethrow;
      }
    } catch (e, s) {
      Logging.instance.e(
        "Nanswap.getEstimate() exception: ",
        error: e,
        stackTrace: s,
      );
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  // GET Get estimate reverse
  // https://api.nanswap.com/v1/get-estimate-reverse?from=XNO&to=BAN&amount=1650
  //
  // (Only available for feeless crypto)
  //
  // Get estimate but reversed, it takes toAmount and returns the fromAmount
  // estimation. Allows to let user input directly their toAmount wanted.
  // HEADERS
  // Accept
  //
  // application/json
  // PARAMS
  // from
  // XNO
  // Ticker from
  //
  // to
  // BAN
  // Ticker to
  //
  // amount
  // 1650
  // Amount to
  Future<ExchangeResponse<NEstimate>> getEstimateReversed({
    required String amountTo,
    required String from,
    required String to,
  }) async {
    final uri = _buildUri(
      endpoint: "get-estimate-reverse",
      params: {
        "to": to.toUpperCase(),
        "from": from.toUpperCase(),
        "amount": amountTo,
      },
    );

    try {
      final json = await _makeGetRequest(uri);

      final map = Map<String, dynamic>.from(json as Map);

      // not sure why the api responds without these sometimes...
      map["to"] ??= to.toUpperCase();
      map["from"] ??= from.toUpperCase();

      return ExchangeResponse(
        value: NEstimate.fromJson(
          map,
        ),
      );
    } catch (e, s) {
      Logging.instance.e(
        "Nanswap.getEstimateReverse() exception: ",
        error: e,
        stackTrace: s,
      );
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  // GET Get order limit amount
  // https://api.nanswap.com/v1/get-limits?from=XNO&to=BAN
  //
  // Returns minimum and maximum from amount for a given pair. Maximum amount depends of current liquidity.
  // HEADERS
  // Accept
  //
  // application/json
  // PARAMS
  // from
  // XNO
  // Ticker from
  //
  // to
  // BAN
  // Ticker to
  Future<ExchangeResponse<({num minFrom, num maxFrom})>> getOrderLimits({
    required String from,
    required String to,
  }) async {
    final uri = _buildUri(
      endpoint: "get-limits",
      params: {
        "to": to.toUpperCase(),
        "from": from.toUpperCase(),
      },
    );

    try {
      final json = await _makeGetRequest(uri);

      return ExchangeResponse(
        value: (
          minFrom: json["min"] as num,
          maxFrom: json["max"] as num,
        ),
      );
    } catch (e, s) {
      Logging.instance.e(
        "Nanswap.getOrderLimits() exception: ",
        error: e,
        stackTrace: s,
      );
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  // POST Create a new order
  // https://api.nanswap.com/v1/create-order
  //
  // Create a new order and returns order data. You need to send the request body as JSON.
  // A valid API key is required in nanswap-api-key header for this request.
  // You can get one at https://nanswap.com/API
  // Request:
  //
  // * from ticker of currency you want to exchange
  // * to ticker of currency you want to receive
  // * amount The amount you want to send
  // * toAddress The address that will recieve the exchanged funds
  // * extraId (optional) Memo/Id of the toAddress
  //
  // * itemName (optional) An item name that will be displayed on transaction
  // page. Can be used by merchant to provide a better UX to users. Max 128 char.
  // * maxDurationSeconds (optional) Maximum seconds after what transaction
  // expires. Min: 30s Max: 259200s. Default to 72h or 5min if itemName is set
  // Reponse:
  //
  // * id Order id.
  // * from ticker of currency you want to exchange
  // * to ticker of currency you want to receive
  // * expectedAmountFrom The amount you want to send
  // * expectedAmountTo Estimated value that you will get based on the field expectedAmountFrom
  // * payinAddress Nanswap's address you need to send the funds to
  // * payinExtraId If present, the extra/memo id required for the payinAddress
  // * payoutAddress The address that will recieve the exchanged funds
  // * fullLink URL of the transaction
  // AUTHORIZATIONAPI Key
  // Key
  //
  // nanswap-api-key
  // Value
  //
  // <value>
  // HEADERS
  // nanswap-api-key
  //
  // API_KEY
  //
  // (Required)
  // Content-Type
  //
  // application/json
  // Accept
  //
  // application/json
  Future<ExchangeResponse<NTrade>> createOrder({
    required String from,
    required String to,
    required num fromAmount,
    required String toAddress,
    String? extraIdOrMemo,
  }) async {
    final uri = _buildUri(
      endpoint: "create-order",
    );

    final body = {
      "from": from.toUpperCase(),
      "to": to.toUpperCase(),
      "amount": fromAmount,
      "toAddress": toAddress,
    };

    if (extraIdOrMemo != null) {
      body["extraId"] = extraIdOrMemo;
    }

    try {
      final json = await _makePostRequest(uri, body);

      try {
        return ExchangeResponse(
          value: NTrade.fromJson(
            Map<String, dynamic>.from(json as Map),
          ),
        );
      } catch (_) {
        debugPrint(json.toString());
        rethrow;
      }
    } catch (e, s) {
      Logging.instance.e(
        "Nanswap.createOrder() exception: ",
        error: e,
        stackTrace: s,
      );
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  // GET Get order id data
  // https://api.nanswap.com/v1/get-order?id=zYkxDxfmYRM
  //
  // Returns data of an order id.
  // Response:
  //
  //     id Order id.
  //
  //     status Order status, can be one of the following : [waiting, exchanging, sending, completed, error]
  //
  //     from ticker of currency you want to exchange
  //
  //     fromNetwork network of the currency you want to exchange.
  //
  //     to ticker of currency you want to receive
  //
  //     toNetwork network of the currency you want to receive.
  //
  //     expectedAmountFrom The amount you want to send
  //
  //     expectedAmountTo Estimated value that you will get based on the field expectedAmountFrom
  //
  //     amountFrom From Amount Exchanged
  //
  //     amountTo To Amount Exchanged
  //
  //     payinAddress Nanswap's address you need to send the funds to
  //
  //     payinExtraId If present, the extra/memo id required for the payinAddress
  //
  //     payoutAddress The address that will recieve the exchanged funds
  //
  //     payinHash Hash of the transaction you sent us
  //
  //     senderAddress Address which sent us the funds
  //
  //     payoutHash Hash of the transaction we sent to you
  //
  // HEADERS
  // Accept
  //
  // application/json
  // PARAMS
  // id
  //
  // zYkxDxfmYRM
  //
  // The order id
  Future<ExchangeResponse<NTrade>> getOrder({required String id}) async {
    final uri = _buildUri(
      endpoint: "get-order",
      params: {
        "id": id,
      },
    );

    try {
      final json = await _makeGetRequest(uri);

      try {
        return ExchangeResponse(
          value: NTrade.fromJson(
            Map<String, dynamic>.from(json as Map),
          ),
        );
      } catch (_) {
        debugPrint(json.toString());
        rethrow;
      }
    } catch (e, s) {
      Logging.instance.e(
        "Nanswap.getOrder($id) exception: ",
        error: e,
        stackTrace: s,
      );
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }
}
