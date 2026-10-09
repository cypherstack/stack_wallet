import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/test_monero_node_connection.dart';

/// A SOCKS5 proxy that hands each tunnel to [onTunnel] after the CONNECT reply.
Future<ServerSocket> _proxy(
  Future<void> Function(Socket peer, Stream<List<int>> request) onTunnel,
) async {
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  addTearDown(server.close);
  server.listen((peer) {
    addTearDown(peer.destroy);
    final buffer = <int>[];
    final request = StreamController<List<int>>();
    var tunnel = false;
    peer.listen(
      (bytes) {
        if (tunnel) {
          request.add(bytes);
          return;
        }
        buffer.addAll(bytes);
        if (buffer.length == 3) {
          peer.add([5, 0]);
        } else if (buffer.length > 8 && buffer.length == 10 + buffer[7]) {
          tunnel = true;
          peer.add([5, 0, 0, 1, 0, 0, 0, 0, 0, 0]);
          unawaited(onTunnel(peer, request.stream));
        }
      },
      onError: (Object _) {},
      onDone: request.close,
    );
  });
  return server;
}

Future<MoneroNodeConnectionResponse> _check(ServerSocket proxy) =>
    testMoneroNodeConnection(
      Uri.parse("http://node.onion:18081/json_rpc"),
      null,
      null,
      false,
      proxyInfo: (host: InternetAddress.loopbackIPv4, port: proxy.port),
    );

void main() {
  test("onion check reads a body sent after the headers", () async {
    const body = '{"jsonrpc":"2.0","id":"0","result":{"status":"OK"}}';
    final proxy = await _proxy((peer, request) async {
      await request.first;
      peer.add(
        utf8.encode(
          "HTTP/1.1 200 Ok\r\n"
          "Content-Type: application/json\r\n"
          "Content-Length: ${body.length}\r\n\r\n",
        ),
      );
      await peer.flush();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      peer.add(utf8.encode(body));
      await peer.flush();
    });

    expect((await _check(proxy)).success, isTrue);
  });

  test("onion check reports a reset connection as a failure", () async {
    final proxy = await _proxy((peer, request) async {
      await peer.flush();
      // Linux SO_LINGER {on=1, seconds=0} requests a TCP reset on close.
      peer.setRawOption(
        RawSocketOption(
          1,
          13,
          Uint8List.view(Int32List.fromList([1, 0]).buffer),
        ),
      );
      peer.destroy();
    });

    expect((await _check(proxy)).success, isFalse);
  }, testOn: "linux");
}
