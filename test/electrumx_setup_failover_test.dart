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
  @override
  TorConnectionStatus get status => TorConnectionStatus.disconnected;
}

Future<void> _until(bool Function() ready) async {
  final watch = Stopwatch()..start();
  while (!ready()) {
    if (watch.elapsed > const Duration(seconds: 3)) {
      throw TimeoutException('Waiting for setup test server');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  late Directory logDirectory;
  late EventBus bus;
  setUpAll(() async {
    logDirectory = await Directory.systemTemp.createTemp('electrum_setup');
    await Logging.instance.initialize(logDirectory.path, level: Level.off);
  });
  tearDownAll(() => logDirectory.delete(recursive: true));
  setUp(() => bus = EventBus());
  tearDown(() async {
    await ClientManager.sharedInstance.closeAll();
    bus.destroy();
  });

  Future<TlsElectrumServer> start({
    String? certificateName,
    bool stallHandshake = false,
    bool versionError = false,
    Set<String> ignoredMethods = const {},
  }) async {
    final server = await TlsElectrumServer.start(
      certificateName: certificateName,
      stallHandshake: stallHandshake,
      versionError: versionError,
      ignoredMethods: ignoredMethods,
    );
    addTearDown(server.close);
    return server;
  }

  ElectrumXNode node(
    TlsElectrumServer server, {
    bool useSSL = false,
    String? certificateName,
  }) => ElectrumXNode(
    address: '127.0.0.1',
    port: server.port,
    name: 'setup test',
    id: '${server.port}',
    useSSL: useSSL,
    torEnabled: true,
    clearnetEnabled: true,
    trustedCertificatePem: certificateName == null
        ? null
        : TlsElectrumServer.certificate(certificateName),
  );

  ElectrumXClient clientFor(
    int port,
    List<ElectrumXNode> failovers, {
    bool useSSL = false,
    String? certificateName,
    bool useTor = false,
    Duration timeout = const Duration(milliseconds: 200),
  }) {
    final client = ElectrumXClient(
      host: '127.0.0.1',
      port: port,
      useSSL: useSSL,
      trustedCertificatePem: certificateName == null
          ? null
          : TlsElectrumServer.certificate(certificateName),
      cryptoCurrency: Bitcoin(CryptoCurrencyNetwork.main),
      prefs: _Prefs(useTor: useTor),
      torService: _Tor(),
      netType: TorPlainNetworkOption.both,
      globalEventBusForTesting: bus,
      connectionTimeoutForSpecialCaseJsonRPCClients: timeout,
      failovers: failovers,
    );
    addTearDown(client.closeAdapter);
    return client;
  }

  for (final caller in ['adapter', 'request', 'batch']) {
    test('$caller reaches a failover after server.version times out', () async {
      final primary = await start(ignoredMethods: {'server.version'});
      final fallback = await start();
      final client = clientFor(primary.port, [node(fallback)]);

      switch (caller) {
        case 'adapter':
          await client.checkElectrumAdapter().timeout(
            const Duration(seconds: 3),
          );
        case 'request':
          expect(
            await client
                .request(command: 'probe')
                .timeout(const Duration(seconds: 3)),
            isEmpty,
          );
        case 'batch':
          expect(
            await client
                .batchRequest(
                  command: 'probe',
                  args: [<dynamic>[], <dynamic>[]],
                )
                .timeout(const Duration(seconds: 3)),
            [<String, dynamic>{}, <String, dynamic>{}],
          );
      }
      expect(client.getElectrumAdapter()!.port, fallback.port);
      expect(primary.methods, ['server.version']);
      expect(primary.accepted, 1);
      expect(fallback.accepted, 1);
      await _until(() => primary.disconnections == 1);
    });
  }

  test('a refused TCP connection reaches a healthy failover', () async {
    final unused = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final refusedPort = unused.port;
    await unused.close();
    final fallback = await start();
    final client = clientFor(refusedPort, [node(fallback)]);

    await client.checkElectrumAdapter().timeout(const Duration(seconds: 3));

    expect(client.getElectrumAdapter()!.port, fallback.port);
    expect(fallback.accepted, 1);
  });

  test('a server.version RPC rejection reaches a healthy failover', () async {
    final primary = await start(versionError: true);
    final fallback = await start();
    final client = clientFor(primary.port, [node(fallback)]);

    await client.checkElectrumAdapter().timeout(const Duration(seconds: 3));

    expect(client.getElectrumAdapter()!.port, fallback.port);
    expect(primary.methods, ['server.version']);
    expect(primary.accepted, 1);
    expect(fallback.accepted, 1);
    await _until(() => primary.disconnections == 1);
  });

  test('TLS setup failovers require each endpoint own approval', () async {
    final primary = await start(
      certificateName: 'node_a',
      stallHandshake: true,
    );
    final unapproved = await start(certificateName: 'node_a');
    final approved = await start(certificateName: 'node_b');
    final client = clientFor(
      primary.port,
      [
        node(unapproved, useSSL: true),
        node(approved, useSSL: true, certificateName: 'node_b'),
      ],
      useSSL: true,
      certificateName: 'node_a',
    );

    await client.checkElectrumAdapter().timeout(const Duration(seconds: 3));

    expect(client.getElectrumAdapter()!.port, approved.port);
    expect(primary.accepted, 1);
    expect(primary.requests, 0);
    expect(unapproved.accepted, 1);
    expect(unapproved.requests, 0);
    expect(approved.accepted, 1);
    expect(
      ClientManager.sharedInstance.trustedCertificateFor(client.cryptoCurrency),
      TlsElectrumServer.certificate('node_b'),
    );
    await _until(() => primary.disconnections == 1);
  });

  test(
    'setup exhaustion tries each remaining endpoint once and resets selection',
    () async {
      final primary = await start(ignoredMethods: {'server.version'});
      final first = await start(ignoredMethods: {'server.version'});
      final last = await start(ignoredMethods: {'server.version'});
      final client = clientFor(primary.port, [node(first), node(last)]);
      client.currentFailoverIndex = 0;

      await expectLater(
        client.checkElectrumAdapter().timeout(const Duration(seconds: 3)),
        throwsA(isA<TimeoutException>()),
      );

      expect(primary.accepted, 0);
      expect(first.accepted, 1);
      expect(last.accepted, 1);
      expect(client.getElectrumAdapter(), isNull);
      expect(client.currentFailoverIndex, -1);
      await _until(() => first.disconnections == 1 && last.disconnections == 1);

      // A later independent setup operation starts again from the primary.
      await expectLater(
        client.checkElectrumAdapter().timeout(const Duration(seconds: 3)),
        throwsA(isA<TimeoutException>()),
      );
      expect(primary.accepted, 1);
      expect(first.accepted, 2);
      expect(last.accepted, 2);
    },
  );

  test('concurrent setup callers share the successful fallback', () async {
    final primary = await start(ignoredMethods: {'server.version'});
    final fallback = await start();
    final client = clientFor(primary.port, [node(fallback)]);

    await Future.wait([
      client.checkElectrumAdapter(),
      client.checkElectrumAdapter(),
    ]).timeout(const Duration(seconds: 3));

    expect(client.getElectrumAdapter()!.port, fallback.port);
    expect(primary.accepted, 1);
    expect(fallback.accepted, 1);
  });

  test(
    'closing during negotiation cancels setup without trying failovers',
    () async {
      final primary = await start(ignoredMethods: {'server.version'});
      final fallback = await start();
      final client = clientFor(primary.port, [
        node(fallback),
      ], timeout: const Duration(seconds: 2));
      final result = client.checkElectrumAdapter().then<Object?>(
        (_) => null,
        onError: (Object error) => error,
      );
      await _until(() => primary.methods.contains('server.version'));

      await client.closeAdapter();

      expect(
        await result.timeout(const Duration(seconds: 3)),
        isA<StateError>(),
      );
      expect(client.getElectrumAdapter(), isNull);
      expect(fallback.accepted, 0);
      await _until(() => primary.disconnections == 1);
    },
  );

  test('Tor kill switch prevents all setup attempts', () async {
    final primary = await start();
    final fallback = await start();
    final client = clientFor(primary.port, [node(fallback)], useTor: true);

    await expectLater(
      client.checkElectrumAdapter(),
      throwsA(isA<StateError>()),
    );

    expect(primary.accepted, 0);
    expect(fallback.accepted, 0);
  });
}
