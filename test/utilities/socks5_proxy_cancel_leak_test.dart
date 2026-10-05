import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:socks5_proxy/exceptions.dart';
import 'package:stackwallet/utilities/socks5_proxy_cancel_leak.dart';

void main() {
  final socksTrace = StackTrace.fromString(
    '#0  SocksSocket.initialize (package:socks5_proxy/src/client/socks_client.dart:93:7)\n'
    '#1  SocksTCPClient.assignToHttpClientWithSecureOptions.<fn>.<fn> '
    '(package:socks5_proxy/src/client/socks_tcp_client.dart:57:24)\n',
  );
  final otherTrace = StackTrace.fromString(
    '#0  _SecureFilterImpl.handshake (dart:io-patch/secure_socket_patch.dart:1:1)\n',
  );

  test('swallows socks5_proxy client exceptions', () {
    expect(
      handleSocks5ProxyCancelLeak(
        const SocksClientConnectionClosedException(),
        socksTrace,
      ),
      isTrue,
    );
  });

  test('swallows a TLS handshake failure raised through socks5_proxy', () {
    expect(
      handleSocks5ProxyCancelLeak(
        const HandshakeException('Connection terminated during handshake'),
        socksTrace,
      ),
      isTrue,
    );
  });

  test('leaves a TLS handshake failure from elsewhere alone', () {
    expect(
      handleSocks5ProxyCancelLeak(
        const HandshakeException('Connection terminated during handshake'),
        otherTrace,
      ),
      isFalse,
    );
  });

  test('leaves unrelated errors alone', () {
    expect(
      handleSocks5ProxyCancelLeak(StateError('nope'), socksTrace),
      isFalse,
    );
  });
}
