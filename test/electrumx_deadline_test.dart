import 'dart:async';
import 'dart:io';

import 'package:event_bus/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart' show Level;
import 'package:mockito/mockito.dart';
import 'package:stackwallet/electrumx_rpc/client_manager.dart';
import 'package:stackwallet/electrumx_rpc/electrumx_client.dart';
import 'package:stackwallet/services/event_bus/events/global/tor_connection_status_changed_event.dart';
import 'package:stackwallet/services/tor_service.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/utilities/tor_plain_net_option_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

import 'utilities/tls_test_server.dart';

class _Prefs extends Mock implements Prefs {
  _Prefs({this.useTor = false});
  @override
  final bool useTor;
  @override
  bool get wifiOnly => false;
  @override
  bool get torKillSwitch => true;
}

class _Tor extends Mock implements TorService {
  _Tor(this.proxy);
  final ({InternetAddress host, int port})? proxy;
  @override
  TorConnectionStatus get status => TorConnectionStatus.connected;
  @override
  ({InternetAddress host, int port}) getProxyInfo() => proxy!;
}

Future<void> _until(bool Function() ready) async {
  final watch = Stopwatch()..start();
  while (!ready()) {
    if (watch.elapsed > const Duration(seconds: 2)) {
      throw TimeoutException('Waiting for test server');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  late Directory logDirectory;
  late EventBus bus;
  setUpAll(() async {
    logDirectory = await Directory.systemTemp.createTemp('electrum_deadlines');
    await Logging.instance.initialize(logDirectory.path, level: Level.off);
  });
  tearDownAll(() => logDirectory.delete(recursive: true));
  setUp(() => bus = EventBus());
  tearDown(() async {
    await ClientManager.sharedInstance.closeAll();
    bus.destroy();
  });

  Future<TlsElectrumServer> start({
    bool stallHandshake = false,
    Set<String> ignoredMethods = const {},
  }) async {
    final server = await TlsElectrumServer.start(
      stallHandshake: stallHandshake,
      ignoredMethods: ignoredMethods,
    );
    addTearDown(server.close);
    return server;
  }

  ElectrumXClient clientFor(
    TlsElectrumServer server, {
    CryptoCurrency? coin,
    ({InternetAddress host, int port})? proxy,
    Duration connectionTimeout = const Duration(seconds: 2),
  }) {
    final client = ElectrumXClient(
      host: proxy == null ? '127.0.0.1' : 'deadline.test.onion',
      port: server.port,
      useSSL: true,
      trustedCertificatePem: TlsElectrumServer.certificate('node_a'),
      cryptoCurrency: coin ?? Bitcoin(CryptoCurrencyNetwork.main),
      prefs: _Prefs(useTor: proxy != null),
      torService: _Tor(proxy),
      netType: TorPlainNetworkOption.both,
      globalEventBusForTesting: bus,
      connectionTimeoutForSpecialCaseJsonRPCClients: connectionTimeout,
      failovers: [],
    );
    addTearDown(client.closeAdapter);
    return client;
  }

  for (final proxied in [false, true]) {
    final route = proxied ? 'SOCKS TLS' : 'direct TLS';
    for (final stallHandshake in [true, false]) {
      final phase = stallHandshake ? 'TLS handshake' : 'server.version';
      test('$route releases a stalled $phase', () async {
        final server = await start(
          stallHandshake: stallHandshake,
          ignoredMethods: {'server.version'},
        );
        final proxy = proxied ? await TlsTestProxy.start(server.port) : null;
        if (proxy != null) addTearDown(proxy.close);
        final client = clientFor(
          server,
          proxy: proxy?.info,
          connectionTimeout: const Duration(milliseconds: 200),
        );

        await expectLater(
          client.checkElectrumAdapter().timeout(const Duration(seconds: 3)),
          throwsA(isA<TimeoutException>()),
        );
        expect(client.getElectrumAdapter(), isNull);
        await _until(() => server.disconnections == 1);
        expect(server.accepted, 1);
      });
    }
  }

  for (final coin in [
    Bitcoin(CryptoCurrencyNetwork.main),
    Firo(CryptoCurrencyNetwork.main),
  ]) {
    test('${coin.runtimeType} RPC timeout closes and reconnects', () async {
      final server = await start(ignoredMethods: {'probe.silent'});
      final client = clientFor(server, coin: coin);
      await client.request(command: 'probe.ready');
      final original = client.getElectrumAdapter()!;

      await expectLater(
        client
            .request(
              command: 'probe.silent',
              requestTimeout: const Duration(milliseconds: 150),
            )
            .timeout(const Duration(seconds: 3)),
        throwsA(isA<TimeoutException>()),
      );
      expect(original.peer.isClosed, true);
      await _until(() => server.disconnections == 1);
      expect(await client.request(command: 'probe.ready'), isEmpty);
      expect(client.getElectrumAdapter(), isNot(same(original)));
      expect(server.accepted, 2);
      expect(server.methods.where((m) => m == 'probe.silent').length, 1);
    });
  }

  test(
    'batch members use the caller timeout and close a silent peer',
    () async {
      final server = await start(ignoredMethods: {'probe.silent'});
      final client = clientFor(server);
      await client.request(command: 'probe.ready');
      final original = client.getElectrumAdapter()!;

      await expectLater(
        client
            .batchRequest(
              command: 'probe.silent',
              args: [
                [1],
                [2],
              ],
              requestTimeout: const Duration(milliseconds: 150),
            )
            .timeout(const Duration(seconds: 3)),
        throwsA(isA<TimeoutException>()),
      );
      expect(original.peer.isClosed, true);
      await _until(() => server.disconnections == 1);
      expect(server.methods.where((m) => m == 'probe.silent').length, 2);
      expect(await client.request(command: 'probe.ready'), isEmpty);
    },
  );

  test('batch replies preserve the request order and arguments', () async {
    final server = await start();
    final client = clientFor(server);
    expect(
      await client.batchRequest(
        command: 'blockchain.transaction.get',
        args: [
          ['first', true],
          ['second', true],
        ],
      ),
      [
        {'txid': 'first', 'confirmations': 3},
        {'txid': 'second', 'confirmations': 3},
      ],
    );
  });

  test('an empty batch sends no requests and opens no connection', () async {
    final server = await start();
    final client = clientFor(server);
    expect(
      await client.batchRequest(command: 'probe.empty', args: []),
      isEmpty,
    );
    expect(server.accepted, 0);
  });
}
