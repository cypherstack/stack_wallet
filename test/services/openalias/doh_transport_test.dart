import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/services/openalias/dns_proxy_connection.dart';
import 'package:stackwallet/services/openalias/doh_open_alias.dart';
import 'package:stackwallet/services/openalias/open_alias.dart';

void main() {
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
