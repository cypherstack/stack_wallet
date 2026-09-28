import 'dart:io';

import 'package:async/async.dart';

// socks5_proxy resolves hostnames locally before CONNECT, so tunnel to the
// numeric endpoint instead.
class DnsProxyConnection {
  Socket? _transport;
  bool _cancelled = false;
  late final Future<Socket> socket;

  DnsProxyConnection(InternetAddress proxyHost, int proxyPort) {
    socket = _connect(proxyHost, proxyPort);
  }

  Future<Socket> _connect(InternetAddress host, int port) async {
    try {
      final raw = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 5),
      );
      _transport = raw;
      if (_cancelled) throw const SocketException('DNS connection cancelled');
      // SecureSocket.secure takes over this reader's subscription.
      final reader = ChunkedStreamReader<int>(raw);
      Future<List<int>> read(int count) async {
        final bytes = await reader.readBytes(count);
        if (bytes.length != count) {
          throw const SocketException('Incomplete SOCKS response');
        }
        return bytes;
      }

      raw.add([5, 1, 0]);
      final greeting = await read(2);
      if (greeting[0] != 5 || greeting[1] != 0) {
        throw const SocketException('SOCKS authentication failed');
      }
      raw.add([5, 1, 0, 1, 8, 8, 8, 8, 1, 187]); // CONNECT 8.8.8.8:443.
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
      final secured = await SecureSocket.secure(raw, host: 'dns.google');
      _transport = secured;
      if (_cancelled) throw const SocketException('DNS connection cancelled');
      return secured;
    } catch (_) {
      cancel();
      rethrow;
    }
  }

  void cancel() {
    _cancelled = true;
    _transport?.destroy();
  }
}
