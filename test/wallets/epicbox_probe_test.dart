import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/wallet/supporting/epicbox_probe.dart';

void main() {
  test('accepts a relay that greets with a challenge', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      socket.add('{"type":"Challenge","str":"abc"}');
    });

    expect(
      await probeEpicboxServer(Uri.parse('ws://127.0.0.1:${server.port}')),
      isTrue,
    );
  });

  test('rejects a relay that greets with something else', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      socket.add('hello');
    });

    expect(
      await probeEpicboxServer(Uri.parse('ws://127.0.0.1:${server.port}')),
      isFalse,
    );
  });

  test('fails promptly when nothing listens on the port', () async {
    final reserved = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = reserved.port;
    await reserved.close();

    await expectLater(
      probeEpicboxServer(Uri.parse('ws://127.0.0.1:$port'))
          .timeout(const Duration(seconds: 15)),
      throwsA(isNot(isA<TimeoutException>())),
    );
  });

  test('fails promptly on a TLS handshake with a plain server', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) => request.response.close());

    await expectLater(
      probeEpicboxServer(Uri.parse('wss://127.0.0.1:${server.port}'))
          .timeout(const Duration(seconds: 15)),
      throwsA(isNot(isA<TimeoutException>())),
    );
  });
}
