import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:socks5_proxy/socks_client.dart';
import 'package:stackwallet/utilities/logger.dart';

// WIP wrapper layer

// TODO expand this class
class Response {
  final int code;
  final List<int> bodyBytes;

  String get body => utf8.decode(bodyBytes, allowMalformed: true);

  Response(this.bodyBytes, this.code);
}

class HTTP {
  Future<Response> get({
    required Uri url,
    Map<String, String>? headers,
    required ({
      InternetAddress host,
      int port,
    })? proxyInfo,
  }) async {
    final httpClient = HttpClient();
    try {
      if (proxyInfo != null) {
        SocksTCPClient.assignToHttpClient(httpClient, [
          ProxySettings(
            proxyInfo.host,
            proxyInfo.port,
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
        await _bodyBytes(response),
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
    required ({
      InternetAddress host,
      int port,
    })? proxyInfo,
  }) async {
    final httpClient = HttpClient();
    try {
      if (proxyInfo != null) {
        SocksTCPClient.assignToHttpClient(httpClient, [
          ProxySettings(
            proxyInfo.host,
            proxyInfo.port,
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
        await _bodyBytes(response),
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

  Future<Uint8List> _bodyBytes(HttpClientResponse response) {
    final completer = Completer<Uint8List>();
    final List<int> bytes = [];
    response.listen(
      (data) {
        bytes.addAll(data);
      },
      onDone: () => completer.complete(
        Uint8List.fromList(bytes),
      ),
    );
    return completer.future;
  }
}
