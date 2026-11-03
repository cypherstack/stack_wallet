import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/services/tor_service.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/wallets/wallet/impl/ethereum_wallet.dart';

class _MockPrefs extends Mock implements Prefs {
  _MockPrefs(this.useTor);

  @override
  bool useTor;
}

class _FakeTorService extends Fake implements TorService {
  _FakeTorService(this.proxyInfo);

  final ({InternetAddress host, int port}) proxyInfo;
  int proxyInfoReads = 0;

  @override
  ({InternetAddress host, int port}) getProxyInfo() {
    proxyInfoReads++;
    return proxyInfo;
  }
}

const _rpcBody = '{"jsonrpc":"2.0","id":0,"result":"0x2a"}';

String _rpcHttpResponse() =>
    'HTTP/1.1 200 OK\r\n'
    'Content-Type: application/json\r\n'
    'Content-Length: ${_rpcBody.length}\r\n'
    'Connection: close\r\n\r\n'
    '$_rpcBody';

// Minimal SOCKS5 server that records the CONNECT target and answers the
// tunnelled HTTP request with a canned JSON-RPC eth_blockNumber result.
class _FakeSocksServer {
  late final ServerSocket _server;
  int connections = 0;
  int? addressType;
  String? target;
  int? port;
  final request = StringBuffer();

  int get listeningPort => _server.port;

  Future<void> start() async {
    _server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((socket) {
      connections++;
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
          case 2:
            request.write(utf8.decode(bytes, allowMalformed: true));
            socket.write(_rpcHttpResponse());
            socket.close();
            stage = 3;
          default:
            request.write(utf8.decode(bytes, allowMalformed: true));
        }
      });
    });
  }

  Future<void> stop() => _server.close();
}

// Local node that answers every RPC with the canned result and counts them.
class _FakeNode {
  late final HttpServer _server;
  int requests = 0;

  String get url => 'http://127.0.0.1:${_server.port}';

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((req) async {
      requests++;
      await utf8.decoder.bind(req).join();
      req.response
        ..headers.contentType = ContentType.json
        ..write(_rpcBody);
      await req.response.close();
    });
  }

  Future<void> stop() => _server.close(force: true);
}

final _torPreferenceChanged = throwsA(
  isA<StateError>().having(
    (e) => e.message,
    'message',
    contains('Tor preference changed'),
  ),
);

void main() {
  late _FakeSocksServer socks;

  setUp(() async {
    socks = _FakeSocksServer();
    await socks.start();
  });

  tearDown(() => socks.stop());

  test('web3 client sends RPC through the Tor SOCKS5 proxy', () async {
    final torService = _FakeTorService((
      host: InternetAddress.loopbackIPv4,
      port: socks.listeningPort,
    ));
    final client = EthereumWallet.createWeb3Client(
      'http://eth.example.invalid:8545',
      _MockPrefs(true),
      torService,
    );

    final height = await client.getBlockNumber();
    await client.dispose();

    expect(height, 42);
    expect(torService.proxyInfoReads, 1);
    // Hostname goes to the proxy, so there is no local DNS lookup.
    expect(socks.addressType, 0x03);
    expect(socks.target, 'eth.example.invalid');
    expect(socks.port, 8545);
    expect(socks.request.toString(), contains('eth_blockNumber'));
  });

  test('web3 client connects directly when Tor is off', () async {
    final node = _FakeNode();
    await node.start();

    final torService = _FakeTorService((
      host: InternetAddress.loopbackIPv4,
      port: socks.listeningPort,
    ));
    final client = EthereumWallet.createWeb3Client(
      node.url,
      _MockPrefs(false),
      torService,
    );

    final height = await client.getBlockNumber();
    await client.dispose();
    await node.stop();

    expect(height, 42);
    expect(node.requests, 1);
    expect(torService.proxyInfoReads, 0);
    expect(socks.target, isNull);
  });

  group('tor preference changed after the client was built', () {
    late _FakeNode node;
    late _FakeTorService torService;

    setUp(() async {
      node = _FakeNode();
      await node.start();
      torService = _FakeTorService((
        host: InternetAddress.loopbackIPv4,
        port: socks.listeningPort,
      ));
    });

    tearDown(() => node.stop());

    test('client built with Tor off refuses to send once Tor is on', () async {
      final prefs = _MockPrefs(false);
      final client = EthereumWallet.createWeb3Client(
        node.url,
        prefs,
        torService,
      );

      expect(await client.getBlockNumber(), 42);
      expect(node.requests, 1);

      prefs.useTor = true;

      await expectLater(client.getBlockNumber(), _torPreferenceChanged);
      await client.dispose();

      // Nothing went out directly and nothing was rerouted via the proxy.
      expect(node.requests, 1);
      expect(socks.connections, 0);
      expect(torService.proxyInfoReads, 0);
    });

    test('client built with Tor on refuses to send once Tor is off', () async {
      final prefs = _MockPrefs(true);
      final client = EthereumWallet.createWeb3Client(
        node.url,
        prefs,
        torService,
      );

      expect(await client.getBlockNumber(), 42);
      expect(socks.connections, 1);
      expect(socks.request.toString(), contains('eth_blockNumber'));

      prefs.useTor = false;

      await expectLater(client.getBlockNumber(), _torPreferenceChanged);
      await client.dispose();

      // No new proxy connection and nothing went to the node directly.
      expect(socks.connections, 1);
      expect(node.requests, 0);
      expect(torService.proxyInfoReads, 1);
    });

    test('unchanged preference keeps a reused client working', () async {
      final direct = EthereumWallet.createWeb3Client(
        node.url,
        _MockPrefs(false),
        torService,
      );
      expect(await direct.getBlockNumber(), 42);
      expect(await direct.getBlockNumber(), 42);
      await direct.dispose();
      expect(node.requests, 2);
      expect(socks.connections, 0);

      final proxied = EthereumWallet.createWeb3Client(
        node.url,
        _MockPrefs(true),
        torService,
      );
      expect(await proxied.getBlockNumber(), 42);
      expect(await proxied.getBlockNumber(), 42);
      await proxied.dispose();
      expect(node.requests, 2);
      expect(socks.connections, 2);
    });
  });
}
