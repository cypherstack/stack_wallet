import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// FIRO fee box:
// 346493beb1be3f439c64f71f98c07f7c6707c1f02e8f9505c2366e1f57c67655
const rosenFeeRegisters = <String, dynamic>{
  'R4': {
    'serializedValue':
        '1a060762696e616e63650d626974636f696e2d72756e65730763617264616e6f'
        '046572676f08657468657265756d046669726f',
  },
  'R5': {
    'serializedValue':
        '1c02069eee8d70c4d175ce869a0db2d8e201f8abcf1894bfa60106d6f2fd72b'
        'af575fc9aa20dd687e401a08ddd18d4cfa701',
  },
  'R6': {
    'serializedValue':
        '1d0206cedfebcf0acedfebcf0acedfebcf0acedfebcf0acedfebcf0acedfebcf0a'
        '06a28398b508a28398b508a28398b508a28398b508a28398b508a28398b508',
  },
  'R7': {
    'serializedValue':
        '1d0206b4faee01a4f1dc4ae8e2f976dc9db807ac80bb07c88b3d06d2e9cb01'
        'dae9e35fe8f6945fe0e1ce05e2a5b101c88b3d',
  },
  'R8': {
    'serializedValue':
        '0c1d020602fc826280a8d6b90702fc826280a8d6b90702fc826280a8d6b907'
        '02fc826280a8d6b90702fc826280a8d6b90702fc826280a8d6b907'
        '0602a2f80c8084af5f02a2f80c8084af5f02a2f80c8084af5f'
        '02a2f80c8084af5f02a2f80c8084af5f02a2f80c8084af5f',
  },
  'R9': {'serializedValue': '1d020664646464646406646464646464'},
};

Map<String, dynamic> rosenFeeBox() => {
  'mainChain': true,
  'spentTransactionId': null,
  'assets': [
    {
      'tokenId':
          'e2ed4d64393222db666f20e67803e9e6fbe6d64531e14ff52ddd95615b0cbf17',
    },
    {
      'tokenId':
          '581d7df25808881b2b8b9b4e03e2f637c46a94f74a69a5da36434125bacb4e08',
    },
  ],
  'additionalRegisters': rosenFeeRegisters,
};

// Exercise the real HTTP wrapper without replacing production singletons or
// opening sockets. Unimplemented HTTP operations fail through Fake.
class RosenTestHttp extends HttpOverrides {
  RosenTestHttp(this.respond, {this.statusCode = 200});

  final FutureOr<Object?> Function(Uri) respond;
  final int statusCode;
  final requests = <Uri>[];

  Future<T> run<T>(Future<T> Function() action) =>
      HttpOverrides.runZoned(action, createHttpClient: createHttpClient);

  @override
  HttpClient createHttpClient(SecurityContext? context) => _Client(this);
}

class _Client extends Fake implements HttpClient {
  _Client(this.http);
  final RosenTestHttp http;

  @override
  set connectionTimeout(Duration? timeout) {}
  @override
  void close({bool force = false}) {}
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    http.requests.add(url);
    return _Request(http, url);
  }
}

class _Request extends Fake implements HttpClientRequest {
  _Request(this.http, this.url);
  final RosenTestHttp http;
  final Uri url;

  @override
  final HttpHeaders headers = _Headers();
  @override
  Future<HttpClientResponse> close() async =>
      _Response(jsonEncode(await http.respond(url)), http.statusCode);
}

class _Response extends Fake implements HttpClientResponse {
  _Response(this.body, this.statusCode);
  final String body;
  @override
  final int statusCode;
  @override
  final HttpHeaders headers = _Headers();
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(utf8.encode(body)).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
}

class _Headers extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void forEach(void Function(String, List<String>) action) {}
}
