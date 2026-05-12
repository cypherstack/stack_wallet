import "dart:convert";
import "dart:io";

import "package:decimal/decimal.dart";
import "package:flutter/material.dart";

import "../../../app_config.dart";
import "../../../external_api_keys.dart";
import "../../../networking/http.dart";
import "../../../utilities/prefs.dart";
import "../../tor_service.dart";

/// The rate type for an exchange.
enum ExolixRateType {
  fixed,
  float;

  String get apiValue => switch (this) {
    .fixed => "fixed",
    .float => "float",
  };
}

/// Transaction status returned by the API.
enum ExolixTransactionStatus {
  wait,
  confirmation,
  confirmed,
  exchanging,
  sending,
  success,
  overdue,
  refund,
  refunded,
  unknown;

  static ExolixTransactionStatus fromString(String? value) => switch (value) {
    "wait" => .wait,
    "confirmation" => .confirmation,
    "confirmed" => .confirmed,
    "exchanging" => .exchanging,
    "sending" => .sending,
    "success" => .success,
    "overdue" => .overdue,
    "refund" => .refund,
    "refunded" => .refunded,
    _ => .unknown,
  };
}

/// Thrown when the Exolix API returns a non-2xx response or an unexpected body.
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

// ============================================================
// DTOs
// ============================================================

/// Parse a [Decimal] money value from a JSON field. Accepts:
///   - num (int or double) — converted via its canonical string form so that
///     a JSON literal like 0.5 round-trips precisely
///   - String — parsed directly via [Decimal.tryParse]
/// Throws [FormatException] for null, unparseable strings, or any other type.
///
/// IMPORTANT: never goes through double arithmetic. Even when the JSON parser
/// hands us a double, we stringify it (its shortest round-trip representation)
/// and parse that as Decimal. For values produced by `jsonDecode` of normal
/// API responses this is lossless; for pathological doubles the result is the
/// closest decimal representation of that double, which is the best any
/// consumer of a JSON-decoded double can do.
Decimal _parseDecimal(dynamic value) {
  if (value is Decimal) return value;
  if (value is int) return Decimal.fromInt(value);
  if (value is double) {
    final parsed = Decimal.tryParse(value.toString());
    if (parsed != null) return parsed;
    throw FormatException(
      "Could not convert double to Decimal",
      value.toString(),
    );
  }
  if (value is String) {
    final parsed = Decimal.tryParse(value);
    if (parsed != null) return parsed;
    throw FormatException(
      "Expected a numeric Decimal value but got unparseable string",
      value,
    );
  }
  throw FormatException(
    "Expected a Decimal-compatible value (num or numeric String) but got"
        " ${value.runtimeType}",
    "$value",
  );
}

double _parseDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value);
    if (parsed != null) return parsed;
    throw FormatException(
      "Expected a numeric value but got unparseable string",
      value,
    );
  }
  throw FormatException(
    "Expected a numeric value (num or numeric String) but got"
        " ${value.runtimeType}",
    "$value",
  );
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    final parsedInt = int.tryParse(value);
    if (parsedInt != null) return parsedInt;
    throw FormatException(
      "Expected an integer value but got unparseable string",
      value,
    );
  }
  throw FormatException(
    "Expected an integer value (int, or numeric String) but got"
        " ${value.runtimeType}",
    "$value",
  );
}

/// A network entry as returned in currency listings and the dedicated
/// networks endpoints.
class ExolixNetwork {
  final String network;
  final String name;
  final String? shortName;
  final String? notes;
  final String? addressRegex;
  final bool isDefault;
  final String? blockExplorer;
  final bool memoNeeded;
  final String? memoName;
  final String? memoRegex;
  final int precision;
  final int? decimal;
  final String? contract;
  final String? icon;

  ExolixNetwork({
    required this.network,
    required this.name,
    required this.shortName,
    required this.notes,
    required this.addressRegex,
    required this.isDefault,
    required this.blockExplorer,
    required this.memoNeeded,
    required this.memoName,
    required this.memoRegex,
    required this.precision,
    required this.decimal,
    required this.contract,
    required this.icon,
  });

  factory ExolixNetwork.fromJson(Map<String, dynamic> json) {
    // The docs are inconsistent: one example uses "addresRegex" (typo),
    // another uses "addressRegex". Accept both.
    final dynamic addrRegex = json["addressRegex"] ?? json["addresRegex"];
    return ExolixNetwork(
      network: json["network"] as String? ?? "",
      name: json["name"] as String? ?? "",
      shortName: json["shortName"] as String?,
      notes: json["notes"] as String?,
      addressRegex: addrRegex as String?,
      isDefault: json["isDefault"] as bool? ?? false,
      blockExplorer: json["blockExplorer"] as String?,
      memoNeeded: json["memoNeeded"] as bool? ?? false,
      memoName: json["memoName"] as String?,
      memoRegex: json["memoRegex"] as String?,
      precision: _parseInt(json["precision"]),
      decimal: json["decimal"] == null ? null : _parseInt(json["decimal"]),
      contract: json["contract"] as String?,
      icon: json["icon"] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "network": network,
      "name": name,
      "shortName": shortName,
      "notes": notes,
      "addressRegex": addressRegex,
      "isDefault": isDefault,
      "blockExplorer": blockExplorer,
      "memoNeeded": memoNeeded,
      "memoName": memoName,
      "memoRegex": memoRegex,
      "precision": precision,
      "decimal": decimal,
      "contract": contract,
      "icon": icon,
    };
  }

  @override
  String toString() => toMap().toString();
}

/// A currency entry.
class ExolixCurrency {
  final String code;
  final String name;
  final String? icon;
  final String? notes;

  /// Only populated when the listing was requested with withNetworks=true.
  final List<ExolixNetwork> networks;

  ExolixCurrency({
    required this.code,
    required this.name,
    required this.icon,
    required this.notes,
    required this.networks,
  });

  factory ExolixCurrency.fromJson(Map<String, dynamic> json) {
    final dynamic rawNetworks = json["networks"];
    final List<ExolixNetwork> nets = (rawNetworks is List)
        ? rawNetworks
              .map(
                (e) =>
                    ExolixNetwork.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList()
        : [];
    return ExolixCurrency(
      code: json["code"] as String? ?? "",
      name: json["name"] as String? ?? "",
      icon: json["icon"] as String?,
      notes: json["notes"] as String?,
      networks: nets,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "code": code,
      "name": name,
      "icon": icon,
      "notes": notes,
      "networks": networks.map((n) => n.toMap()).toList(),
    };
  }

  @override
  String toString() => toMap().toString();
}

/// Generic paginated response wrapper.
class ExolixPaginatedResponse<T> {
  final List<T> data;
  final int count;

  ExolixPaginatedResponse({required this.data, required this.count});

  factory ExolixPaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    final dynamic rawData = json["data"];
    final List<T> items = (rawData is List)
        ? rawData
              .map((e) => itemFromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
        : <T>[];
    return ExolixPaginatedResponse(
      data: items,
      count: _parseInt(json["count"]),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "data": data.map((e) {
        if (e is ExolixCurrency) return e.toMap();
        if (e is ExolixNetwork) return e.toMap();
        if (e is ExolixTransaction) return e.toMap();
        return e.toString();
      }).toList(),
      "count": count,
    };
  }

  @override
  String toString() => toMap().toString();
}

/// Exchange rate quote.
///
/// All numeric fields are [Decimal] to preserve precision for coin amounts
/// and exchange rates.
class ExolixRate {
  final Decimal fromAmount;
  final Decimal toAmount;
  final Decimal rate;
  final String? message;
  final Decimal minAmount;
  final Decimal withdrawMin;
  final Decimal maxAmount;

  ExolixRate({
    required this.fromAmount,
    required this.toAmount,
    required this.rate,
    required this.message,
    required this.minAmount,
    required this.withdrawMin,
    required this.maxAmount,
  });

  factory ExolixRate.fromJson(Map<String, dynamic> json) {
    return ExolixRate(
      fromAmount: _parseDecimal(json["fromAmount"]),
      toAmount: _parseDecimal(json["toAmount"]),
      rate: _parseDecimal(json["rate"]),
      message: json["message"] as String?,
      minAmount: _parseDecimal(json["minAmount"]),
      withdrawMin: _parseDecimal(json["withdrawMin"]),
      maxAmount: _parseDecimal(json["maxAmount"]),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "fromAmount": fromAmount.toString(),
      "toAmount": toAmount.toString(),
      "rate": rate.toString(),
      "message": message,
      "minAmount": minAmount.toString(),
      "withdrawMin": withdrawMin.toString(),
      "maxAmount": maxAmount.toString(),
    };
  }

  @override
  String toString() => toMap().toString();
}

/// The "coinFrom" / "coinTo" sub-object inside a transaction.
class ExolixCoinInfo {
  final String coinCode;
  final String coinName;
  final String network;
  final String networkName;
  final String? networkShortName;
  final String? icon;
  final String? memoName;
  final String? contract;

  ExolixCoinInfo({
    required this.coinCode,
    required this.coinName,
    required this.network,
    required this.networkName,
    required this.networkShortName,
    required this.icon,
    required this.memoName,
    required this.contract,
  });

  factory ExolixCoinInfo.fromJson(Map<String, dynamic> json) {
    return ExolixCoinInfo(
      coinCode: json["coinCode"] as String? ?? "",
      coinName: json["coinName"] as String? ?? "",
      network: json["network"] as String? ?? "",
      networkName: json["networkName"] as String? ?? "",
      networkShortName: json["networkShortName"] as String?,
      icon: json["icon"] as String?,
      memoName: json["memoName"] as String?,
      contract: json["contract"] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "coinCode": coinCode,
      "coinName": coinName,
      "network": network,
      "networkName": networkName,
      "networkShortName": networkShortName,
      "icon": icon,
      "memoName": memoName,
      "contract": contract,
    };
  }

  @override
  String toString() => toMap().toString();
}

/// A transaction hash sub-object (hashIn / hashOut).
class ExolixHash {
  final String? hash;
  final String? link;

  ExolixHash({required this.hash, required this.link});

  factory ExolixHash.fromJson(Map<String, dynamic> json) {
    return ExolixHash(
      hash: json["hash"] as String?,
      link: json["link"] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {"hash": hash, "link": link};
  }

  @override
  String toString() => toMap().toString();
}

/// A full transaction object.
///
/// Coin amounts and the exchange rate are [Decimal] for precision.
class ExolixTransaction {
  final String id;
  final Decimal amount;
  final Decimal amountTo;
  final ExolixCoinInfo coinFrom;
  final ExolixCoinInfo coinTo;
  final String? comment;
  final DateTime? createdAt;
  final String depositAddress;
  final String? depositExtraId;
  final String withdrawalAddress;
  final String? withdrawalExtraId;
  final ExolixHash hashIn;
  final ExolixHash hashOut;
  final Decimal rate;
  final ExolixRateType rateType;
  final String? refundAddress;
  final String? refundExtraId;
  final ExolixTransactionStatus status;

  /// "source" is documented for the listing endpoint but not for the single
  /// fetch. Nullable so it round-trips safely either way.
  final String? source;

  ExolixTransaction({
    required this.id,
    required this.amount,
    required this.amountTo,
    required this.coinFrom,
    required this.coinTo,
    required this.comment,
    required this.createdAt,
    required this.depositAddress,
    required this.depositExtraId,
    required this.withdrawalAddress,
    required this.withdrawalExtraId,
    required this.hashIn,
    required this.hashOut,
    required this.rate,
    required this.rateType,
    required this.refundAddress,
    required this.refundExtraId,
    required this.status,
    required this.source,
  });

  factory ExolixTransaction.fromJson(Map<String, dynamic> json) {
    final dynamic coinFromRaw = json["coinFrom"];
    final dynamic coinToRaw = json["coinTo"];
    final dynamic hashInRaw = json["hashIn"];
    final dynamic hashOutRaw = json["hashOut"];

    DateTime? parsedCreatedAt;
    final dynamic createdAtRaw = json["createdAt"];
    if (createdAtRaw is String && createdAtRaw.isNotEmpty) {
      parsedCreatedAt = DateTime.tryParse(createdAtRaw);
    }

    ExolixRateType parsedRateType;
    final dynamic rateTypeRaw = json["rateType"];
    if (rateTypeRaw == "float") {
      parsedRateType = ExolixRateType.float;
    } else {
      // Default per docs is fixed.
      parsedRateType = ExolixRateType.fixed;
    }

    return ExolixTransaction(
      id: json["id"] as String? ?? "",
      amount: _parseDecimal(json["amount"]),
      amountTo: _parseDecimal(json["amountTo"]),
      coinFrom: (coinFromRaw is Map)
          ? ExolixCoinInfo.fromJson(Map<String, dynamic>.from(coinFromRaw))
          : ExolixCoinInfo(
              coinCode: "",
              coinName: "",
              network: "",
              networkName: "",
              networkShortName: null,
              icon: null,
              memoName: null,
              contract: null,
            ),
      coinTo: (coinToRaw is Map)
          ? ExolixCoinInfo.fromJson(Map<String, dynamic>.from(coinToRaw))
          : ExolixCoinInfo(
              coinCode: "",
              coinName: "",
              network: "",
              networkName: "",
              networkShortName: null,
              icon: null,
              memoName: null,
              contract: null,
            ),
      comment: json["comment"] as String?,
      createdAt: parsedCreatedAt,
      depositAddress: json["depositAddress"] as String? ?? "",
      depositExtraId: json["depositExtraId"] as String?,
      withdrawalAddress: json["withdrawalAddress"] as String? ?? "",
      withdrawalExtraId: json["withdrawalExtraId"] as String?,
      hashIn: (hashInRaw is Map)
          ? ExolixHash.fromJson(Map<String, dynamic>.from(hashInRaw))
          : ExolixHash(hash: null, link: null),
      hashOut: (hashOutRaw is Map)
          ? ExolixHash.fromJson(Map<String, dynamic>.from(hashOutRaw))
          : ExolixHash(hash: null, link: null),
      rate: _parseDecimal(json["rate"]),
      rateType: parsedRateType,
      refundAddress: json["refundAddress"] as String?,
      refundExtraId: json["refundExtraId"] as String?,
      status: ExolixTransactionStatus.fromString(json["status"] as String?),
      source: json["source"] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "amount": amount.toString(),
      "amountTo": amountTo.toString(),
      "coinFrom": coinFrom.toMap(),
      "coinTo": coinTo.toMap(),
      "comment": comment,
      "createdAt": createdAt?.toIso8601String(),
      "depositAddress": depositAddress,
      "depositExtraId": depositExtraId,
      "withdrawalAddress": withdrawalAddress,
      "withdrawalExtraId": withdrawalExtraId,
      "hashIn": hashIn.toMap(),
      "hashOut": hashOut.toMap(),
      "rate": rate.toString(),
      "rateType": rateType.apiValue,
      "refundAddress": refundAddress,
      "refundExtraId": refundExtraId,
      "status": status.name,
      "source": source,
    };
  }

  @override
  String toString() => toMap().toString();
}

// ============================================================
// Singleton API client
// ============================================================

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
