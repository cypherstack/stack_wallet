import 'dart:convert';
import 'dart:io';

import '../../../app_config.dart';
import '../../../networking/http.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/prefs.dart';
import '../../tor_service.dart';
import 'api_exception.dart';
import 'api_response.dart';
import 'endpoints.dart';
import 'models/address.dart';
import 'models/car_research.dart';
import 'models/message.dart';
import 'models/payment.dart';
import 'models/ticket.dart';
import 'models/voucher.dart';
import 'token_manager.dart';

const _kTag = "ShopInBitClient";

class ShopInBitClient {
  final String accessKey;
  final String partnerSecret;
  final String baseUrl;
  final bool sandbox;
  final HTTP _httpClient;
  final TokenManager _tokenManager;

  ShopInBitClient({
    required this.accessKey,
    required this.partnerSecret,
    this.baseUrl = Endpoints.production,
    this.sandbox = false,
    String? externalCustomerKey,
    HTTP? httpClient,
  }) : _httpClient = httpClient ?? const HTTP(),
       _tokenManager = TokenManager(
         accessKey: accessKey,
         partnerSecret: partnerSecret,
         baseUrl: baseUrl,
         httpClient: httpClient,
       );

  // -- Auth --

  Future<ApiResponse<void>> authenticate() async {
    try {
      await _tokenManager.getValidToken();
      return ApiResponse();
    } on ApiException catch (e) {
      return ApiResponse(exception: e);
    } catch (e) {
      return ApiResponse(exception: ApiException('Authentication failed: $e'));
    }
  }

  // -- Utility --

  Future<ApiResponse<String>> generateKey() async {
    return _request(
      'GET',
      '/generate-key',
      customerKey: null,
      parse: (json) {
        return json['external_customer_key'] as String;
      },
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getHealth() async {
    return _request('GET', '/health', customerKey: null, parse: (json) => json);
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getCountries() async {
    return _requestRaw(
      'GET',
      '/meta/countries',
      customerKey: null,
      needsAuth: false,
      parse: (body) {
        final decoded = jsonDecode(body);
        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        }
        return [decoded as Map<String, dynamic>];
      },
    );
  }

  // -- Tickets --

  Future<ApiResponse<TicketRef>> createRequest({
    required String customerPseudonym,
    required String externalCustomerKey,
    required String serviceType,
    required String comment,
    required String deliveryCountry,
    String? voucherCode,
  }) async {
    return _request(
      'POST',
      '/requests',
      body: {
        'customer_pseudonym': customerPseudonym,
        'external_customer_key': externalCustomerKey,
        'service_type': serviceType,
        'comment': comment,
        'delivery_country': deliveryCountry,
        if (voucherCode != null) 'voucher_code': voucherCode,
      },
      parse: (json) {
        return TicketRef(
          id: json['ticket_id'] is int
              ? json['ticket_id'] as int
              : int.parse(json['ticket_id'].toString()),
          number: json['ticket_number'].toString(),
        );
      },
      customerKey: externalCustomerKey,
    );
  }

  Future<ApiResponse<TicketStatus>> getTicketStatus(
    int ticketId, {
    required String customerKey,
  }) async {
    return _request(
      'GET',
      '/tickets/$ticketId/status',
      parse: TicketStatus.fromJson,
      customerKey: customerKey,
    );
  }

  Future<ApiResponse<TicketFull>> getTicketFull(
    int ticketId, {
    required String customerKey,
  }) async {
    return _request(
      'GET',
      '/tickets/$ticketId/full',
      parse: TicketFull.fromJson,
      customerKey: customerKey,
    );
  }

  Future<ApiResponse<List<TicketRef>>> getTicketsByCustomer(
    String customerKey,
  ) async {
    return _request(
      'GET',
      '/tickets/by-customer/$customerKey',
      parse: (json) {
        final list = json['tickets'] as List<dynamic>;
        return list
            .map((e) => TicketRef.fromJson(e as Map<String, dynamic>))
            .toList();
      },
      customerKey: customerKey,
    );
  }

  // -- Messages --

  Future<ApiResponse<Map<String, dynamic>>> sendMessage(
    int ticketId,
    String message, {
    required String customerKey,
  }) async {
    return _request(
      'POST',
      '/tickets/$ticketId/messages',
      body: {'message': message},
      parse: (json) => json,
      customerKey: customerKey,
    );
  }

  Future<ApiResponse<List<TicketMessage>>> getMessages(
    int ticketId, {
    required String customerKey,
  }) async {
    return _request(
      'GET',
      '/tickets/$ticketId/messages',
      parse: (json) {
        final list = json['messages'] as List<dynamic>;
        return list
            .map((e) => TicketMessage.fromJson(e as Map<String, dynamic>))
            .toList();
      },
      customerKey: customerKey,
    );
  }

  // -- Attachments --

  Future<ApiResponse<Map<String, dynamic>>> sendAttachments(
    int ticketId, {
    required String message,
    required List<Map<String, String>> attachments,
    required String customerKey,
  }) async {
    return _request(
      'POST',
      '/tickets/$ticketId/attachments',
      body: {'message': message, 'attachments': attachments},
      parse: (json) => json,
      customerKey: customerKey,
    );
  }

  /// Build a URL for fetching an attachment via `/attachment-proxy/<path>`.
  ///
  /// For use in HTTP clients that can set headers, use the returned URL with
  /// the standard Authorization + External-Customer-Key headers.
  /// For inline images (e.g. in HTML where headers can't be set), pass
  /// [useQueryAuth] = true to append token and customer_key as query params.
  Future<ApiResponse<Uri>> getAttachmentUrl(
    String attachmentPath, {
    String? customerKey,
    bool useQueryAuth = false,
  }) async {
    try {
      final token = await _tokenManager.getValidToken();
      final resolved = _resolvePath('/attachment-proxy/$attachmentPath');
      var uri = Uri.parse('$baseUrl$resolved');
      if (useQueryAuth) {
        uri = uri.replace(
          queryParameters: {
            'token': token,
            if (customerKey != null) 'customer_key': customerKey,
          },
        );
      }
      return ApiResponse(value: uri);
    } on ApiException catch (e) {
      return ApiResponse(exception: e);
    } catch (e) {
      return ApiResponse(exception: ApiException.network(e));
    }
  }

  /// Download an attachment from `/attachment-proxy/<path>`.
  Future<ApiResponse<Response>> getAttachment(
    String attachmentPath, {
    String? customerKey,
  }) async {
    try {
      final token = await _tokenManager.getValidToken();
      final resolved = _resolvePath('/attachment-proxy/$attachmentPath');
      final uri = Uri.parse('$baseUrl$resolved');
      Logging.instance.t("$_kTag GET $uri");
      final headers = _headers(token, customerKey: customerKey);
      final response = await _httpClient.get(
        url: uri,
        headers: headers,
        proxyInfo: _proxyInfo,
      );
      if (response.code >= 200 && response.code < 300) {
        return ApiResponse(value: response);
      } else {
        Logging.instance.w(
          "$_kTag GET $resolved HTTP:${response.code} "
          "body: ${response.body}",
        );
        return ApiResponse(
          exception: ApiException.fromResponse(response.code, response.body),
        );
      }
    } on ApiException catch (e) {
      Logging.instance.e(
        "$_kTag getAttachment($attachmentPath) threw: ",
        error: e,
      );
      return ApiResponse(exception: e);
    } catch (e, s) {
      Logging.instance.e(
        "$_kTag getAttachment($attachmentPath) threw: ",
        error: e,
        stackTrace: s,
      );
      return ApiResponse(exception: ApiException.network(e));
    }
  }

  // -- Address --

  Future<ApiResponse<Map<String, dynamic>>> submitAddress(
    int ticketId, {
    required Address shipping,
    required String customerKey,
    Address? billing,
  }) async {
    return _request(
      'POST',
      '/tickets/$ticketId/address',
      body: {'shipping': shipping.toJson(), 'billing': billing?.toJson()},
      parse: (json) => json,
      customerKey: customerKey,
    );
  }

  // -- Payment --

  /// Read existing invoice state. Use this for polling, page-reload recovery,
  /// and any view that just wants to show the current invoice; per ShopinBit
  /// 1.0.4 this endpoint is read-only and will not create or regenerate the
  /// invoice. Call [putPayment] for that.
  Future<ApiResponse<PaymentInfo>> getPayment(
    int ticketId, {
    required String customerKey,
  }) async {
    return _request(
      'GET',
      '/tickets/$ticketId/payment',
      parse: PaymentInfo.fromJson,
      customerKey: customerKey,
    );
  }

  /// Create or regenerate the BTCPay invoice for [ticketId]. Per the 1.0.4
  /// spec call this only after the customer has accepted the offer, submitted
  /// shipping/billing, seen the Terms & Conditions, and explicitly clicked
  /// PAY NOW.  Repeated calls regenerate the invoice and invalidate any in-
  /// flight payment.
  Future<ApiResponse<PaymentInfo>> putPayment(
    int ticketId, {
    required String customerKey,
  }) async {
    return _request(
      'PUT',
      '/tickets/$ticketId/payment',
      parse: PaymentInfo.fromJson,
      customerKey: customerKey,
    );
  }

  // -- Vouchers --

  /// Pre-check a voucher code (does not consume usage or create a ticket).
  Future<ApiResponse<VoucherInfo>> checkVoucher(
    String code, {
    required String customerKey,
  }) async {
    return _request(
      'GET',
      '/vouchers/validate',
      query: {'code': code},
      parse: VoucherInfo.fromJson,
      customerKey: customerKey,
    );
  }

  /// Redeem a VIP voucher (creates ticket in one call). VIP/VIP_PRIORITY only.
  Future<ApiResponse<VipRedemptionResult>> redeemVipVoucher({
    required String voucherCode,
    required String customerPseudonym,
    required String serviceType,
    required String comment,
    required String customerKey,
    String? deliveryCountry,
  }) async {
    return _request(
      'POST',
      '/vouchers/validate',
      body: {
        'voucher_code': voucherCode,
        'customer_pseudonym': customerPseudonym,
        'service_type': serviceType,
        'comment': comment,
        if (deliveryCountry != null) 'delivery_country': deliveryCountry,
      },
      parse: VipRedemptionResult.fromJson,
      customerKey: customerKey,
    );
  }

  // -- Car Research Fee --

  Future<ApiResponse<CarResearchInvoice>> createCarResearchInvoice({
    required Address billing,
    required String customerKey,
    CarResearchRequest? request,
  }) async {
    return _request(
      'POST',
      '/car-research/invoice',
      body: {
        'billing': billing.toJson(),
        if (request != null) 'request': request.toJson(),
        'external_customer_key': customerKey,
      },
      parse: CarResearchInvoice.fromJson,
      customerKey: customerKey,
    );
  }

  /// Unresolved car research invoices for the current partner/customer pair.
  /// Used to recover a fee payment the user started but did not finish.
  Future<ApiResponse<List<CarResearchCurrentInvoice>>>
  getCurrentCarResearchInvoices({required String customerKey}) async {
    return _requestRaw(
      'GET',
      '/car-research/invoices/current',
      parse: (body) {
        if (body.isEmpty) return <CarResearchCurrentInvoice>[];
        final decoded = jsonDecode(body);
        final list = decoded is List
            ? decoded
            : (decoded as Map<String, dynamic>)['invoices'] as List? ??
                  const [];
        return list
            .map(
              (e) =>
                  CarResearchCurrentInvoice.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      },
      customerKey: customerKey,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getCarResearchInvoiceStatus(
    String invoiceId, {
    required String customerKey,
  }) async {
    return _request(
      'GET',
      '/car-research/invoice/$invoiceId/status',
      parse: (json) => json,
      customerKey: customerKey,
    );
  }

  Future<ApiResponse<CarResearchPaymentResult>> logCarResearchPayment(
    String invoiceId, {

    required String customerKey,
  }) async {
    return _request(
      'POST',
      '/car-research/log-payment',
      body: {'invoice_id': invoiceId, 'external_customer_key': customerKey},
      parse: CarResearchPaymentResult.fromJson,
      customerKey: customerKey,
    );
  }

  // -- Push Notifications --

  Future<ApiResponse<Map<String, dynamic>>> registerPushSubscription({
    String? deviceToken,
    String? endpoint,
    Map<String, String>? keys,
    String? platform,
    String? environment,
    String? expirationTime,
    int? ticketId,

    required String customerKey,
  }) async {
    return _request(
      'POST',
      '/notifications/push-subscriptions',
      body: {
        if (deviceToken != null) 'deviceToken': deviceToken,
        if (endpoint != null) 'endpoint': endpoint,
        if (keys != null) 'keys': keys,
        if (platform != null) 'platform': platform,
        if (environment != null) 'environment': environment,
        if (expirationTime != null) 'expirationTime': expirationTime,
        if (ticketId != null) 'ticketId': ticketId,
      },
      parse: (json) => json,
      customerKey: customerKey,
    );
  }

  // -- Webhooks --

  Future<ApiResponse<List<Map<String, dynamic>>>> listWebhooks() async {
    return _request(
      'GET',
      '/partners/webhooks',
      customerKey: null,
      parse: (json) {
        if (json.containsKey('webhooks')) {
          return (json['webhooks'] as List<dynamic>)
              .cast<Map<String, dynamic>>();
        }
        return [json];
      },
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> createWebhook({
    required String webhookUrl,
    required List<String> eventTypes,
  }) async {
    return _request(
      'POST',
      '/partners/webhooks',
      customerKey: null,
      body: {'webhook_url': webhookUrl, 'event_types': eventTypes},
      parse: (json) => json,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> rotateWebhookSecret(
    String webhookId,
  ) async {
    return _request(
      'POST',
      '/partners/webhooks/$webhookId/rotate',
      customerKey: null,
      parse: (json) => json,
    );
  }

  Future<ApiResponse<void>> deleteWebhook(String webhookId) async {
    return _request(
      'DELETE',
      '/partners/webhooks/$webhookId',
      customerKey: null,
      parse: (_) {},
    );
  }

  // -- Sandbox --

  Future<ApiResponse<Map<String, dynamic>>> sandboxSetState(
    int ticketId,
    String state, {
    required String customerKey,
  }) async {
    return _request(
      'POST',
      '/sandbox/state/$ticketId/$state',
      parse: (json) => json,
      customerKey: customerKey,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> sandboxSetPayment(
    int ticketId,
    String status, {
    required String customerKey,
  }) async {
    return _request(
      'POST',
      '/sandbox/payment/$ticketId/$status',
      parse: (json) => json,
      customerKey: customerKey,
    );
  }

  // -- Internals --

  ({InternetAddress host, int port})? get _proxyInfo =>
      !AppConfig.hasFeature(AppFeature.tor)
      ? null
      : Prefs.instance.useTor
      ? TorService.sharedInstance.getProxyInfo()
      : null;

  /// Prepend /sandbox to paths when in sandbox mode, except for paths that
  /// already start with /sandbox, /meta, /health, or /token.
  String _resolvePath(String path) {
    if (!sandbox) return path;
    if (path.startsWith('/sandbox') ||
        path.startsWith('/meta') ||
        path.startsWith('/health') ||
        path.startsWith('/token') ||
        path.startsWith('/partners')) {
      return path;
    }
    return '/sandbox$path';
  }

  Map<String, String> _headers(String token, {String? customerKey}) {
    final h = <String, String>{
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (customerKey != null) {
      h['External-Customer-Key'] = customerKey;
    }
    return h;
  }

  Future<Response> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    required String? customerKey,
    bool needsAuth = true,
  }) async {
    final resolved = _resolvePath(path);
    var uri = Uri.parse('$baseUrl$resolved');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }
    final Map<String, String> headers;
    if (needsAuth) {
      final token = await _tokenManager.getValidToken();
      headers = _headers(token, customerKey: customerKey);
    } else {
      headers = {'Accept': 'application/json'};
    }
    final proxy = _proxyInfo;

    Logging.instance.t("$_kTag $method $uri");

    switch (method) {
      case 'GET':
        return _httpClient.get(url: uri, headers: headers, proxyInfo: proxy);
      case 'POST':
        return _httpClient.post(
          url: uri,
          headers: headers,
          body: body != null ? _asciiSafeJson(body) : null,
          proxyInfo: proxy,
        );
      case 'PUT':
        return _httpClient.put(
          url: uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
          proxyInfo: proxy,
        );
      case 'PATCH':
        return _httpClient.patch(
          url: uri,
          headers: headers,
          body: body != null ? _asciiSafeJson(body) : null,
          proxyInfo: proxy,
        );
      case 'DELETE':
        return _httpClient.delete(url: uri, headers: headers, proxyInfo: proxy);
      default:
        throw ApiException('Unsupported method: $method');
    }
  }

  // Encode [body] as JSON with all non-ASCII characters replaced by \uXXXX
  // escapes. The HTTP wrapper writes string bodies with the latin1 default of
  // HttpClientRequest.write, which mangles multi-byte UTF-8 like the U+00B1/±.
  static String _asciiSafeJson(Object body) {
    final raw = jsonEncode(body);
    final buf = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      final c = raw.codeUnitAt(i);
      if (c < 0x80) {
        buf.writeCharCode(c);
      } else {
        buf.write('\\u');
        buf.write(c.toRadixString(16).padLeft(4, '0'));
      }
    }
    return buf.toString();
  }

  Future<ApiResponse<T>> _request<T>(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    required String? customerKey,
    required T Function(Map<String, dynamic>) parse,
  }) async {
    try {
      final response = await _send(
        method,
        path,
        body: body,
        query: query,
        customerKey: customerKey,
      );

      final resolved = _resolvePath(path);

      if (response.code >= 200 && response.code < 300) {
        Logging.instance.t("$_kTag $method $resolved HTTP:${response.code}");
        if (response.body.isEmpty) {
          return ApiResponse(value: parse({}));
        }
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse(value: parse(json), customerKey: customerKey);
      } else {
        Logging.instance.w(
          "$_kTag $method $resolved HTTP:${response.code} "
          "body: ${response.body}",
        );
        return ApiResponse(
          exception: ApiException.fromResponse(response.code, response.body),
        );
      }
    } on ApiException catch (e) {
      Logging.instance.e("$_kTag _request($method $path) threw: ", error: e);
      return ApiResponse(exception: e);
    } catch (e, s) {
      Logging.instance.e(
        "$_kTag _request($method $path) threw: ",
        error: e,
        stackTrace: s,
      );
      return ApiResponse(exception: ApiException.network(e));
    }
  }

  /// Like [_request] but gives the parse function the raw response body
  /// string, for endpoints that return non-object JSON (e.g. arrays).
  Future<ApiResponse<T>> _requestRaw<T>(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    required String? customerKey,
    bool needsAuth = true,
    required T Function(String) parse,
  }) async {
    try {
      final response = await _send(
        method,
        path,
        body: body,
        query: query,
        customerKey: customerKey,
        needsAuth: needsAuth,
      );

      final resolved = _resolvePath(path);

      if (response.code >= 200 && response.code < 300) {
        Logging.instance.t("$_kTag $method $resolved HTTP:${response.code}");
        return ApiResponse(value: parse(response.body));
      } else {
        Logging.instance.w(
          "$_kTag $method $resolved HTTP:${response.code} "
          "body: ${response.body}",
        );
        return ApiResponse(
          exception: ApiException.fromResponse(response.code, response.body),
        );
      }
    } on ApiException catch (e) {
      Logging.instance.e("$_kTag _requestRaw($method $path) threw: ", error: e);
      return ApiResponse(exception: e);
    } catch (e, s) {
      Logging.instance.e(
        "$_kTag _requestRaw($method $path) threw: ",
        error: e,
        stackTrace: s,
      );
      return ApiResponse(exception: ApiException.network(e));
    }
  }
}
