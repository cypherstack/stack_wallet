import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/services/openalias/dns_proxy_connection.dart';
import 'package:stackwallet/services/openalias/doh_open_alias.dart';
import 'package:stackwallet/services/openalias/open_alias.dart';

void main() {
  test(
    'immediate cancellation completes without leaving a connection',
    () async {
      final proxy = await _StalledTlsProxy.start();
      addTearDown(proxy.close);
      final task = DnsProxyConnection(
        InternetAddress.loopbackIPv4,
        proxy.server.port,
      );
      final failed = expectLater(task.socket, throwsA(isA<SocketException>()));
      task.cancel();
      await failed.timeout(const Duration(seconds: 2));
      final peer = await proxy.nextPeer();
      await peer.disconnected.future.timeout(const Duration(seconds: 2));
    },
  );

  test(
    'TLS transport carries HTTP with backpressure and cancels after success',
    () async {
      final body = List<int>.generate(256 * 1024, (index) => index % 256);
      final served = Completer<void>();
      final disconnected = Completer<void>();
      final proxy = await _TlsSocksProxy.start((socket) async {
        final reader = ChunkedStreamReader<int>(socket);
        final header = <int>[];
        while (!ascii.decode(header).endsWith('\r\n\r\n')) {
          header.addAll(await reader.readBytes(1));
        }
        expect(ascii.decode(header), contains('POST /resolve HTTP/1.1'));
        // Let the sender fill the TLS buffers before consuming its body.
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(await reader.readBytes(body.length), body);
        socket.add(
          ascii.encode(
            'HTTP/1.1 200 OK\r\nContent-Length: ${body.length}\r\n\r\n',
          ),
        );
        socket.add(body);
        await socket.flush();
        served.complete();
        expect(await reader.readBytes(1), isEmpty);
        disconnected.complete();
      });
      addTearDown(proxy.close);
      final context = SecurityContext(withTrustedRoots: false)
        ..setTrustedCertificates(_certificate);
      final task = DnsProxyConnection(
        InternetAddress.loopbackIPv4,
        proxy.server.port,
        context: context,
      );
      addTearDown(task.cancel);
      final client = HttpClient()
        ..connectionFactory = (uri, _, _) async =>
            ConnectionTask.fromSocket(task.socket, task.cancel);
      addTearDown(() => client.close(force: true));
      final request = await client.postUrl(Uri.https('dns.google', '/resolve'));
      request.contentLength = body.length;
      request.add(body);
      final response = await request.close();
      expect(response.statusCode, 200);
      expect(response.certificate, isNotNull);
      final received = <int>[];
      await for (final chunk in response) {
        received.addAll(chunk);
      }
      expect(received, body);
      await served.future.timeout(const Duration(seconds: 2));
      task.cancel();
      task.cancel();
      await disconnected.future.timeout(const Duration(seconds: 2));
      expect(proxy.errors, isEmpty);
    },
  );

  test('TLS still rejects an untrusted certificate', () async {
    final proxy = await _TlsSocksProxy.start((socket) async {
      await socket.drain<void>();
    });
    addTearDown(proxy.close);
    final task = DnsProxyConnection(
      InternetAddress.loopbackIPv4,
      proxy.server.port,
    );
    addTearDown(task.cancel);
    await expectLater(task.socket, throwsA(isA<HandshakeException>()));
  });

  test(
    'cancelling stalled TLS closes the peer and completes the task',
    () async {
      final proxy = await _StalledTlsProxy.start();
      addTearDown(proxy.close);
      for (var attempt = 0; attempt < 3; attempt++) {
        final task = DnsProxyConnection(
          InternetAddress.loopbackIPv4,
          proxy.server.port,
        );
        final failed = expectLater(
          task.socket,
          throwsA(isA<SocketException>()),
        );
        addTearDown(task.cancel);
        final peer = await proxy.nextPeer();
        await peer.clientHello.future.timeout(const Duration(seconds: 2));
        task.cancel();
        task.cancel();
        await peer.disconnected.future.timeout(const Duration(seconds: 2));
        await failed.timeout(const Duration(seconds: 2));
      }
    },
  );

  test('lookup timeout closes a stalled TLS connection', () async {
    final proxy = await _StalledTlsProxy.start();
    addTearDown(proxy.close);
    final failed = expectLater(
      DohOpenAlias().lookup(
        'alice.example',
        proxyInfo: (
          host: InternetAddress.loopbackIPv4,
          port: proxy.server.port,
        ),
      ),
      throwsA(isA<OpenAliasException>()),
    );
    final peer = await proxy.nextPeer();
    await peer.clientHello.future.timeout(const Duration(seconds: 2));
    await failed.timeout(const Duration(seconds: 8));
    await peer.disconnected.future.timeout(const Duration(seconds: 2));
  });

  test('cancelling a stalled SOCKS handshake closes the socket', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final greeted = Completer<void>();
    final disconnected = Completer<void>();
    Socket? peer;
    final sub = server.listen((socket) {
      peer = socket;
      socket.listen((_) {
        if (!greeted.isCompleted) greeted.complete();
      }, onDone: () => disconnected.complete());
    });
    final task = DnsProxyConnection(InternetAddress.loopbackIPv4, server.port);
    final failed = expectLater(task.socket, throwsA(isA<SocketException>()));
    try {
      await greeted.future.timeout(const Duration(seconds: 2));
      task.cancel();
      await failed;
      await disconnected.future.timeout(const Duration(seconds: 2));
    } finally {
      task.cancel();
      peer?.destroy();
      await sub.cancel();
      await server.close();
    }
  });

  test(
    'SOCKS connects to a numeric endpoint without resolving dns.google locally',
    () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final requested = Completer<List<int>>();
      final sockets = <Socket>[];
      final sub = server.listen((socket) {
        sockets.add(socket);
        final bytes = <int>[];
        var greeted = false;
        socket.listen((data) {
          bytes.addAll(data);
          if (!greeted && bytes.length >= 3) {
            expect(bytes.sublist(0, 3), [5, 1, 0]);
            bytes.removeRange(0, 3);
            greeted = true;
            socket.add([5, 0]);
          }
          if (greeted && bytes.length >= 10 && !requested.isCompleted) {
            requested.complete(bytes.sublist(0, 10));
            socket.add([5, 5, 0, 1, 0, 0, 0, 0, 0, 0]);
          }
        });
      });
      try {
        await expectLater(
          DohOpenAlias().lookup(
            'alice.example',
            proxyInfo: (host: InternetAddress.loopbackIPv4, port: server.port),
          ),
          throwsA(isA<OpenAliasException>()),
        );
        expect(await requested.future.timeout(const Duration(seconds: 2)), [
          5,
          1,
          0,
          1,
          8,
          8,
          8,
          8,
          1,
          187,
        ]);
      } finally {
        for (final socket in sockets) {
          socket.destroy();
        }
        await sub.cancel();
        await server.close();
      }
    },
  );
}

class _StalledTlsProxy {
  final ServerSocket server;
  final _accepted = StreamController<_StalledTlsPeer>();
  final _peers = <_StalledTlsPeer>[];
  late final StreamIterator<_StalledTlsPeer> _iterator;
  late final StreamSubscription<Socket> _subscription;

  _StalledTlsProxy(this.server) {
    _iterator = StreamIterator(_accepted.stream);
    _subscription = server.listen((socket) {
      final peer = _StalledTlsPeer(socket);
      _peers.add(peer);
      _accepted.add(peer);
    });
  }

  static Future<_StalledTlsProxy> start() async => _StalledTlsProxy(
    await ServerSocket.bind(InternetAddress.loopbackIPv4, 0),
  );

  Future<_StalledTlsPeer> nextPeer() async {
    await _iterator.moveNext().timeout(const Duration(seconds: 2));
    return _iterator.current;
  }

  Future<void> close() async {
    for (final peer in _peers) {
      peer.socket.destroy();
    }
    await _iterator.cancel();
    await _accepted.close();
    await _subscription.cancel();
    await server.close();
  }
}

class _StalledTlsPeer {
  final Socket socket;
  final clientHello = Completer<void>();
  final disconnected = Completer<void>();

  _StalledTlsPeer(this.socket) {
    final bytes = <int>[];
    var stage = 0;
    socket.listen((data) {
      bytes.addAll(data);
      if (stage == 0 && bytes.length >= 3) {
        expect(bytes.sublist(0, 3), [5, 1, 0]);
        bytes.removeRange(0, 3);
        socket.add([5, 0]);
        stage = 1;
      }
      if (stage == 1 && bytes.length >= 10) {
        expect(bytes.sublist(0, 10), [5, 1, 0, 1, 8, 8, 8, 8, 1, 187]);
        bytes.removeRange(0, 10);
        socket.add([5, 0, 0, 1, 127, 0, 0, 1, 0, 0]);
        stage = 2;
      }
      if (stage == 2 && bytes.length >= 6) {
        // TLS handshake record followed by a ClientHello message.
        expect(bytes[0], 22);
        expect(bytes[5], 1);
        clientHello.complete();
        stage = 3;
        bytes.clear();
      }
    }, onDone: disconnected.complete);
  }
}

// Test-only identity for dns.google; never added to the default trust store.
const _certificate =
    'test/services/openalias/fixtures/dns_google_test_cert.pem';
const _privateKey = 'test/services/openalias/fixtures/dns_google_test_key.pem';

class _TlsSocksProxy {
  final ServerSocket server;
  final errors = <Object>[];
  final _sockets = <Socket>[];
  final _tasks = <Future<void>>[];
  late final StreamSubscription<Socket> _subscription;

  _TlsSocksProxy(this.server, Future<void> Function(SecureSocket) handle) {
    final context = SecurityContext()
      ..useCertificateChain(_certificate)
      ..usePrivateKey(_privateKey);
    _subscription = server.listen((socket) {
      _sockets.add(socket);
      _tasks.add(
        _serve(socket, context, handle).catchError((Object error) {
          errors.add(error);
        }),
      );
    });
  }

  Future<void> _serve(
    Socket socket,
    SecurityContext context,
    Future<void> Function(SecureSocket) handle,
  ) async {
    final reader = ChunkedStreamReader<int>(socket);
    expect(await reader.readBytes(3), [5, 1, 0]);
    socket.add([5]);
    await socket.flush();
    socket.add([0]);
    expect(await reader.readBytes(10), [5, 1, 0, 1, 8, 8, 8, 8, 1, 187]);
    // A fragmented domain-form reply also exercises exact SOCKS reads.
    for (final byte in [5, 0, 0, 3, 3, 102, 111, 111, 0, 0]) {
      socket.add([byte]);
      await socket.flush();
    }
    final secure = await SecureSocket.secureServer(socket, context);
    _sockets.add(secure);
    await handle(secure);
  }

  static Future<_TlsSocksProxy> start(
    Future<void> Function(SecureSocket) handle,
  ) async => _TlsSocksProxy(
    await ServerSocket.bind(InternetAddress.loopbackIPv4, 0),
    handle,
  );

  Future<void> close() async {
    for (final socket in _sockets) {
      socket.destroy();
    }
    await _subscription.cancel();
    await server.close();
    await Future.wait(_tasks).timeout(const Duration(seconds: 2));
  }
}
