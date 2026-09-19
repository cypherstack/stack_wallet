import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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

// 429 retry policy: up to 3 retries, backoff capped at 30s.
const int _kMaxRetries = 3;
const Duration _kMaxBackoff = Duration(seconds: 30);

// Per-request ceiling so a stalled socket (common on a sleeping/backgrounded
// device) can't hang a request forever. A hung poll would otherwise latch the
// caller's in-flight guard and silently stop all further polling.
const Duration _kRequestTimeout = Duration(seconds: 30);

// Uploads can carry up to 50 MB; the 30s request ceiling would kill them on
// slow links, so multipart sends get their own generous ceiling.
const _kUploadTimeout = Duration(minutes: 5);

class ShopInBitClient {
  final String accessKey;
  final String partnerSecret;
  final String baseUrl;
  final bool sandbox;
  final HTTP _httpClient;
  final TokenManager _tokenManager;
  final Random _rng = Random();

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
    required String? deliveryState,
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
        if (deliveryState != null) 'delivery_state': deliveryState,
        if (voucherCode != null) 'voucher_code': voucherCode,
      },
      parse: (json) {
        return TicketRef(
          id: json['ticket_id'] is int
              ? json['ticket_id'] as int
              : int.parse(json['ticket_id'].toString()),
          number: json['ticket_number'] as String,
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
        // Tolerate a single malformed message: skip it rather than throwing,
        // which would discard the entire conversation for this (and every
        // subsequent) poll and silently stall the chat.
        final messages = <TicketMessage>[];
        for (final raw in list) {
          try {
            messages.add(TicketMessage.fromJson(raw as Map<String, dynamic>));
          } catch (e, s) {
            Logging.instance.w(
              "$_kTag skipping malformed ticket message",
              error: e,
              stackTrace: s,
            );
          }
        }
        return messages;
      },
      customerKey: customerKey,
    );
  }

  // -- Attachments --

  Future<ApiResponse<Map<String, dynamic>>> sendAttachments(
    int ticketId, {
    required String message,
    required List<File> attachments,
    required String customerKey,
  }) async {
    if (attachments.isEmpty) {
      return _validationError(
        "No files to upload. Use POST /tickets/{id}/messages for text-only messages.",
      );
    }

    int combinedBytes = 0;
    final List<_AttachmentUpload> uploads = [];

    for (final file in attachments) {
      final fileName = file.uri.pathSegments.last;
      final resolved = resolveAttachmentType(fileName);

      if (resolved == null) {
        return _validationError("Unsupported file type: $fileName");
      }

      final sizeBytes = await file.length();
      if (sizeBytes > resolved.category.maxBytes) {
        return _validationError(
          "$fileName is larger than the "
          "${resolved.category.maxBytes ~/ 1000000} MB "
          "${resolved.category.name} limit",
        );
      }

      combinedBytes += sizeBytes;
      if (combinedBytes > kCombinedAttachmentMaxBytes) {
        return _validationError("Combined upload size exceeds the 50 MB limit");
      }

      uploads.add((path: file.path, contentType: resolved.mimeType));
    }

    return _multipartRequest(
      "/tickets/$ticketId/attachments",
      fields: {"message": message},
      uploads: uploads,
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
      final response = await _httpClient
          .get(url: uri, headers: headers, proxyInfo: _proxyInfo)
          .timeout(_kRequestTimeout);
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
  /// Create a payment invoice, or regenerate an expired/invalid one with
  /// [retry] = true (spec: PUT ...?retry=true).
  Future<ApiResponse<PaymentInfo>> putPayment(
    int ticketId, {
    required String customerKey,
    bool retry = false,
  }) async {
    return _request(
      'PUT',
      '/tickets/$ticketId/payment',
      query: retry ? const {'retry': 'true'} : null,
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

  /// Create the car research fee invoice. Both [billing] and [request] are
  /// required; without a request the server returns 422 and creates nothing.
  /// The stored request lets the backend build the customer-facing car ticket
  /// once the fee is paid.
  Future<ApiResponse<CarResearchInvoice>> createCarResearchInvoice({
    required Address billing,
    required CarResearchRequest request,
    required String customerKey,
  }) async {
    return _request(
      'POST',
      '/car-research/invoice',
      body: {
        'billing': billing.toJson(),
        'request': request.toJson(),
        'external_customer_key': customerKey,
      },
      parse: CarResearchInvoice.fromJson,
      customerKey: customerKey,
    );
  }

  /// Replace [invoiceId] using the billing/request payload already stored by
  /// the server.
  Future<ApiResponse<CarResearchInvoice>> retryCarResearchInvoice({
    required String invoiceId,
    required String customerKey,
  }) async {
    return _request(
      'POST',
      '/car-research/invoice',
      body: {'invoice_id': invoiceId, 'retry': true},
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

  /// Poll the car research invoice status. Read-only: it never confirms
  /// payment. Once [CarResearchInvoiceStatus.finalized] is true the response
  /// carries the receipt and real ticket references.
  Future<ApiResponse<CarResearchInvoiceStatus>> getCarResearchInvoiceStatus(
    String invoiceId, {
    required String customerKey,
  }) async {
    return _request(
      'GET',
      '/car-research/invoice/$invoiceId/status',
      parse: CarResearchInvoiceStatus.fromJson,
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
    Map<String, String> headers;
    if (needsAuth) {
      final token = await _tokenManager.getValidToken();
      headers = _headers(token, customerKey: customerKey);
    } else {
      headers = {'Accept': 'application/json'};
    }
    final proxy = _proxyInfo;

    Logging.instance.t("$_kTag $method $uri");

    Future<Response> dispatch() {
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
          return _httpClient.delete(
            url: uri,
            headers: headers,
            proxyInfo: proxy,
          );
        default:
          throw ApiException('Unsupported method: $method');
      }
    }

    // Retry on 429 (Too Many Requests) with backoff so we stop hammering the
    // API the moment it tells us to. Respects a server-sent Retry-After when
    // present, otherwise exponential backoff with jitter. Everything funnels
    // through here, so all endpoints get this for free.
    int attempt = 0;
    bool reauthed = false;
    while (true) {
      final response = await dispatch().timeout(_kRequestTimeout);
      // A 401 means the bearer token is stale/expired: invalidate it,
      // re-authenticate once, and retry before surfacing the error.
      if (response.code == 401 && needsAuth && !reauthed) {
        reauthed = true;
        _tokenManager.invalidate();
        final token = await _tokenManager.getValidToken();
        headers = _headers(token, customerKey: customerKey);
        Logging.instance.w(
          "$_kTag $method $resolved HTTP:401, re-authenticating",
        );
        continue;
      }
      if (response.code != 429 || attempt >= _kMaxRetries) {
        return response;
      }
      final Duration delay = _backoffDelay(attempt, response.headers);
      Logging.instance.w(
        "$_kTag $method $resolved HTTP:429, backing off "
        "${delay.inMilliseconds}ms (retry ${attempt + 1}/$_kMaxRetries)",
      );
      await Future<void>.delayed(delay);
      attempt++;
    }
  }

  /// Next poll interval after a failed poll: double [current], capped at [max].
  static Duration nextPollBackoff(Duration current, Duration max) {
    final Duration next = current * 2;
    return next > max ? max : next;
  }

  /// How long to wait before retrying a 429. Prefers a sane `Retry-After`
  /// header; otherwise 1s, 2s, 4s... with jitter, capped at [_kMaxBackoff].
  Duration _backoffDelay(int attempt, Map<String, String> headers) {
    final Duration? retryAfter = _parseRetryAfter(headers['retry-after']);
    if (retryAfter != null) {
      return retryAfter > _kMaxBackoff ? _kMaxBackoff : retryAfter;
    }
    final int base = 1000 * (1 << attempt);
    final int ms = base + _rng.nextInt(500);
    return ms > _kMaxBackoff.inMilliseconds
        ? _kMaxBackoff
        : Duration(milliseconds: ms);
  }

  /// Parse a `Retry-After` value, which is either delay-seconds or an
  /// HTTP-date. Returns null if absent or unparseable.
  Duration? _parseRetryAfter(String? value) {
    if (value == null) return null;
    final String trimmed = value.trim();
    final int? seconds = int.tryParse(trimmed);
    if (seconds != null) {
      return seconds < 0 ? Duration.zero : Duration(seconds: seconds);
    }
    try {
      final Duration diff = HttpDate.parse(trimmed).difference(DateTime.now());
      return diff.isNegative ? Duration.zero : diff;
    } catch (_) {
      return null;
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

      if (kDebugMode) {
        Logging.instance.i(
          "$_kTag $method   HTTP:${response.code} "
          "body: ${response.body}",
        );
      }

      final resolved = _resolvePath(path);

      if (response.code >= 200 && response.code < 300) {
        Logging.instance.t("$_kTag $method $resolved HTTP:${response.code}");
        if (response.body.isEmpty) {
          // An empty 2xx body would make object parsers fabricate placeholder
          // objects (e.g. a ticket with id 0); surface it as an error instead.
          return ApiResponse(
            exception: ApiException(
              "Empty response body for $method $resolved",
            ),
          );
        }
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse(value: parse(json));
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

  /// Client-side rejection: the request never left the device. Uses the same
  /// ApiException channel as server failures so call sites handle one format.
  ApiResponse<T> _validationError<T>(String message) =>
      ApiResponse(exception: ApiException(message));

  /// Multipart sibling of [_request]. package:http is used only to *encode*
  /// the multipart/form-data body.
  /// Transport goes through [_httpClient] so uploads ride the same
  /// Tor-capable pipe as every other request.
  ///
  /// The encoded body is held in memory once (bounded to 50 MB by the
  /// validation in [sendAttachments]) so the 401 re-auth can resend it
  /// without re-reading files from disk. Deliberately no 429 auto-retry:
  /// unlike [_send], a retry here would re-send the full upload body, which
  /// the user should trigger explicitly.
  Future<ApiResponse<T>> _multipartRequest<T>(
    String path, {
    required Map<String, String> fields,
    required List<_AttachmentUpload> uploads,
    required T Function(Map<String, dynamic>) parse,
    required String customerKey,
  }) async {
    final resolved = _resolvePath(path);
    final uri = Uri.parse("$baseUrl$resolved");

    try {
      // Encode once. finalize() fixes the boundary and yields the body
      // stream; the content-type header carrying that boundary is only
      // valid after finalize() has run, so it is read afterwards.
      final encoder = http.MultipartRequest("POST", uri)..fields.addAll(fields);
      for (final upload in uploads) {
        encoder.files.add(
          await http.MultipartFile.fromPath(
            "attachments", // repeated field name, as the doc specifies
            upload.path,
            contentType: http.MediaType.parse(upload.contentType),
          ),
        );
      }
      final bodyBytes = await encoder.finalize().toBytes();
      final contentType = encoder.headers["content-type"]!;

      Future<Response> sendOnce(String token) {
        Logging.instance.t("$_kTag POST $uri");
        return _httpClient
            .postBytes(
              url: uri,
              headers: {
                "Authorization": "Bearer $token",
                "External-Customer-Key": customerKey,
                "Content-Type": contentType,
                "Accept": "application/json",
              },
              bodyBytes: bodyBytes,
              proxyInfo: _proxyInfo,
            )
            .timeout(_kUploadTimeout);
      }

      Response response = await sendOnce(await _tokenManager.getValidToken());

      // Mirror [_send]'s single re-auth on a stale bearer token; the encoded
      // bytes are immutable, so resending needs no rebuild.
      if (response.code == 401) {
        _tokenManager.invalidate();
        Logging.instance.w("$_kTag POST $resolved HTTP:401, re-authenticating");
        response = await sendOnce(await _tokenManager.getValidToken());
      }

      if (response.code >= 200 && response.code < 300) {
        Logging.instance.t("$_kTag POST $resolved HTTP:${response.code}");
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse(value: parse(json));
      } else {
        Logging.instance.w(
          "$_kTag POST $resolved HTTP:${response.code} "
          "body: ${response.body}",
        );
        return ApiResponse(
          exception: ApiException.fromResponse(response.code, response.body),
        );
      }
    } on ApiException catch (e) {
      Logging.instance.e(
        "$_kTag _multipartRequest(POST $path) threw: ",
        error: e,
      );
      return ApiResponse(exception: e);
    } catch (e, s) {
      Logging.instance.e(
        "$_kTag _multipartRequest(POST $path) threw: ",
        error: e,
        stackTrace: s,
      );
      return ApiResponse(exception: ApiException.network(e));
    }
  }
}

/// Per-category limits from POST /tickets/{ticket_id}/attachments.
///
/// The doc says "MB" without defining it, so the stricter 1000-based reading
/// is enforced: a client-side pass then implies a server-side pass under
/// either interpretation. Confirm with it@shopinbit.com and pin the answer
/// here.
enum AttachmentCategory {
  image(5 * 1000 * 1000),
  document(10 * 1000 * 1000),
  video(50 * 1000 * 1000);

  const AttachmentCategory(this.maxBytes);

  final int maxBytes;
}

/// Combined upload cap for a single attachments message.
const kCombinedAttachmentMaxBytes = 50 * 1000 * 1000;

/// Extensions accepted by [resolveAttachmentType], in file-picker
/// allowedExtensions form (no dots). Keep in sync with the switch in
/// [resolveAttachmentType]; drift fails safe because every picked file is
/// re-validated through the resolver anyway.
const kAllowedAttachmentExtensions = [
  "jpg", "jpeg", "png", "webp", "heic", "heif", "gif", // images
  "pdf", "docx", "xlsx", "odt", // documents
  "mp4", "mov", "webm", "3gp", "3gpp", // videos
];

typedef ResolvedAttachment = ({String mimeType, AttachmentCategory category});

/// Path + content type, materialized into multipart bytes inside
/// [_multipartRequest]: validation stays separate from encoding, and the
/// encoded bytes can be resent on 401 without re-reading files from disk.
typedef _AttachmentUpload = ({String path, String contentType});

/// Maps a filename to its API-supported MIME type and size category.
/// Returns null for unsupported types. Public so the UI can validate at
/// pick time with the same rules [ShopInBitClient.sendAttachments] enforces
/// at send time.
ResolvedAttachment? resolveAttachmentType(String fileName) {
  final extension = fileName.split(".").last.toLowerCase();
  return switch (extension) {
    "jpg" || "jpeg" => (mimeType: "image/jpeg", category: .image),
    "png" => (mimeType: "image/png", category: .image),
    "webp" => (mimeType: "image/webp", category: .image),
    "heic" => (mimeType: "image/heic", category: .image),
    "heif" => (mimeType: "image/heif", category: .image),
    "gif" => (mimeType: "image/gif", category: .image),
    "pdf" => (mimeType: "application/pdf", category: .document),
    "docx" => (
      mimeType:
          "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      category: .document,
    ),
    "xlsx" => (
      mimeType:
          "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      category: .document,
    ),
    "odt" => (
      mimeType: "application/vnd.oasis.opendocument.text",
      category: .document,
    ),
    "mp4" => (mimeType: "video/mp4", category: .video),
    "mov" => (mimeType: "video/quicktime", category: .video),
    "webm" => (mimeType: "video/webm", category: .video),
    "3gp" || "3gpp" => (mimeType: "video/3gpp", category: .video),
    _ => null,
  };
}
