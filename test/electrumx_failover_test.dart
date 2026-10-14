import 'dart:io';

import 'package:event_bus/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart' show Level;
import 'package:mockito/mockito.dart';
import 'package:stackwallet/electrumx_rpc/client_manager.dart';
import 'package:stackwallet/electrumx_rpc/electrumx_client.dart';
import 'package:stackwallet/services/tor_service.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

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

void main() {
  late Directory logDirectory;
  setUpAll(() async {
    logDirectory = await Directory.systemTemp.createTemp('electrumx_failover');
    await Logging.instance.initialize(logDirectory.path, level: Level.off);
  });
  tearDownAll(() => logDirectory.delete(recursive: true));
  final coin = Bitcoin(CryptoCurrencyNetwork.main);
  final servers = <TlsElectrumServer>[];
  late EventBus bus;

  setUp(() => bus = EventBus());
  tearDown(() async {
    await ClientManager.sharedInstance.closeAll();
    bus.destroy();
    for (final server in servers) {
      await server.close();
    }
    servers.clear();
  });

  Future<TlsElectrumServer> startPlain() async {
    final server = await TlsElectrumServer.start(certificateName: null);
    servers.add(server);
    return server;
  }

  /// A port nothing listens on.
  Future<int> deadPort() async {
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = socket.port;
    await socket.close();
    return port;
  }

  ElectrumXNode node(int port, String id) => ElectrumXNode(
    address: '127.0.0.1',
    port: port,
    name: id,
    id: id,
    useSSL: false,
    torEnabled: true,
    clearnetEnabled: true,
  );

  ElectrumXClient client(
    ElectrumXNode primary, {
    List<ElectrumXNode> failovers = const [],
  }) => ElectrumXClient.from(
    node: primary,
    prefs: _Prefs(),
    torService: _Tor(),
    failovers: failovers,
    cryptoCurrency: coin,
    globalEventBusForTesting: bus,
  );

  test(
    'requests after a successful failover request stay on the failover',
    () async {
      final failover = await startPlain();
      final connection = client(
        node(await deadPort(), 'primary'),
        failovers: [node(failover.port, 'failover')],
      );
      connection.currentFailoverIndex = 0;
      // A successful request resets the failover index to the primary.
      expect(await connection.ping(), true);
      expect(connection.currentFailoverIndex, -1);
      final result = await connection.getTransaction(txHash: 'a' * 64);
      expect(result['confirmations'], 3);
      expect(connection.getElectrumAdapter()!.port, failover.port);
      // server.version, headers.subscribe, ping, transaction.get: one session.
      expect(failover.requests, 4);
      expect(failover.disconnections, 0);
    },
  );

  test('another client for the coin shares the failover connection', () async {
    final failover = await startPlain();
    final dead = await deadPort();
    final first = client(
      node(dead, 'primary'),
      failovers: [node(failover.port, 'failover')],
    );
    first.currentFailoverIndex = 0;
    expect(await first.ping(), true);
    final second = client(
      node(dead, 'primary'),
      failovers: [node(failover.port, 'failover')],
    );
    final result = await second.getTransaction(txHash: 'b' * 64);
    expect(result['confirmations'], 3);
    expect(failover.disconnections, 0);
  });
}
