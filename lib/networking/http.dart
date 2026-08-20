import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:socks5_proxy/socks_client.dart';

import '../utilities/logger.dart';

// WIP wrapper layer

// TODO expand this class
class Response {
  final int code;
  final List<int> bodyBytes;

  // Lower-cased response header names mapped to their (comma-joined) values.
  // Empty by default so existing callers/tests don't need to supply them.
  final Map<String, String> headers;

  String get body => utf8.decode(bodyBytes, allowMalformed: true);

  Response(this.bodyBytes, this.code, {this.headers = const {}});
}

Map<String, String> _headerMap(HttpClientResponse response) {
  final map = <String, String>{};
  response.headers.forEach((name, values) {
    map[name.toLowerCase()] = values.join(', ');
  });
  return map;
}

class HTTP {
  const HTTP();

  Future<Response> get({
    required Uri url,
    Map<String, String>? headers,
    required ({InternetAddress host, int port})? proxyInfo,
    Duration? connectionTimeout,
  }) async {
    final httpClient = HttpClient();
    if (connectionTimeout != null) {
      httpClient.connectionTimeout = connectionTimeout;
    }
    try {
      if (proxyInfo != null) {
        SocksTCPClient.assignToHttpClient(httpClient, [
          ProxySettings(proxyInfo.host, proxyInfo.port),
        ]);
      }
      final HttpClientRequest request = await httpClient.getUrl(url);

      if (headers != null) {
        headers.forEach((key, value) => request.headers.add(key, value));
      }

      final response = await request.close();

      return Response(
        await _bodyBytes(response),
        response.statusCode,
        headers: _headerMap(response),
      );
    } catch (e, s) {
      Logging.instance.w("HTTP.get() rethrew: ", error: e, stackTrace: s);
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
    required ({InternetAddress host, int port})? proxyInfo,
  }) async {
    final httpClient = HttpClient();
    try {
      if (proxyInfo != null) {
        SocksTCPClient.assignToHttpClient(httpClient, [
          ProxySettings(proxyInfo.host, proxyInfo.port),
        ]);
      }
      final HttpClientRequest request = await httpClient.postUrl(url);

      if (headers != null) {
        headers.forEach((key, value) => request.headers.add(key, value));
      }

      request.write(body);

      final response = await request.close();
      return Response(
        await _bodyBytes(response),
        response.statusCode,
        headers: _headerMap(response),
      );
    } catch (e, s) {
      Logging.instance.w("HTTP.post() rethrew: ", error: e, stackTrace: s);
      rethrow;
    } finally {
      httpClient.close(force: true);
    }
  }

  /// POST a raw byte body (e.g. an encoded multipart/form-data payload).
  Future<Response> postBytes({
    required Uri url,
    Map<String, String>? headers,
    required List<int> bodyBytes,
    required ({InternetAddress host, int port})? proxyInfo,
  }) async {
    final httpClient = HttpClient();
    try {
      if (proxyInfo != null) {
        SocksTCPClient.assignToHttpClient(httpClient, [
          ProxySettings(proxyInfo.host, proxyInfo.port),
        ]);
      }
      final HttpClientRequest request = await httpClient.postUrl(url);

      if (headers != null) {
        headers.forEach((key, value) => request.headers.add(key, value));
      }

      request.contentLength = bodyBytes.length;
      request.add(bodyBytes);

      final response = await request.close();
      return Response(
        await _bodyBytes(response),
        response.statusCode,
        headers: _headerMap(response),
      );
    } catch (e, s) {
      Logging.instance.w("HTTP.postBytes() rethrew: ", error: e, stackTrace: s);
      rethrow;
    } finally {
      httpClient.close(force: true);
    }
  }

  Future<Response> put({
    required Uri url,
    Map<String, String>? headers,
    Object? body,
    required ({InternetAddress host, int port})? proxyInfo,
  }) async {
    final httpClient = HttpClient();
    try {
      if (proxyInfo != null) {
        SocksTCPClient.assignToHttpClient(httpClient, [
          ProxySettings(proxyInfo.host, proxyInfo.port),
        ]);
      }
      final HttpClientRequest request = await httpClient.putUrl(url);

      if (headers != null) {
        headers.forEach((key, value) => request.headers.add(key, value));
      }

      if (body != null) request.write(body);

      final response = await request.close();
      return Response(
        await _bodyBytes(response),
        response.statusCode,
        headers: _headerMap(response),
      );
    } catch (e, s) {
      Logging.instance.w("HTTP.put() rethrew: ", error: e, stackTrace: s);
      rethrow;
    } finally {
      httpClient.close(force: true);
    }
  }

  Future<Response> patch({
    required Uri url,
    Map<String, String>? headers,
    Object? body,
    required ({InternetAddress host, int port})? proxyInfo,
  }) async {
    final httpClient = HttpClient();
    try {
      if (proxyInfo != null) {
        SocksTCPClient.assignToHttpClient(httpClient, [
          ProxySettings(proxyInfo.host, proxyInfo.port),
        ]);
      }
      final HttpClientRequest request = await httpClient.patchUrl(url);

      if (headers != null) {
        headers.forEach((key, value) => request.headers.add(key, value));
      }

      request.write(body);

      final response = await request.close();
      return Response(
        await _bodyBytes(response),
        response.statusCode,
        headers: _headerMap(response),
      );
    } catch (e, s) {
      Logging.instance.w("HTTP.patch() rethrew: ", error: e, stackTrace: s);
      rethrow;
    } finally {
      httpClient.close(force: true);
    }
  }

  Future<Response> delete({
    required Uri url,
    Map<String, String>? headers,
    required ({InternetAddress host, int port})? proxyInfo,
  }) async {
    final httpClient = HttpClient();
    try {
      if (proxyInfo != null) {
        SocksTCPClient.assignToHttpClient(httpClient, [
          ProxySettings(proxyInfo.host, proxyInfo.port),
        ]);
      }
      final HttpClientRequest request = await httpClient.deleteUrl(url);

      if (headers != null) {
        headers.forEach((key, value) => request.headers.add(key, value));
      }

      final response = await request.close();
      return Response(
        await _bodyBytes(response),
        response.statusCode,
        headers: _headerMap(response),
      );
    } catch (e, s) {
      Logging.instance.w("HTTP.delete() rethrew: ", error: e, stackTrace: s);
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
      onDone: () => completer.complete(Uint8List.fromList(bytes)),
      onError: (Object err, StackTrace s) {
        Logging.instance.e(
          "Http wrapper layer listen",
          error: err,
          stackTrace: s,
        );
        if (!completer.isCompleted) {
          completer.completeError(err, s);
        }
      },
      cancelOnError: true,
    );
    return completer.future;
  }
}
