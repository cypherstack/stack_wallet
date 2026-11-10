import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/networking/http.dart';

// Minimal SOCKS5 server that records the CONNECT target and answers any
// request with a canned HTTP 200.
class _FakeSocksServer {
  late final ServerSocket _server;
  int? addressType;
  String? target;
  int? port;

  int get listeningPort => _server.port;

  Future<void> start() async {
    _server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((socket) {
      var stage = 0;
      socket.listen((Uint8List bytes) {
        switch (stage) {
          case 0:
            socket.add([0x05, 0x00]);
            stage = 1;
          case 1:
            addressType = bytes[3];
            if (addressType == 0x03) {
              target = String.fromCharCodes(bytes.sublist(5, 5 + bytes[4]));
            } else {
              target = bytes.sublist(4, bytes.length - 2).join('.');
            }
            port = (bytes[bytes.length - 2] << 8) | bytes[bytes.length - 1];
            socket.add([0x05, 0x00, 0x00, 0x01, 0, 0, 0, 0, 0, 0]);
            stage = 2;
          default:
            socket.write(
              'HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nok',
            );
            socket.close();
        }
      });
    });
  }

  Future<void> stop() => _server.close();
}

void main() {
  late _FakeSocksServer socks;

  setUp(() async {
    socks = _FakeSocksServer();
    await socks.start();
  });

  tearDown(() => socks.stop());

  Future<Response> get(String host) => const HTTP().get(
    url: Uri.http(host, '/'),
    proxyInfo: (host: InternetAddress.loopbackIPv4, port: socks.listeningPort),
  );

  test('proxied request sends the hostname to the SOCKS5 proxy', () async {
    final response = await get('example.invalid');

    expect(response.code, 200);
    expect(socks.addressType, 0x03);
    expect(socks.target, 'example.invalid');
    expect(socks.port, 80);
  });

  test('proxied request can target an onion address', () async {
    const onion =
        'trocadorfyhlu27aefre5u7zri66gudtzdyelymftvr4yjwcxhfaqsid.onion';
    final response = await get(onion);

    expect(response.code, 200);
    expect(socks.addressType, 0x03);
    expect(socks.target, onion);
  });
}
