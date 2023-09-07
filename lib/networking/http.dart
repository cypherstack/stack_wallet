import 'dart:convert';
import 'dart:io';

import 'package:socks5_proxy/socks_client.dart';
import 'package:stackwallet/networking/tor_service.dart';
import 'package:stackwallet/utilities/logger.dart';

// WIP wrapper layer

abstract class HTTP {
  static Future<HttpClientResponse> get({
    required Uri url,
    Map<String, String>? headers,
    required bool routeOverTor,
  }) async {
    final httpClient = HttpClient();
    try {
      if (routeOverTor) {
        SocksTCPClient.assignToHttpClient(httpClient, [
          ProxySettings(
            TorService.sharedInstance.proxyInfo.host,
            TorService.sharedInstance.proxyInfo.port,
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

      return request.close();
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

  static Future<HttpClientResponse> post({
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
            TorService.sharedInstance.proxyInfo.host,
            TorService.sharedInstance.proxyInfo.port,
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

      return request.close();
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
