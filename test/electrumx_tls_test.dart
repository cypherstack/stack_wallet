import 'dart:async';
import 'dart:io';

import 'package:event_bus/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:logger/logger.dart' show Level;
import 'package:stackwallet/electrumx_rpc/electrumx_client.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/event_bus/events/global/tor_status_changed_event.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/services/tor_service.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/impl/bitcoin_wallet.dart';

import 'utilities/tls_test_server.dart';

class _Prefs extends Mock implements Prefs {
  @override
  bool get useTor => false;
  @override
  bool get wifiOnly => false;
  @override
  bool get torKillSwitch => false;
}

class _Tor extends Mock implements TorService {}

/// Serves one primary node and no failovers to a wallet under test.
class _Nodes extends NodeService {
  _Nodes(this.node) : super(secureStorageInterface: FakeSecureStorage());
  NodeModel node;
  @override
  NodeModel? getPrimaryNodeFor({required CryptoCurrency currency}) => node;
  @override
  List<NodeModel> failoverNodesFor({required CryptoCurrency currency}) => [];
}

void main() {
  late Directory logDirectory;
  setUpAll(() async {
    logDirectory = await Directory.systemTemp.createTemp('electrum_tls_logs');
    await Logging.instance.initialize(logDirectory.path, level: Level.off);
  });
  tearDownAll(() => logDirectory.delete(recursive: true));
  final coin = Bitcoin(CryptoCurrencyNetwork.main);
  final servers = <TlsElectrumServer>[];
  late EventBus bus;
  final prefs = _Prefs();

  final clients = <ElectrumXClient>[];
  setUp(() => bus = EventBus());
  tearDown(() async {
    for (final client in clients) {
      await client.closeAdapter();
    }
    clients.clear();
    bus.destroy();
    for (final server in servers) {
      await server.close();
    }
    servers.clear();
  });

  Future<TlsElectrumServer> start(String certificateName) async {
    final server = await TlsElectrumServer.start(
      certificateName: certificateName,
    );
    servers.add(server);
    return server;
  }

  ElectrumXNode node(TlsElectrumServer server, {String? certificateName}) =>
      ElectrumXNode(
        address: '127.0.0.1',
        port: server.port,
        name: 'TLS node',
        id: '${server.port}',
        useSSL: true,
        torEnabled: true,
        clearnetEnabled: true,
        trustedCertificatePem: certificateName == null
            ? null
            : TlsElectrumServer.certificate(certificateName),
      );

  ElectrumXClient client(
    ElectrumXNode node, {
    List<ElectrumXNode> failovers = const [],
  }) {
    final client = ElectrumXClient.from(
      node: node,
      prefs: prefs,
      torService: _Tor(),
      failovers: failovers,
      cryptoCurrency: coin,
      globalEventBusForTesting: bus,
    );
    clients.add(client);
    return client;
  }

  test('live client connects using the approved primary certificate', () async {
    final server = await start('node_a');
    final primary = node(server, certificateName: 'node_a');
    expect(
      ElectrumXNode.from(primary).trustedCertificatePem,
      primary.trustedCertificatePem,
    );
    final connection = client(primary);
    await connection.checkElectrumAdapter();
    final result = await connection.getTransaction(txHash: 'a' * 64);
    expect(result['confirmations'], 3);
    expect(connection.trustedCertificatePem, primary.trustedCertificatePem);
  });

  test('live client rejects an unapproved primary certificate', () async {
    final server = await start('node_a');
    await expectLater(
      client(node(server)).checkElectrumAdapter(),
      throwsA(isA<HandshakeException>()),
    );
    expect(server.requests, 0);
  });

  test('failover uses its own approved certificate', () async {
    final primary = await start('node_a');
    final failover = await start('node_b');
    final connection = client(
      node(primary, certificateName: 'node_a'),
      failovers: [node(failover, certificateName: 'node_b')],
    );
    connection.currentFailoverIndex = 0;
    await connection.checkElectrumAdapter();
    await connection.getElectrumAdapter()!.request('server.version');
    expect(connection.getElectrumAdapter()!.port, failover.port);
  });

  test('primary approval is not inherited by an unapproved failover', () async {
    final primary = await start('node_a');
    final failover = await start('node_b');
    final connection = client(
      node(primary, certificateName: 'node_a'),
      failovers: [node(failover)],
    );
    connection.currentFailoverIndex = 0;
    await expectLater(
      connection.checkElectrumAdapter(),
      throwsA(isA<HandshakeException>()),
    );
    expect(failover.requests, 0);
  });

  test('a client with the same approval opens its own connection', () async {
    final server = await start('node_a');
    final first = client(node(server, certificateName: 'node_a'));
    await first.checkElectrumAdapter();
    final second = client(node(server, certificateName: 'node_a'));
    await second.checkElectrumAdapter();
    expect(
      second.getElectrumAdapter(),
      isNot(same(first.getElectrumAdapter())),
    );
    expect(server.accepted, 2);
    expect(server.disconnections, 0);
  });

  test('a revoked client never reuses a trusted connection', () async {
    final server = await start('node_a');
    final trusted = client(node(server, certificateName: 'node_a'));
    await trusted.checkElectrumAdapter();
    final peer = trusted.getElectrumAdapter()!.peer;
    final revoked = client(node(server));
    await expectLater(
      revoked.checkElectrumAdapter(),
      throwsA(isA<HandshakeException>()),
    );
    expect(revoked.getElectrumAdapter(), null);
    // The trusted connection belongs to its own client. A revocation reaches
    // it through that client being replaced, as updateNode() does.
    expect(peer.isClosed, false);
    await trusted.closeAdapter();
    expect(peer.isClosed, true);
  });

  test(
    'updateNode closes the wallet connection a revocation replaces',
    () async {
      final server = await start('node_a');
      NodeModel nodeModel({String? pem}) => NodeModel(
        host: '127.0.0.1',
        port: server.port,
        name: 'TLS node',
        id: 'tls-node',
        useSSL: true,
        enabled: true,
        coinName: 'bitcoin',
        isFailover: false,
        isDown: false,
        trusted: false,
        torEnabled: true,
        clearnetEnabled: true,
        isPrimary: true,
        trustedCertificatePem: pem,
      );
      final nodes = _Nodes(
        nodeModel(pem: TlsElectrumServer.certificate('node_a')),
      );
      final wallet = BitcoinWallet<Bitcoin>(CryptoCurrencyNetwork.main)
        ..prefs = prefs
        ..nodeService = nodes;
      // Wallet.load() calls this before the wallet has any client to close.
      await wallet.updateNode();
      final trusted = wallet.electrumXClient;
      clients.add(trusted);
      await trusted.request(command: 'server.version');
      final peer = trusted.getElectrumAdapter()!.peer;

      nodes.node = nodeModel();
      await wallet.updateNode();
      clients.add(wallet.electrumXClient);
      expect(peer.isClosed, true);
      await expectLater(
        wallet.electrumXClient.request(command: 'server.version'),
        throwsA(isA<HandshakeException>()),
      );
    },
  );

  for (final action in ['Tor change', 'close owner']) {
    test('$action also closes a connection draining after failover', () async {
      final primary = await TlsElectrumServer.start(
        ignoredMethods: {'blockchain.transaction.get'},
      );
      servers.add(primary);
      final fallback = await start('node_b');
      final fallbackNode = node(fallback, certificateName: 'node_b');
      final connection = client(
        node(primary, certificateName: 'node_a'),
        failovers: [fallbackNode],
      );
      await connection.checkElectrumAdapter();
      final previous = connection.getElectrumAdapter()!;
      final pending = connection
          .getTransaction(txHash: 'a' * 64)
          .then<Object?>((value) => value, onError: (Object e) => e);
      await _until(
        () => primary.methods.contains('blockchain.transaction.get'),
      );
      connection.currentFailoverIndex = 0;
      await connection.checkElectrumAdapter();
      expect(connection.getElectrumAdapter()!.port, fallback.port);
      expect(previous.peer.isClosed, false);

      switch (action) {
        case 'Tor change':
          bus.fire(TorPreferenceChangedEvent(status: TorStatus.enabled));
        case 'close owner':
          // A revocation or node change replaces the owner via updateNode().
          await connection.closeAdapter();
      }
      await _until(() => previous.peer.isClosed);
      expect(await pending, isA<StateError>());
    });
  }
}

Future<void> _until(bool Function() ready) async {
  final watch = Stopwatch()..start();
  while (!ready()) {
    if (watch.elapsed > const Duration(seconds: 3)) {
      throw TimeoutException('Waiting for TLS lifecycle');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}
