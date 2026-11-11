import 'dart:io';

import 'package:event_bus/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:logger/logger.dart' show Level;
import 'package:stackwallet/electrumx_rpc/client_manager.dart';
import 'package:stackwallet/electrumx_rpc/electrumx_client.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/services/node_service.dart';
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
  final NodeModel node;
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

  setUp(() => bus = EventBus());
  tearDown(() async {
    await ClientManager.sharedInstance.closeAll();
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
  }) => ElectrumXClient.from(
    node: node,
    prefs: prefs,
    torService: _Tor(),
    failovers: failovers,
    cryptoCurrency: coin,
    globalEventBusForTesting: bus,
  );

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

  test('a client with the same approval shares the connection', () async {
    final server = await start('node_a');
    final first = client(node(server, certificateName: 'node_a'));
    await first.checkElectrumAdapter();
    // Let the header subscription settle before another client joins.
    await first.getElectrumAdapter()!.request('server.version');
    final second = client(node(server, certificateName: 'node_a'));
    await second.checkElectrumAdapter();
    expect(second.getElectrumAdapter(), same(first.getElectrumAdapter()));
    expect(server.disconnections, 0);
  });

  test(
    'revoking approval cannot reuse a previously trusted connection',
    () async {
      final server = await start('node_a');
      final trusted = client(node(server, certificateName: 'node_a'));
      await trusted.checkElectrumAdapter();
      await trusted.getElectrumAdapter()!.request('server.version');
      final peer = trusted.getElectrumAdapter()!.peer;
      // No wallet closed the connection; the next client for this endpoint
      // carries the revocation itself.
      final revoked = client(node(server));
      await expectLater(
        revoked.checkElectrumAdapter(),
        throwsA(isA<HandshakeException>()),
      );
      expect(peer.isClosed, true);
      expect(revoked.getElectrumAdapter(), null);
    },
  );

  test('a fresh wallet applies a revocation no loaded wallet could', () async {
    final server = await start('node_a');
    // A wallet connected under the approval and was then deleted, which
    // leaves the coin-wide connection open. With no wallet of the coin
    // loaded, saving the revocation had no wallet to notify.
    final trusted = client(node(server, certificateName: 'node_a'));
    await trusted.checkElectrumAdapter();
    await trusted.getElectrumAdapter()!.request('server.version');
    final peer = trusted.getElectrumAdapter()!.peer;
    final fresh = BitcoinWallet<Bitcoin>(CryptoCurrencyNetwork.main)
      ..prefs = prefs
      ..nodeService = _Nodes(
        NodeModel(
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
        ),
      );
    // Wallet.load() calls this before the wallet has any client to close.
    await fresh.updateNode();
    await expectLater(
      fresh.electrumXClient.request(command: 'server.version'),
      throwsA(isA<HandshakeException>()),
    );
    expect(peer.isClosed, true);
  });
}
