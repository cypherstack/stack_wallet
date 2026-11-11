import 'dart:async';
import 'dart:convert';
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
import 'package:stackwallet/utilities/tor_plain_net_option_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

import 'utilities/tls_test_server.dart';

class _Prefs extends Mock implements Prefs {
  @override
  bool get useTor => false;
  @override
  bool get wifiOnly => false;
}

class _Tor extends Mock implements TorService {}

void main() {
  test('repeated requests can keep an approved duplicate-endpoint failover', () async {
    final logs = await Directory.systemTemp.createTemp('duplicate_endpoint');
    await Logging.instance.initialize(logs.path, level: Level.off);
    final listener = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final sockets = <Socket>[];
    int accepted = 0;
    addTearDown(() async {
      await ClientManager.sharedInstance.closeAll();
      for (final s in sockets) {
        s.destroy();
      }
      await listener.close();
      await logs.delete(recursive: true);
    });
    listener.listen((raw) async {
      final first = ++accepted == 1;
      sockets.add(raw);
      raw.done.ignore();
      final name = first ? 'node_a' : 'node_b';
      final context = SecurityContext()
        ..useCertificateChainBytes(
          utf8.encode(TlsElectrumServer.certificate(name)),
        )
        ..usePrivateKeyBytes(
          File('test/fixtures/tls/$name.key.pem').readAsBytesSync(),
        );
      try {
        final socket = await SecureSocket.secureServer(raw, context);
        sockets.add(socket);
        socket.done.ignore();
        socket
            .cast<List<int>>()
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((line) {
              final request = jsonDecode(line) as Map<String, dynamic>;
              final method = request['method'];
              final Object? result = switch (method) {
                'server.version' => ['test', '1.4'],
                'blockchain.headers.subscribe' => {
                  'height': 100,
                  'hex': '00' * 80,
                },
                'probe' =>
                  first ? {'error': 'retry at failover'} : {'via': 'B'},
                _ => null,
              };
              socket.write(
                '${jsonEncode({'jsonrpc': '2.0', 'id': request['id'], 'result': result})}\n',
              );
            }, onError: (Object _) {});
      } catch (_) {
        raw.destroy();
      }
    });
    final bus = EventBus();
    addTearDown(bus.destroy);
    final connection = ElectrumXClient(
      host: '127.0.0.1',
      port: listener.port,
      useSSL: true,
      prefs: _Prefs(),
      netType: TorPlainNetworkOption.both,
      cryptoCurrency: Bitcoin(CryptoCurrencyNetwork.main),
      torService: _Tor(),
      globalEventBusForTesting: bus,
      trustedCertificatePem: TlsElectrumServer.certificate('node_a'),
      connectionTimeoutForSpecialCaseJsonRPCClients: const Duration(seconds: 2),
      failovers: [
        ElectrumXNode(
          address: '127.0.0.1',
          port: listener.port,
          name: 'B',
          id: 'B',
          useSSL: true,
          torEnabled: true,
          clearnetEnabled: true,
          trustedCertificatePem: TlsElectrumServer.certificate('node_b'),
        ),
      ],
    );
    addTearDown(connection.closeAdapter);
    expect(await connection.request(command: 'probe'), {'via': 'B'});
    expect(connection.currentFailoverIndex, -1);
    final selected = connection.getElectrumAdapter();
    final next = await connection.ping().then<Object?>(
      (value) => value,
      onError: (Object e) => e,
    );
    expect(next, true);
    expect(connection.getElectrumAdapter(), same(selected));
  });
}
