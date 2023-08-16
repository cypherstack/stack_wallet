import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/electrumx_rpc/rpc.dart';
import 'package:stackwallet/utilities/default_nodes.dart';

void main() {
  test("REQUIRES INTERNET - JsonRPC.request success", () async {
    final jsonRPC = JsonRPC(
      host: DefaultNodes.bitcoin.host,
      port: DefaultNodes.bitcoin.port,
      useSSL: true,
      connectionTimeout: const Duration(seconds: 40),
    );

    const jsonRequestString =
        '{"jsonrpc": "2.0", "id": "some id","method": "server.ping","params": []}';
    final result = await jsonRPC.request(
      jsonRequestString,
      const Duration(seconds: 1),
    );

    expect(result.data, {"jsonrpc": "2.0", "result": null, "id": "some id"});
  });

  test("JsonRPC.request fails due to SocketException", () async {
    final jsonRPC = JsonRPC(
      host: "some.bad.address.thingdsfsdfsdaf",
      port: 3000,
      connectionTimeout: Duration(seconds: 10),
    );

    const jsonRequestString =
        '{"jsonrpc": "2.0", "id": "some id","method": "server.ping","params": []}';

    expect(
        () => jsonRPC.request(
              jsonRequestString,
              const Duration(seconds: 1),
            ),
        throwsA(isA<SocketException>()));
  });

  test("JsonRPC.request fails due to connection timeout", () async {
    final jsonRPC = JsonRPC(
      host: "8.8.8.8",
      port: 3000,
      useSSL: false,
      connectionTimeout: const Duration(seconds: 1),
    );

    const jsonRequestString =
        '{"jsonrpc": "2.0", "id": "some id","method": "server.ping","params": []}';

    expect(
        () => jsonRPC.request(
              jsonRequestString,
              const Duration(seconds: 1),
            ),
        throwsA(isA<SocketException>()));
  });
}
