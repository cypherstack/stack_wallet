import 'dart:async';
import 'dart:io';

import 'package:cs_openalias/cs_openalias.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/services/openalias/open_alias_service.dart';

void main() {
  test(
    'Flutter loads the facade native validator and queries through Tor',
    () async {
      // A local stand-in for Tor: the first connection proves the native
      // validator started and sent a query; the lookup is then cancelled.
      final proxy = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(proxy.close);
      final connected = Completer<void>();
      proxy.listen((socket) {
        if (!connected.isCompleted) connected.complete();
        socket.destroy();
      });
      final operation = OpenAliasService(
        externalCalls: () => true,
        useTor: () => true,
        supportsTor: () => true,
        torProxy: () => (host: InternetAddress.loopbackIPv4, port: proxy.port),
      ).lookup('alice.example', isValidAddress: (_) => true);
      await connected.future.timeout(const Duration(seconds: 10));
      operation.cancel();
      await expectLater(
        operation.result,
        throwsA(isA<CsOpenAliasCancelledException>()),
      );
    },
  );
}
