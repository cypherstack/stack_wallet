import "dart:convert";
import "dart:io";

import "package:decimal/decimal.dart";
import "package:flutter/material.dart";

import "../../../../app_config.dart";
import "../../../../external_api_keys.dart";
import "../../../../networking/http.dart";
import "../../../../utilities/prefs.dart";
import "../../../tor_service.dart";
import "dto/exolix_currency.dart";
import "dto/exolix_network.dart";
import "dto/exolix_rate.dart";
import "dto/exolix_transaction.dart";
import "helpers/enums.dart";
import "helpers/exolix_paginated_response.dart";

class ExolixApiException implements Exception {
  final int? statusCode;
  final String message;
  final dynamic body;

  ExolixApiException({required this.message, this.statusCode, this.body});

  @override
  String toString() =>
      "ExolixApiException("
      "statusCode: $statusCode, "
      "message: $message, "
      "body: $body)";
}

class ExolixApi {
  ExolixApi._();

  static const String _baseUrl = "https://exolix.com/api/v2";

  /// Override to inject a mock client in tests.
  static HTTP _client = const HTTP();

  // ignore: avoid_setters_without_getters
  @visibleForTesting
  static set client(HTTP client) {
    _client = client;
  }

  /// Resolves the API key to use for a request. If [override] is null OR an
  /// empty/whitespace-only string, falls back to [kExolixApiKey].
  static String _resolveApiKey(String? override) {
    if (override == null) return kExolixApiKey;
    final trimmed = override.trim();
    if (trimmed.isEmpty) return kExolixApiKey;
    return trimmed;
  }

  /// Builds the standard headers. The Authorization header is only attached
  /// when the resolved key is non-empty AND not the literal placeholder.
  /// Many endpoints work unauthenticated, so we must not send a useless
  /// header that could be rejected by the server.
  static Map<String, String> _buildHeaders(String? apiKey) {
    final headers = <String, String>{
      "Accept": "application/json",
      "Content-Type": "application/json",
    };
    final key = _resolveApiKey(apiKey);
    if (key.isNotEmpty && key != "YOUR_API_KEY_HERE") {
      headers["Authorization"] = key;
    }
    return headers;
  }

  /// Encodes a query parameter map, dropping null values. All values are
  /// stringified because Uri requires String values. [Decimal] values are
  /// rendered via their canonical [Decimal.toString()] for lossless transport.
  static Map<String, String> _encodeQuery(Map<String, dynamic> raw) {
    final out = <String, String>{};
    raw.forEach((key, value) {
      if (value == null) return;
      if (value is bool) {
        out[key] = value ? "true" : "false";
      } else if (value is Decimal) {
        out[key] = value.toString();
      } else {
        out[key] = value.toString();
      }
    });
    return out;
  }

  /// Builds a URI for a path under the base URL with optional query params.
  static Uri _buildUri(String path, [Map<String, dynamic>? query]) {
    final fullPath = path.startsWith("/") ? path : "/$path";
    final base = Uri.parse("$_baseUrl$fullPath");
    if (query == null || query.isEmpty) {
      return base;
    }
    final encoded = _encodeQuery(query);
    if (encoded.isEmpty) {
      return base;
    }
    return base.replace(queryParameters: encoded);
  }

  /// Resolve the proxy info to use for a request based on app config + prefs.
  /// Returns null when the Tor feature is disabled or when the user has not
  /// opted in to Tor in prefs.
  static ({InternetAddress host, int port})? _resolveProxyInfo() {
    if (!AppConfig.hasFeature(AppFeature.tor)) {
      return null;
    }
    if (Prefs.instance.useTor) {
      return TorService.sharedInstance.getProxyInfo();
    }
    return null;
  }

  /// Encodes a request body, serializing [Decimal] values as raw JSON
  /// numbers (not strings) so the wire format matches the API examples.
  /// We do this by emitting the JSON manually for top-level fields, since
  /// jsonEncode's `toEncodable` can only return objects, not raw tokens.
  ///
  /// The body is a flat Map<String, dynamic> in this API, which keeps the
  /// implementation simple. If you ever nest Decimals deeper, extend this.
  static String _encodeBody(Map<String, dynamic> body) {
    final buffer = StringBuffer("{");
    var first = true;
    body.forEach((key, value) {
      if (!first) buffer.write(",");
      first = false;
      buffer.write(jsonEncode(key));
      buffer.write(":");
      if (value is Decimal) {
        // Emit as a raw JSON number using Decimal's canonical string form.
        // Decimal.toString() never produces exponent form for finite values
        // and always yields a valid JSON number.
        buffer.write(value.toString());
      } else {
        buffer.write(jsonEncode(value));
      }
    });
    buffer.write("}");
    return buffer.toString();
  }

  /// Parse a response body and check status. Throws [ExolixApiException] on
  /// non-2xx. Returns the decoded body (Map or List), or the raw String body
  /// if it wasn't JSON-parseable.
  static dynamic _parseResponse(
    int status,
    String body,
    String endpointForError,
  ) {
    dynamic decoded;
    if (body.isNotEmpty) {
      try {
        decoded = jsonDecode(body);
      } catch (_) {
        decoded = body;
      }
    }
    if (status < 200 || status >= 300) {
      String message;
      if (decoded is Map && decoded["message"] is String) {
        message = decoded["message"] as String;
      } else if (decoded is Map && decoded["error"] is String) {
        message = decoded["error"] as String;
      } else {
        message = "Request failed with status $status for $endpointForError";
      }
      throw ExolixApiException(
        statusCode: status,
        message: message,
        body: decoded,
      );
    }
    return decoded;
  }

  /// Issues a GET and returns the decoded body. Throws on non-2xx.
  static Future<dynamic> _get(Uri uri, String? apiKey) async {
    final response = await _client.get(
      url: uri,
      headers: _buildHeaders(apiKey),
      proxyInfo: _resolveProxyInfo(),
    );
    return _parseResponse(response.code, response.body, uri.path);
  }

  /// Issues a POST and returns the decoded body. Throws on non-2xx.
  static Future<dynamic> _post(
    Uri uri,
    String? apiKey,
    Map<String, dynamic> jsonBody,
  ) async {
    final response = await _client.post(
      url: uri,
      headers: _buildHeaders(apiKey),
      body: _encodeBody(jsonBody),
      proxyInfo: _resolveProxyInfo(),
    );
    return _parseResponse(response.code, response.body, uri.path);
  }

  // --------------------------------------------------------
  // Currencies
  // --------------------------------------------------------

  /// GET /currencies
  static Future<ExolixPaginatedResponse<ExolixCurrency>> getCurrencies({
    int? page,
    int? size,
    String? search,
    bool? withNetworks,
    String? apiKey,
  }) async {
    final uri = _buildUri("/currencies", {
      "page": page,
      "size": size,
      "search": search,
      "withNetworks": withNetworks,
    });
    final result = await _get(uri, apiKey);
    if (result is! Map) {
      throw ExolixApiException(
        message: "Unexpected response shape for /currencies",
        body: result,
      );
    }
    return ExolixPaginatedResponse.fromJson(
      Map<String, dynamic>.from(result),
      ExolixCurrency.fromJson,
    );
  }

  /// GET /currencies/{code}/networks
  static Future<List<ExolixNetwork>> getCurrencyNetworks({
    required String code,
    String? apiKey,
  }) async {
    if (code.trim().isEmpty) {
      throw ArgumentError.value(code, "code", "must not be empty");
    }
    final uri = _buildUri("/currencies/${Uri.encodeComponent(code)}/networks");
    final result = await _get(uri, apiKey);
    if (result is! List) {
      throw ExolixApiException(
        message: "Unexpected response shape for /currencies/$code/networks",
        body: result,
      );
    }
    return result
        .map((e) => ExolixNetwork.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// GET /currencies/networks
  static Future<ExolixPaginatedResponse<ExolixNetwork>> getAllNetworks({
    int? page,
    int? size,
    String? search,
    String? apiKey,
  }) async {
    final uri = _buildUri("/currencies/networks", {
      "page": page,
      "size": size,
      "search": search,
    });
    final result = await _get(uri, apiKey);
    if (result is! Map) {
      throw ExolixApiException(
        message: "Unexpected response shape for /currencies/networks",
        body: result,
      );
    }
    return ExolixPaginatedResponse.fromJson(
      Map<String, dynamic>.from(result),
      ExolixNetwork.fromJson,
    );
  }

  // --------------------------------------------------------
  // Rate
  // --------------------------------------------------------

  /// GET /rate
  ///
  /// You must supply EXACTLY ONE of [amount] or [withdrawalAmount]. Supplying
  /// neither or both throws [ArgumentError]. Both are coin amounts and use
  /// [Decimal] for precision.
  static Future<ExolixRate> getRate({
    required String coinFrom,
    required String coinTo,
    String? networkFrom,
    String? networkTo,
    Decimal? amount,
    Decimal? withdrawalAmount,
    ExolixRateType rateType = ExolixRateType.fixed,
    String? apiKey,
  }) async {
    if (coinFrom.trim().isEmpty) {
      throw ArgumentError.value(coinFrom, "coinFrom", "must not be empty");
    }
    if (coinTo.trim().isEmpty) {
      throw ArgumentError.value(coinTo, "coinTo", "must not be empty");
    }
    final hasAmount = amount != null;
    final hasWithdraw = withdrawalAmount != null;
    if (!hasAmount && !hasWithdraw) {
      throw ArgumentError("Must supply either amount or withdrawalAmount.");
    }
    if (hasAmount && hasWithdraw) {
      throw ArgumentError(
        "Supply only one of amount or withdrawalAmount, not both.",
      );
    }
    if (amount != null && amount <= Decimal.zero) {
      throw ArgumentError.value(amount, "amount", "must be positive");
    }
    if (withdrawalAmount != null && withdrawalAmount <= Decimal.zero) {
      throw ArgumentError.value(
        withdrawalAmount,
        "withdrawalAmount",
        "must be positive",
      );
    }

    final uri = _buildUri("/rate", {
      "coinFrom": coinFrom,
      "coinTo": coinTo,
      "networkFrom": networkFrom,
      "networkTo": networkTo,
      "amount": amount,
      "withdrawalAmount": withdrawalAmount,
      "rateType": rateType.apiValue,
    });
    final result = await _get(uri, apiKey);
    if (result is! Map) {
      throw ExolixApiException(
        message: "Unexpected response shape for /rate",
        body: result,
      );
    }
    return ExolixRate.fromJson(Map<String, dynamic>.from(result));
  }

  // --------------------------------------------------------
  // Transactions
  // --------------------------------------------------------

  /// GET /transactions
  static Future<ExolixPaginatedResponse<ExolixTransaction>> getTransactions({
    int? page,
    int? size,
    String? search,
    String? sort,
    String? order,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? statuses,
    String? apiKey,
  }) async {
    if (order != null) {
      final normalized = order.toLowerCase();
      if (normalized != "asc" && normalized != "desc") {
        throw ArgumentError.value(order, "order", "must be 'asc' or 'desc'");
      }
    }
    final uri = _buildUri("/transactions", {
      "page": page,
      "size": size,
      "search": search,
      "sort": sort,
      "order": order?.toLowerCase(),
      "dateFrom": dateFrom?.toUtc().toIso8601String(),
      "dateTo": dateTo?.toUtc().toIso8601String(),
      "statuses": statuses,
    });
    final result = await _get(uri, apiKey);
    if (result is! Map) {
      throw ExolixApiException(
        message: "Unexpected response shape for /transactions",
        body: result,
      );
    }
    return ExolixPaginatedResponse.fromJson(
      Map<String, dynamic>.from(result),
      ExolixTransaction.fromJson,
    );
  }

  /// GET /transactions/{id}
  static Future<ExolixTransaction> getTransaction({
    required String id,
    String? apiKey,
  }) async {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, "id", "must not be empty");
    }
    final uri = _buildUri("/transactions/${Uri.encodeComponent(id)}");
    final result = await _get(uri, apiKey);
    if (result is! Map) {
      throw ExolixApiException(
        message: "Unexpected response shape for /transactions/$id",
        body: result,
      );
    }
    return ExolixTransaction.fromJson(Map<String, dynamic>.from(result));
  }

  /// POST /transactions
  ///
  /// Exactly one of [amount] / [withdrawalAmount] must be supplied — both are
  /// coin amounts and use [Decimal]. If [slippage] is supplied,
  /// [refundAddress] is required (per the docs). [slippage] is a percentage,
  /// not a money value, so it stays a [double].
  static Future<ExolixTransaction> createTransaction({
    required String coinFrom,
    required String networkFrom,
    required String coinTo,
    required String networkTo,
    required String withdrawalAddress,
    Decimal? amount,
    Decimal? withdrawalAmount,
    String? withdrawalExtraId,
    ExolixRateType rateType = ExolixRateType.fixed,
    String? refundAddress,
    String? refundExtraId,
    double? slippage,
    String? apiKey,
  }) async {
    if (coinFrom.trim().isEmpty) {
      throw ArgumentError.value(coinFrom, "coinFrom", "must not be empty");
    }
    if (networkFrom.trim().isEmpty) {
      throw ArgumentError.value(
        networkFrom,
        "networkFrom",
        "must not be empty",
      );
    }
    if (coinTo.trim().isEmpty) {
      throw ArgumentError.value(coinTo, "coinTo", "must not be empty");
    }
    if (networkTo.trim().isEmpty) {
      throw ArgumentError.value(networkTo, "networkTo", "must not be empty");
    }
    if (withdrawalAddress.trim().isEmpty) {
      throw ArgumentError.value(
        withdrawalAddress,
        "withdrawalAddress",
        "must not be empty",
      );
    }

    final hasAmount = amount != null;
    final hasWithdraw = withdrawalAmount != null;
    if (!hasAmount && !hasWithdraw) {
      throw ArgumentError("Must supply either amount or withdrawalAmount.");
    }
    if (hasAmount && hasWithdraw) {
      throw ArgumentError(
        "Supply only one of amount or withdrawalAmount, not both.",
      );
    }
    if (amount != null && amount <= Decimal.zero) {
      throw ArgumentError.value(amount, "amount", "must be positive");
    }
    if (withdrawalAmount != null && withdrawalAmount <= Decimal.zero) {
      throw ArgumentError.value(
        withdrawalAmount,
        "withdrawalAmount",
        "must be positive",
      );
    }

    if (slippage != null) {
      if (slippage < 0) {
        throw ArgumentError.value(slippage, "slippage", "must be non-negative");
      }
      if (refundAddress == null || refundAddress.trim().isEmpty) {
        throw ArgumentError(
          "refundAddress is required when slippage is provided.",
        );
      }
    }

    final body = <String, dynamic>{
      "coinFrom": coinFrom,
      "networkFrom": networkFrom,
      "coinTo": coinTo,
      "networkTo": networkTo,
      "withdrawalAddress": withdrawalAddress,
      "rateType": rateType.apiValue,
    };
    if (amount != null) body["amount"] = amount;
    if (withdrawalAmount != null) body["withdrawalAmount"] = withdrawalAmount;
    if (withdrawalExtraId != null) {
      body["withdrawalExtraId"] = withdrawalExtraId;
    }
    if (refundAddress != null) body["refundAddress"] = refundAddress;
    if (refundExtraId != null) body["refundExtraId"] = refundExtraId;
    if (slippage != null) body["slippage"] = slippage;

    final uri = _buildUri("/transactions");
    final result = await _post(uri, apiKey, body);
    if (result is! Map) {
      throw ExolixApiException(
        message: "Unexpected response shape for POST /transactions",
        body: result,
      );
    }
    return ExolixTransaction.fromJson(Map<String, dynamic>.from(result));
  }
}
