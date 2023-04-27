import 'dart:convert';

import 'package:http/http.dart' as http;

// WIP wrapper layer

abstract class HTTP {
  static Future<http.Response> get({
    required Uri url,
    Map<String, String>? headers,
    required bool routeOverTor,
  }) async {
    if (routeOverTor) {
      // TODO
      throw UnimplementedError();
    } else {
      return http.get(url, headers: headers);
    }
  }

  static Future<http.Response> post({
    required Uri url,
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    required bool routeOverTor,
  }) async {
    if (routeOverTor) {
      // TODO
      throw UnimplementedError();
    } else {
      return http.post(
        url,
        headers: headers,
        body: body,
        encoding: encoding,
      );
    }
  }
}
