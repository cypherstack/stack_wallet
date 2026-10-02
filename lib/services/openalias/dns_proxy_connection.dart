import 'dart:async';
import 'dart:io';

import 'package:async/async.dart';

import 'dns_proxy_socket.dart';

class DnsProxyConnection {
  static const proxyConnectTimeout = Duration(seconds: 5);

  RawSocket? _transport;
  DnsProxySocket? _socket;
  final _result = Completer<Socket>();
  bool _cancelled = false;
  Future<Socket> get socket => _result.future;

  DnsProxyConnection(
    InternetAddress proxyHost,
    int proxyPort, {
    SecurityContext? context,
  }) {
    unawaited(
      _connect(proxyHost, proxyPort, context).then(
        (socket) {
          if (_cancelled) {
            socket.destroy();
          } else if (!_result.isCompleted) {
            _result.complete(socket);
          }
        },
        onError: (Object error, StackTrace stack) {
          if (!_result.isCompleted) _result.completeError(error, stack);
          cancel();
        },
      ),
    );
  }

  Future<Socket> _connect(
    InternetAddress host,
    int port,
    SecurityContext? context,
  ) async {
    try {
      final raw = await RawSocket.connect(
        host,
        port,
        timeout: proxyConnectTimeout,
      );
      _transport = raw;
      if (_cancelled) throw const SocketException('DNS connection cancelled');
      final transport = _socket = DnsProxySocket(raw);
      final reader = ChunkedStreamReader<int>(transport);
      Future<List<int>> read(int count) async {
        final bytes = await reader.readBytes(count);
        if (bytes.length != count) {
          throw const SocketException('Incomplete SOCKS response');
        }
        return bytes;
      }

      transport.add([5, 1, 0]);
      final greeting = await read(2);
      if (greeting[0] != 5 || greeting[1] != 0) {
        throw const SocketException('SOCKS authentication failed');
      }
      transport.add([5, 1, 0, 1, 8, 8, 8, 8, 1, 187]); // CONNECT 8.8.8.8:443.
      final reply = await read(4);
      if (reply[0] != 5 || reply[1] != 0 || reply[2] != 0) {
        throw const SocketException('SOCKS connection failed');
      }
      switch (reply[3]) {
        case 1:
          await read(4);
        case 4:
          await read(16);
        case 3:
          await read((await read(1)).single);
        default:
          throw const SocketException('Invalid SOCKS address type');
      }
      await read(2);
      final subscription = await transport.detachForTls();
      await reader.cancel();
      if (_cancelled) throw const SocketException('DNS connection cancelled');
      final secured = await RawSecureSocket.secure(
        raw,
        subscription: subscription,
        host: 'dns.google',
        context: context,
      );
      _socket = DnsProxySocket.secure(secured);
      if (_cancelled) throw const SocketException('DNS connection cancelled');
      return _socket!;
    } catch (_) {
      _socket?.destroy();
      final transport = _transport;
      if (transport != null) unawaited(transport.close());
      rethrow;
    }
  }

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    if (!_result.isCompleted) {
      _result.completeError(const SocketException('DNS connection cancelled'));
    }
    _socket?.destroy();
    // This raw socket remains valid even while TLS owns its subscription.
    final transport = _transport;
    if (transport != null) unawaited(transport.close());
  }
}
