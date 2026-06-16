import "dart:convert";
import "dart:io";

import "package:decimal/decimal.dart";
import "package:meta/meta.dart";

import "../../../app_config.dart";
import "../../../external_api_keys.dart";
import "../../../networking/http.dart";
import "../../../utilities/logger.dart";
import "../../../utilities/prefs.dart";
import "../../tor_service.dart";
import "models/coin_info.dart";
import "models/coin_v2.dart";
import "models/transaction.dart";

class LetsExchangeApiException implements Exception {
  final int? statusCode;
  final String message;
  final dynamic body;

  LetsExchangeApiException({required this.message, this.statusCode, this.body});

  @override
  String toString() =>
      "LetsExchangeApiException("
      "statusCode: $statusCode, "
      "message: $message, "
      "body: $body)";
}

abstract final class LetsExchangeApi {
  static const base = "api.letsexchange.io";

  /// Override to inject a mock client in tests.
  static HTTP _client = const HTTP();

  // ignore: avoid_setters_without_getters
  @visibleForTesting
  static set client(HTTP client) {
    _client = client;
  }

  static Map<String, String> get _headers => {
    "Content-Type": "application/json",
    "Accept": "application/json",
    "Authorization": "Bearer $kLetsExchangeToken",
  };

  static ({InternetAddress host, int port})? _resolveProxyInfo() {
    if (!AppConfig.hasFeature(AppFeature.tor)) {
      return null;
    }
    if (Prefs.instance.useTor) {
      return TorService.sharedInstance.getProxyInfo();
    }
    return null;
  }

  static T _decode<T>(int code, String body, T Function(dynamic) parse) {
    return switch (code) {
      200 => parse(jsonDecode(body)),

      final int status => throw LetsExchangeApiException(
        message: switch (status) {
          403 => "Wrong API key in Bearer token",
          404 => "Not found",
          422 => "Unprocessable entity",
          500 => "Unexpected server error",
          _ => "Unexpected status code",
        },
        statusCode: status,
        body: body,
      ),
    };
  }

  static Future<T> _get<T>(
    Uri uri, {
    required T Function(dynamic) parse,
  }) async {
    final response = await _client.get(
      url: uri,
      headers: _headers,
      proxyInfo: _resolveProxyInfo(),
    );

    Logging.instance.t("GET $uri: ${response.code}: ${response.body}");

    return _decode(response.code, response.body, parse);
  }

  static Future<T> _post<T>(
    Uri uri, {
    required Map<String, dynamic> body,
    required T Function(dynamic) parse,
  }) async {
    final response = await _client.post(
      url: uri,
      headers: _headers,
      body: jsonEncode(body..["affiliate_id"] = kLetsExchangeId),
      proxyInfo: _resolveProxyInfo(),
    );

    Logging.instance.t("POST $uri: ${response.code}: ${response.body}");

    return _decode(response.code, response.body, parse);
  }

  // ===========================================================================
  // ======== API ==============================================================

  static Future<List<CoinV2>> fetchCoins() async {
    final uri = Uri.https(base, "/api/v2/coins", {
      "affiliate_id": kLetsExchangeId,
    });

    return _get(
      uri,
      parse: (value) => (value as List)
          .map((e) => CoinV2.fromJson((e as Map).cast()))
          .toList(),
    );
  }

  static Future<CoinInfo> getCoinInfo(CoinInfoRequest request) async {
    final uri = Uri.https(base, "/api/v1/info");

    return _post(
      uri,
      body: request.toMap(),
      parse: (value) => CoinInfo.fromJson((value as Map).cast()),
    );
  }

  static Future<CoinInfo> getCoinInfoRevert(CoinInfoRequest request) async {
    final uri = Uri.https(base, "/api/v1/info-revert");

    return _post(
      uri,
      body: request.toMap(),
      parse: (value) => CoinInfo.fromJson((value as Map).cast()),
    );
  }

  static Future<Transaction> createTransaction(
    CreateTransactionRequest request,
  ) async {
    final uri = Uri.https(base, "/api/v1/transaction");

    return _post(
      uri,
      body: request.toMap(),
      parse: (value) => Transaction.fromJson((value as Map).cast()),
    );
  }

  static Future<Transaction> createTransactionRevert(
    CreateTransactionRevertRequest request,
  ) async {
    final uri = Uri.https(base, "/api/v1/transaction-revert");

    return _post(
      uri,
      body: request.toMap(),
      parse: (value) => Transaction.fromJson((value as Map).cast()),
    );
  }

  static Future<Transaction> getTransaction(String id) async {
    final uri = Uri.https(base, "/api/v1/transaction/$id");

    return _get(
      uri,
      parse: (value) => Transaction.fromJson((value as Map).cast()),
    );
  }
}

// =============================================================================
// ============ Request objects +===============================================

/// For `LetsExchangeApi.getCoinInfo` [amount] is the amount of [from]
/// the user will send; for `LetsExchangeApi.getCoinInfoRevert` it is the
/// amount of [to] the user wants to receive. [float] is only relevant to
/// `LetsExchangeApi.getCoinInfo` and is omitted from the body when null.
class CoinInfoRequest {
  CoinInfoRequest({
    required this.from,
    required this.to,
    required this.networkFrom,
    required this.networkTo,
    required this.amount,
    this.promocode,
    this.float,
    this.partnerUserIp,
  });

  final String from;
  final String to;
  final String networkFrom;
  final String networkTo;
  final Decimal amount;
  final String? promocode;
  final bool? float;
  final String? partnerUserIp;

  factory CoinInfoRequest.fromJson(Map<String, dynamic> json) =>
      CoinInfoRequest(
        from: json["from"] as String,
        to: json["to"] as String,
        networkFrom: json["network_from"] as String,
        networkTo: json["network_to"] as String,
        amount: Decimal.parse(json["amount"].toString()),
        promocode: json["promocode"] as String?,
        float: json["float"] as bool?,
        partnerUserIp: json["partner_user_ip"] as String?,
      );

  Map<String, dynamic> toMap() => {
    "from": from,
    "to": to,
    "network_from": networkFrom,
    "network_to": networkTo,
    "amount": amount.toString(),
    if (promocode != null) "promocode": promocode,
    if (float != null) "float": float,
    if (partnerUserIp != null) "partner_user_ip": partnerUserIp,
  };

  @override
  String toString() => toMap().toString();
}

class CreateTransactionRequest {
  CreateTransactionRequest({
    required this.float,
    required this.coinFrom,
    required this.coinTo,
    required this.networkFrom,
    required this.networkTo,
    required this.depositAmount,
    required this.withdrawal,
    required this.withdrawalExtraId,
    this.returnAddress,
    this.returnExtraId,
    this.rateId,
    this.promocode,
    this.email,
    this.partnerUserIp,
  });

  final bool float;
  final String coinFrom;
  final String coinTo;
  final String networkFrom;
  final String networkTo;
  final Decimal depositAmount;
  final String withdrawal;

  /// Must be present; pass an empty string when the coin has no extra ID.
  final String withdrawalExtraId;
  final String? returnAddress;
  final String? returnExtraId;

  /// Rate identifier for the FIXED (`float: false`) flow.
  final String? rateId;
  final String? promocode;
  final String? email;
  final String? partnerUserIp;

  factory CreateTransactionRequest.fromJson(Map<String, dynamic> json) =>
      CreateTransactionRequest(
        float: json["float"] as bool,
        coinFrom: json["coin_from"] as String,
        coinTo: json["coin_to"] as String,
        networkFrom: json["network_from"] as String,
        networkTo: json["network_to"] as String,
        depositAmount: Decimal.parse(json["deposit_amount"].toString()),
        withdrawal: json["withdrawal"] as String,
        withdrawalExtraId: json["withdrawal_extra_id"] as String,
        returnAddress: json["return"] as String?,
        returnExtraId: json["return_extra_id"] as String?,
        rateId: json["rate_id"] as String?,
        promocode: json["promocode"] as String?,
        email: json["email"] as String?,
        partnerUserIp: json["partner_user_ip"] as String?,
      );

  Map<String, dynamic> toMap() => {
    "float": float,
    "coin_from": coinFrom,
    "coin_to": coinTo,
    "network_from": networkFrom,
    "network_to": networkTo,
    "deposit_amount": depositAmount.toString(),
    "withdrawal": withdrawal,
    "withdrawal_extra_id": withdrawalExtraId,
    if (returnAddress != null) "return": returnAddress,
    if (returnExtraId != null) "return_extra_id": returnExtraId,
    if (rateId != null) "rate_id": rateId,
    if (promocode != null) "promocode": promocode,
    if (email != null) "email": email,
    if (partnerUserIp != null) "partner_user_ip": partnerUserIp,
  };

  @override
  String toString() => toMap().toString();
}

class CreateTransactionRevertRequest {
  CreateTransactionRevertRequest({
    required this.float,
    required this.coinFrom,
    required this.coinTo,
    required this.networkFrom,
    required this.networkTo,
    required this.withdrawalAmount,
    required this.withdrawal,
    required this.withdrawalExtraId,
    required this.rateId,
    this.returnAddress,
    this.returnExtraId,
    this.email,
    this.partnerUserIp,
  });

  final bool float;
  final String coinFrom;
  final String coinTo;
  final String networkFrom;
  final String networkTo;
  final Decimal withdrawalAmount;
  final String withdrawal;

  /// Must be present; pass an empty string when the coin has no extra ID.
  final String withdrawalExtraId;
  final String rateId;
  final String? returnAddress;
  final String? returnExtraId;
  final String? email;
  final String? partnerUserIp;

  factory CreateTransactionRevertRequest.fromJson(Map<String, dynamic> json) =>
      CreateTransactionRevertRequest(
        float: json["float"] as bool,
        coinFrom: json["coin_from"] as String,
        coinTo: json["coin_to"] as String,
        networkFrom: json["network_from"] as String,
        networkTo: json["network_to"] as String,
        withdrawalAmount: Decimal.parse(json["withdrawal_amount"].toString()),
        withdrawal: json["withdrawal"] as String,
        withdrawalExtraId: json["withdrawal_extra_id"] as String,
        rateId: json["rate_id"] as String,
        returnAddress: json["return"] as String?,
        returnExtraId: json["return_extra_id"] as String?,
        email: json["email"] as String?,
        partnerUserIp: json["partner_user_ip"] as String?,
      );

  Map<String, dynamic> toMap() => {
    "float": float,
    "coin_from": coinFrom,
    "coin_to": coinTo,
    "network_from": networkFrom,
    "network_to": networkTo,
    "withdrawal_amount": withdrawalAmount.toString(),
    "withdrawal": withdrawal,
    "withdrawal_extra_id": withdrawalExtraId,
    "rate_id": rateId,
    if (returnAddress != null) "return": returnAddress,
    if (returnExtraId != null) "return_extra_id": returnExtraId,
    if (email != null) "email": email,
    if (partnerUserIp != null) "partner_user_ip": partnerUserIp,
  };

  @override
  String toString() => toMap().toString();
}
