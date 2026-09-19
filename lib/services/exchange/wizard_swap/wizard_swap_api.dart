import 'dart:convert';

import 'package:decimal/decimal.dart';

import '../../../app_config.dart';
import '../../../networking/http.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/prefs.dart';
import '../../tor_service.dart';

abstract class WizardSwapApi {
  static const _client = HTTP();
  static const baseUrl = "https://www.wizardswap.io/api";

  static Uri _getUri(String endpoint) => Uri.parse("$baseUrl$endpoint");

  static Future<String> _makeGetRequest(Uri uri) async {
    int code = -1;
    try {
      final response = await _client.get(
        url: uri,
        headers: {'Accept': 'application/json'},
        proxyInfo: !AppConfig.hasFeature(AppFeature.tor)
            ? null
            : Prefs.instance.useTor
            ? TorService.sharedInstance.getProxyInfo()
            : null,
      );

      code = response.code;

      if (code != 200) {
        throw Exception(
          "WizardSwapApi GET failed CODE=$code, response body=${response.body}",
        );
      }

      return response.body;
    } catch (e, s) {
      Logging.instance.e("rethrowing", error: e, stackTrace: s);
      rethrow;
    }
  }

  static Future<String> _makePostRequest(
    Uri uri,
    Map<String, dynamic> body,
  ) async {
    int code = -1;
    try {
      final response = await _client.post(
        url: uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
        proxyInfo: !AppConfig.hasFeature(AppFeature.tor)
            ? null
            : Prefs.instance.useTor
            ? TorService.sharedInstance.getProxyInfo()
            : null,
      );

      code = response.code;

      if (code != 200) {
        throw Exception(
          "WizardSwapApi POST failed CODE=$code, body=${response.body}",
        );
      }

      return response.body;
    } catch (e, s) {
      Logging.instance.e("rethrowing", error: e, stackTrace: s);
      rethrow;
    }
  }

  static Map<String, dynamic> _decode(dynamic map) {
    if (map is! Map) {
      throw Exception(
        "Expected a `Map`, but found a `${map.runtimeType}: $map",
      );
    }

    try {
      return Map<String, dynamic>.from(map);
    } catch (_) {
      Logging.instance.e("$map is NOT Map<String, dynamic>");
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getCurrencies() async {
    final body = await _makeGetRequest(_getUri("/currency"));
    final data = jsonDecode(body);
    if (data is! List) {
      throw Exception("$body is not a json list!");
    }

    return data.map(_decode).toList();
  }

  /// [symbol] should be lowercase. Example: btc
  static Future<Map<String, dynamic>> getCurrencyInfo(String symbol) async {
    final body = await _makeGetRequest(_getUri("/currency/$symbol"));
    return _decode(jsonDecode(body));
  }

  static Future<dynamic> getExchange(String id) async {
    final body = await _makeGetRequest(_getUri("/exchange/$id"));
    return _decode(jsonDecode(body));
  }

  static Future<WzEstimate> postEstimate(
    String from,
    String to,
    Decimal fromAmount,
    String apiKey,
  ) async {
    final body = await _makePostRequest(_getUri("/estimate"), {
      "currency_from": from,
      "currency_to": to,
      "amount_from": fromAmount,
      "api_key": apiKey,
    });

    final map = _decode(jsonDecode(body));

    // sometimes this json value will contain an error message lol...
    final amount = Decimal.tryParse(map["estimated_amount"].toString());
    if (amount == null) {
      throw Exception(map["estimated_amount"]);
    }

    return WzEstimate(
      from: from,
      to: to,
      amountFrom: fromAmount,
      amountTo: amount,
    );
  }

  static Future<dynamic> postExchange(
    String from,
    String to,
    String toAddress,
    Decimal fromAmount,
    String refundAddress,
    String? toExtraId,
    String? refundExtraId,
    String apiKey,
  ) async {
    final body = await _makePostRequest(_getUri("/exchange"), {
      "currency_from": from,
      "currency_to": to,
      "address_to": toAddress,
      "amount_from": fromAmount,
      "refund_address": refundAddress,
      if (toExtraId != null) "extra_id_to": toExtraId,
      if (refundExtraId != null) "refund_extra_id": refundExtraId,
      "api_key": apiKey,
    });
    return _decode(jsonDecode(body));
  }
}

final class WzEstimate {
  final String from;
  final String to;
  final Decimal amountFrom;
  final Decimal amountTo;

  WzEstimate({
    required this.from,
    required this.to,
    required this.amountFrom,
    required this.amountTo,
  });

  @override
  String toString() {
    return 'WzEstimate {'
        'from: $from, '
        'to: $to, '
        'amountFrom: $amountFrom, '
        'amountTo: $amountTo '
        '}';
  }
}
