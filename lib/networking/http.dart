import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:socks5_proxy/socks_client.dart';
import 'package:stackwallet/services/tor_service.dart';
import 'package:stackwallet/utilities/logger.dart';

// WIP wrapper layer

// TODO expand this class
class Response {
  final int code;
  final String body;

  Response(this.body, this.code);
}

class HTTP {
  /// Visible for testing so we can override with a mock TorService
  @visibleForTesting
  TorService torService = TorService.sharedInstance;

  Future<Response> get({
    required Uri url,
    Map<String, String>? headers,
    required bool routeOverTor,
  }) async {
    final httpClient = HttpClient();
    try {
      if (routeOverTor) {
        SocksTCPClient.assignToHttpClient(httpClient, [
          ProxySettings(
            torService.proxyInfo.host,
            torService.proxyInfo.port,
          ),
        ]);
      }
      final HttpClientRequest request = await httpClient.getUrl(
        url,
      );

      request.headers.clear();
      if (headers != null) {
        headers.forEach((key, value) => request.headers.add);
      }

      final response = await request.close();
      return Response(
        await response.transform(utf8.decoder).join(),
        response.statusCode,
      );
    } catch (e, s) {
      Logging.instance.log(
        "HTTP.get() rethrew: $e\n$s",
        level: LogLevel.Info,
      );
      rethrow;
    } finally {
      httpClient.close(force: true);
    }
  }

  Future<Response> post({
    required Uri url,
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    required bool routeOverTor,
  }) async {
    final httpClient = HttpClient();
    try {
      if (routeOverTor) {
        SocksTCPClient.assignToHttpClient(httpClient, [
          ProxySettings(
            torService.proxyInfo.host,
            torService.proxyInfo.port,
          ),
        ]);
      }
      final HttpClientRequest request = await httpClient.postUrl(
        url,
      );

      request.headers.clear();

      if (headers != null) {
        headers.forEach((key, value) => request.headers.add);
      }

      request.write(body);

      final response = await request.close();
      return Response(
        await response.transform(utf8.decoder).join(),
        response.statusCode,
      );
    } catch (e, s) {
      Logging.instance.log(
        "HTTP.post() rethrew: $e\n$s",
        level: LogLevel.Info,
      );
      rethrow;
    } finally {
      httpClient.close(force: true);
    }
  }
}
