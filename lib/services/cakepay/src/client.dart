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
import 'models/card.dart';
import 'models/country.dart';
import 'models/order.dart';
import 'models/vendor.dart';

const _kTag = "CakePayClient";

class CakePayClient {
  final String baseUrl;
  final String apiToken;
  final HTTP _httpClient;

  CakePayClient({
    this.baseUrl = Endpoints.base,
    required this.apiToken,
    HTTP? httpClient,
  }) : _httpClient = httpClient ?? const HTTP();

  late final _authHeaders = {
    'Authorization': 'Bearer $apiToken',
    'Content-Type': 'application/json',
  };

  ({InternetAddress host, int port})? get _proxyInfo =>
      !AppConfig.hasFeature(AppFeature.tor)
      ? null
      : Prefs.instance.useTor
      ? TorService.sharedInstance.getProxyInfo()
      : null;

  // -- Marketplace --

  Future<ApiResponse<({List<CakePayVendor> vendors, int? nextPage})>>
  getVendors({
    String? country,
    String? countryCode,
    String? search,
    int? page,
    int? pageSize,
    bool? all,
    bool? giftCards,
    bool? prepaidCards,
    bool? onDemand,
    bool? custom,
  }) async {
    final query = <String, String>{};
    if (country != null) query['country'] = country;
    if (countryCode != null) query['country_code'] = countryCode;
    if (search != null) query['search'] = search;
    if (page != null) query['page'] = page.toString();
    if (pageSize != null) query['page_size'] = pageSize.toString();
    if (all != null) query['all'] = all.toString();
    if (giftCards != null) query['gift_cards'] = giftCards.toString();
    if (prepaidCards != null) query['prepaid_cards'] = prepaidCards.toString();
    if (onDemand != null) query['on_demand'] = onDemand.toString();
    if (custom != null) query['custom'] = custom.toString();

    return _requestRaw(
      'GET',
      '/marketplace/vendors/',
      query: query,
      parse: (body) {
        final dynamic decoded = jsonDecode(body);

        final List<dynamic> rawList = switch (decoded) {
          final List<dynamic> list => list,
          {"results": final List<dynamic> results} => results,
          _ => const <dynamic>[],
        };

        final List<CakePayVendor> vendors = rawList
            .whereType<Map<String, dynamic>>()
            .map(CakePayVendor.fromJson)
            .toList();

        final int? nextPage =
            (page != null && pageSize != null && vendors.length >= pageSize)
            ? page + 1
            : null;

        return (vendors: vendors, nextPage: nextPage);
      },
    );
  }

  Future<ApiResponse<CakePayCard>> getCard(int id) async {
    return _request(
      'GET',
      '/marketplace/cards/$id/',
      parse: CakePayCard.fromJson,
    );
  }

  Future<ApiResponse<List<CakePayCard>>> searchCards({
    String? query,
    String? category,
    String? country,
    double? minPrice,
    double? maxPrice,
    bool? availableOnly,
    int? page,
  }) async {
    final params = <String, String>{};
    if (query != null) params['query'] = query;
    if (category != null) params['category'] = category;
    if (country != null) params['country'] = country;
    if (minPrice != null) params['min_price'] = minPrice.toString();
    if (maxPrice != null) params['max_price'] = maxPrice.toString();
    if (availableOnly != null) {
      params['available_only'] = availableOnly.toString();
    }
    if (page != null) params['page'] = page.toString();

    return _requestRaw(
      'GET',
      '/marketplace/cards/search/',
      query: params,
      parse: (body) {
        final decoded = jsonDecode(body);
        if (decoded is List) {
          return decoded
              .whereType<Map<String, dynamic>>()
              .map(CakePayCard.fromJson)
              .toList();
        }
        if (decoded is Map<String, dynamic>) {
          final results = decoded['results'];
          if (results is List) {
            return results
                .whereType<Map<String, dynamic>>()
                .map(CakePayCard.fromJson)
                .toList();
          }
        }
        return [];
      },
    );
  }

  Future<ApiResponse<List<CakePayCard>>> getFeaturedCards({int? page}) async {
    final query = <String, String>{};
    if (page != null) query['page'] = page.toString();

    return _requestRaw(
      'GET',
      '/marketplace/cards/featured/',
      query: query,
      parse: (body) {
        final decoded = jsonDecode(body);
        if (decoded is List) {
          return decoded
              .whereType<Map<String, dynamic>>()
              .map(CakePayCard.fromJson)
              .toList();
        }
        if (decoded is Map<String, dynamic>) {
          final results = decoded['results'];
          if (results is List) {
            return results
                .whereType<Map<String, dynamic>>()
                .map(CakePayCard.fromJson)
                .toList();
          }
        }
        return [];
      },
    );
  }

  /// Fetches all countries by following pagination til last page.
  Future<ApiResponse<List<CakePayCountry>>> getAllCountries() async {
    try {
      final allCountries = <CakePayCountry>[];
      int page = 1;

      while (true) {
        final response = await _send(
          'GET',
          '/marketplace/countries/',
          query: {'page': page.toString()},
          overrideHeaders: {}, // Auth here leads to 403. Why? Who knows?
        );

        if (response.code < 200 || response.code >= 300) {
          Logging.instance.w(
            "$_kTag GET /marketplace/countries/ HTTP:${response.code} "
            "body: ${response.body}",
          );
          return ApiResponse(
            exception: ApiException.fromResponse(response.code, response.body),
          );
        }

        final decoded = jsonDecode(response.body);

        // This never gets hit according to docs
        // Handle non-paginated response (plain list).
        // if (decoded is List) {
        //   return ApiResponse(
        //     value: decoded
        //         .whereType<Map<String, dynamic>>()
        //         .map(CakePayCountry.fromJson)
        //         .toList(),
        //   );
        // }

        if (decoded is Map<String, dynamic>) {
          final results = decoded['results'];
          if (results is List) {
            allCountries.addAll(
              results.whereType<Map<String, dynamic>>().map(
                CakePayCountry.fromJson,
              ),
            );
          }

          // If there is no next page we're done.
          if (decoded['next'] == null) break;
        } else {
          break;
        }

        page++;
      }

      return ApiResponse(value: allCountries);
    } on ApiException catch (e) {
      Logging.instance.e("$_kTag getAllCountries threw: ", error: e);
      return ApiResponse(exception: e);
    } catch (e, s) {
      Logging.instance.e(
        "$_kTag getAllCountries threw: ",
        error: e,
        stackTrace: s,
      );
      return ApiResponse(exception: ApiException.network(e));
    }
  }

  /// List cards from the marketplace with optional pagination.
  Future<ApiResponse<List<CakePayCard>>> getCards({
    int? page,
    int? pageSize,
  }) async {
    final query = <String, String>{};
    if (page != null) query['page'] = page.toString();
    if (pageSize != null) query['page_size'] = pageSize.toString();

    return _requestRaw(
      'GET',
      '/marketplace/cards/',
      query: query,
      parse: (body) {
        final decoded = jsonDecode(body);
        if (decoded is List) {
          return decoded
              .whereType<Map<String, dynamic>>()
              .map(CakePayCard.fromJson)
              .toList();
        }
        if (decoded is Map<String, dynamic>) {
          final results = decoded['results'];
          if (results is List) {
            return results
                .whereType<Map<String, dynamic>>()
                .map(CakePayCard.fromJson)
                .toList();
          }
        }
        return [];
      },
    );
  }

  /// Fetches the list of marketplace providers.
  ///
  /// Endpoint: GET `/marketplace/providers/`
  Future<ApiResponse<List<Map<String, dynamic>>>> getProviders() async {
    return _requestRaw(
      'GET',
      '/marketplace/providers/',
      parse: (body) {
        final decoded = jsonDecode(body);
        if (decoded is List) {
          return decoded.whereType<Map<String, dynamic>>().toList();
        }
        if (decoded is Map<String, dynamic>) {
          final results = decoded['results'];
          if (results is List) {
            return results.whereType<Map<String, dynamic>>().toList();
          }
        }
        return [];
      },
    );
  }

  /// Fetches marketplace statistics.
  ///
  /// Endpoint: GET `/marketplace/stats/`
  Future<ApiResponse<Map<String, dynamic>>> getStats() async {
    return _request('GET', '/marketplace/stats/', parse: (json) => json);
  }

  Future<ApiResponse<List<String>>> getBannedCountries() async {
    return _requestRaw(
      'GET',
      '/core/banned_countries/',
      parse: (body) {
        final decoded = jsonDecode(body);
        if (decoded is List) {
          return decoded.whereType<String>().toList();
        }
        return [];
      },
    );
  }

  // -- Orders --

  /// Create an order via the seller API.
  ///
  /// Posts to `/orders/seller/create/`. The response wraps the order object
  /// in `{"message": "...", "order": {...}}`, so we extract `json['order']`
  /// before parsing.
  Future<ApiResponse<CakePayOrder>> createOrder({
    required int cardId,
    required String price,
    int? quantity,
    String? userEmail,
    bool? sendEmail,
    String? externalOrderId,
    String? markupPercent,
    bool? confirmsNoVpn,
    bool? confirmsVoidedRefund,
    bool? confirmsTermsAgreed,
  }) async {
    final body = <String, dynamic>{'card_id': cardId, 'price': price};
    if (quantity != null) body['quantity'] = quantity;
    if (userEmail != null) body['user_email'] = userEmail;
    if (sendEmail != null) body['send_email'] = sendEmail;
    if (externalOrderId != null) body['external_order_id'] = externalOrderId;
    if (markupPercent != null) body['markup_percent'] = markupPercent;
    if (confirmsNoVpn != null) body['confirms_no_vpn'] = confirmsNoVpn;
    if (confirmsVoidedRefund != null) {
      body['confirms_voided_refund'] = confirmsVoidedRefund;
    }
    if (confirmsTermsAgreed != null) {
      body['confirms_terms_agreed'] = confirmsTermsAgreed;
    }

    return _requestRaw(
      'POST',
      '/orders/seller/create/',
      body: body,
      parse: (responseBody) {
        final decoded = jsonDecode(responseBody);
        if (decoded is Map<String, dynamic>) {
          final orderData = decoded['order'];
          if (orderData is Map<String, dynamic>) {
            return CakePayOrder.fromJson(orderData);
          }
          return CakePayOrder.fromJson(decoded);
        }
        return CakePayOrder.fromJson({});
      },
    );
  }

  /// Fetch a single order via the seller API.
  Future<ApiResponse<CakePayOrder>> getOrder(String orderId) async {
    return _request(
      'GET',
      '/orders/seller/order/$orderId/',
      parse: CakePayOrder.fromJson,
    );
  }

  /// Fetch the current user's orders.
  ///
  /// **Note:** This endpoint requires Knox user authentication (email OTP
  /// flow), not the seller API key. It will fail when called with only the
  /// seller bearer token.
  Future<ApiResponse<List<CakePayOrder>>> getMyOrders({
    int? page,
    List<String>? orderIds,
  }) async {
    final query = <String, String>{};
    if (page != null) query['page'] = page.toString();
    if (orderIds != null && orderIds.isNotEmpty) {
      query['order_ids'] = orderIds.join(',');
    }

    return _requestRaw(
      'GET',
      '/orders/my_orders/',
      query: query,
      parse: (body) {
        final decoded = jsonDecode(body);
        if (decoded is List) {
          return decoded
              .whereType<Map<String, dynamic>>()
              .map(CakePayOrder.fromJson)
              .toList();
        }
        if (decoded is Map<String, dynamic>) {
          final results = decoded['results'];
          if (results is List) {
            return results
                .whereType<Map<String, dynamic>>()
                .map(CakePayOrder.fromJson)
                .toList();
          }
        }
        return [];
      },
    );
  }

  // -- Internal --

  Future<Response> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    Map<String, String>? overrideHeaders,
  }) async {
    var uri = Uri.parse('$baseUrl$path');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }
    final headers = overrideHeaders ?? _authHeaders;
    final proxy = _proxyInfo;

    Logging.instance.t("$_kTag $method $uri");

    switch (method) {
      case 'GET':
        return _httpClient.get(url: uri, headers: headers, proxyInfo: proxy);
      case 'POST':
        return _httpClient.post(
          url: uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
          proxyInfo: proxy,
        );
      default:
        throw ApiException('Unsupported method: $method');
    }
  }

  Future<ApiResponse<T>> _request<T>(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    required T Function(Map<String, dynamic>) parse,
  }) async {
    try {
      final response = await _send(method, path, body: body, query: query);

      if (response.code >= 200 && response.code < 300) {
        Logging.instance.t("$_kTag $method $path HTTP:${response.code}");
        if (response.body.isEmpty) {
          return ApiResponse(value: parse({}));
        }
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse(value: parse(json));
      } else {
        Logging.instance.w(
          "$_kTag $method $path HTTP:${response.code} "
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

  Future<ApiResponse<T>> _requestRaw<T>(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    required T Function(String) parse,
  }) async {
    try {
      final response = await _send(method, path, body: body, query: query);

      if (response.code >= 200 && response.code < 300) {
        Logging.instance.t("$_kTag $method $path HTTP:${response.code}");
        return ApiResponse(value: parse(response.body));
      } else {
        Logging.instance.w(
          "$_kTag $method $path HTTP:${response.code} "
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
