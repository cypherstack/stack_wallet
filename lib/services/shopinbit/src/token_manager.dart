import 'dart:async';
import 'dart:convert';

import '../../../app_config.dart';
import '../../../networking/http.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/prefs.dart';
import '../../tor_service.dart';
import 'api_exception.dart';
import 'models/auth_token.dart';

class TokenManager {
  final String accessKey;
  final String partnerSecret;
  final String baseUrl;
  final HTTP _httpClient;

  AuthToken? _token;
  Completer<String>? _refreshCompleter;

  TokenManager({
    required this.accessKey,
    required this.partnerSecret,
    required this.baseUrl,
    HTTP? httpClient,
  }) : _httpClient = httpClient ?? const HTTP();

  Future<String> getValidToken() {
    if (_token != null && !_token!.expiresSoon) {
      return Future.value(_token!.accessToken);
    }

    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    final completer = Completer<String>();
    _refreshCompleter = completer;

    _authenticate()
        .then((token) {
          _token = token;
          completer.complete(token.accessToken);
        })
        .catchError((Object e) {
          completer.completeError(e);
        })
        .whenComplete(() {
          _refreshCompleter = null;
        });

    return completer.future;
  }

  Future<AuthToken> _authenticate() async {
    final uri = Uri.parse('$baseUrl/token');
    Logging.instance.t("ShopInBitClient POST $uri (authenticate)");

    final Response response;
    try {
      response = await _httpClient.post(
        url: uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: Uri(
          queryParameters: {'username': accessKey, 'password': partnerSecret},
        ).query,
        proxyInfo: !AppConfig.hasFeature(AppFeature.tor)
            ? null
            : Prefs.instance.useTor
            ? TorService.sharedInstance.getProxyInfo()
            : null,
      );
    } catch (e, s) {
      Logging.instance.e(
        "ShopInBitClient authenticate() network error: ",
        error: e,
        stackTrace: s,
      );
      throw ApiException.network(e);
    }

    if (response.code != 200) {
      Logging.instance.w(
        "ShopInBitClient authenticate() HTTP:${response.code} "
        "body: ${response.body}",
      );
      throw ApiException.fromResponse(response.code, response.body);
    }

    Logging.instance.t("ShopInBitClient authenticate() success");
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthToken.fromJson(json);
  }

  void invalidate() {
    _token = null;
  }
}
