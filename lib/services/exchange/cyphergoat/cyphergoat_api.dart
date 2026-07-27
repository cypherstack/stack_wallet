import 'dart:convert';

import 'package:decimal/decimal.dart';

import '../../../app_config.dart';
import '../../../exceptions/exchange/exchange_exception.dart';
import '../../../external_api_keys.dart';
import '../../../networking/http.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/prefs.dart';
import '../../tor_service.dart';
import '../exchange_response.dart';
import 'response_objects/cg_estimate.dart';
import 'response_objects/cg_transaction.dart';

const kCypherGoatSource = "stackwallet";

abstract class CypherGoatAPI {
  static const String authority = "api.cyphergoat.com";

  static const HTTP _client = HTTP();

  static Uri _buildUri({
    required String path,
    Map<String, String>? params,
  }) {
    return Uri.https(authority, path, params);
  }

  static Future<dynamic> _makeGetRequest(Uri uri) async {
    int code = -1;
    try {
      final headers = <String, String>{
        "Content-Type": "application/json",
        "Accept": "application/json",
      };
      if (kCypherGoatApiKey.isNotEmpty) {
        headers["Authorization"] = "Bearer $kCypherGoatApiKey";
      }

      final response = await _client.get(
        url: uri,
        headers: headers,
        proxyInfo: !AppConfig.hasFeature(AppFeature.tor)
            ? null
            : Prefs.instance.useTor
            ? TorService.sharedInstance.getProxyInfo()
            : null,
      );

      code = response.code;

      final json = jsonDecode(response.body);

      if (code != 200) {
        final errMsg = (json is Map ? json["error"] : null) as String?;
        throw Exception(errMsg ?? "HTTP $code: ${response.body}");
      }

      return json;
    } catch (e, s) {
      Logging.instance.e(
        "CypherGoatAPI GET $uri HTTP:$code threw:",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// GET /estimate
  /// Returns all exchange provider estimates for the given pair and amount.
  static Future<ExchangeResponse<({CgEstimatesResponse rates, Decimal min})>>
  getEstimate({
    required String coin1,
    required String network1,
    required String coin2,
    required String network2,
    required String amount,
  }) async {
    final params = <String, String>{
      "coin1": coin1.toLowerCase(),
      "network1": network1.toLowerCase(),
      "coin2": coin2.toLowerCase(),
      "network2": network2.toLowerCase(),
      "amount": amount,
      "best": "false",
    };

    if (kCypherGoatApiKey.isNotEmpty) {
      params["api_key"] = kCypherGoatApiKey;
    }

    final uri = _buildUri(path: "/estimate", params: params);

    try {
      final json = await _makeGetRequest(uri);
      final map = Map<String, dynamic>.from(json as Map);

      final ratesMap = map["rates"] as Map?;
      if (ratesMap == null) {
        throw Exception("Missing 'rates' in estimate response");
      }

      final rates = CgEstimatesResponse.fromMap(
        Map<String, dynamic>.from(ratesMap),
      );
      final min = map["min"] != null
          ? Decimal.parse(map["min"].toString())
          : rates.min;

      return ExchangeResponse(value: (rates: rates, min: min));
    } catch (e, s) {
      Logging.instance.e(
        "CypherGoatAPI.getEstimate() exception:",
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

  /// GET /swap
  /// Creates a swap with the specified exchange partner.
  static Future<ExchangeResponse<CgTransaction>> createSwap({
    required String coin1,
    required String network1,
    required String coin2,
    required String network2,
    required String amount,
    required String partner,
    required String address,
    String? estimateId,
  }) async {
    final params = <String, String>{
      "coin1": coin1.toLowerCase(),
      "network1": network1.toLowerCase(),
      "coin2": coin2.toLowerCase(),
      "network2": network2.toLowerCase(),
      "amount": amount,
      "partner": partner,
      "address": address,
      "source": kCypherGoatSource,
    };

    if (kCypherGoatAffiliate.isNotEmpty) {
      params["affiliate"] = kCypherGoatAffiliate;
    }
    if (estimateId != null && estimateId.isNotEmpty) {
      params["estimateid"] = estimateId;
    }
    if (kCypherGoatApiKey.isNotEmpty) {
      params["api_key"] = kCypherGoatApiKey;
    }

    final uri = _buildUri(path: "/swap", params: params);

    try {
      final json = await _makeGetRequest(uri);
      final map = Map<String, dynamic>.from(json as Map);

      final txMap = map["transaction"] as Map?;
      if (txMap == null) {
        throw Exception("Missing 'transaction' in swap response");
      }

      return ExchangeResponse(
        value: CgTransaction.fromMap(Map<String, dynamic>.from(txMap)),
      );
    } catch (e, s) {
      Logging.instance.e(
        "CypherGoatAPI.createSwap() exception:",
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

  /// GET /transaction
  /// Fetches transaction details by CGID.
  static Future<ExchangeResponse<CgTransaction>> getTransaction({
    required String cgid,
  }) async {
    final params = <String, String>{"id": cgid};
    if (kCypherGoatApiKey.isNotEmpty) {
      params["api_key"] = kCypherGoatApiKey;
    }

    final uri = _buildUri(path: "/transaction", params: params);

    try {
      final json = await _makeGetRequest(uri);
      final map = Map<String, dynamic>.from(json as Map);

      final txMap = map["transaction"] as Map?;
      if (txMap == null) {
        throw Exception("Missing 'transaction' in response");
      }

      return ExchangeResponse(
        value: CgTransaction.fromMap(Map<String, dynamic>.from(txMap)),
      );
    } catch (e, s) {
      Logging.instance.e(
        "CypherGoatAPI.getTransaction($cgid) exception:",
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
