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
  @override
  bool get useTor => false;
  @override
  bool get wifiOnly => false;
  @override
  bool get torKillSwitch => false;
}

class _Tor extends Mock implements TorService {
  @override
  TorConnectionStatus get status => TorConnectionStatus.disconnected;
}

Future<void> _until(bool Function() ready) async {
  final watch = Stopwatch()..start();
  while (!ready()) {
    if (watch.elapsed > const Duration(seconds: 3)) {
      throw TimeoutException('Waiting for Tor gate test server');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

Future<Object?> _outcome(Future<dynamic> future) =>
    future.then<Object?>((value) => value, onError: (Object error) => error);

void main() {
  late Directory logs;
  late EventBus bus;
  setUpAll(() async {
    logs = await Directory.systemTemp.createTemp('electrum_tor_gate');
    await Logging.instance.initialize(logs.path, level: Level.off);
  });
  tearDownAll(() => logs.delete(recursive: true));
  setUp(() => bus = EventBus(sync: true));
  tearDown(() async {
    await ClientManager.sharedInstance.closeAll();
    bus.destroy();
  });

  Future<TlsElectrumServer> start({bool stallVersion = false}) async {
    final server = await TlsElectrumServer.start(
      certificateName: null,
      ignoredMethods: stallVersion ? {'server.version'} : const {},
    );
    addTearDown(server.close);
    return server;
  }

  ElectrumXClient clientFor(TlsElectrumServer server) {
    final client = ElectrumXClient(
      host: '127.0.0.1',
      port: server.port,
      useSSL: false,
      prefs: _Prefs(),
      torService: _Tor(),
      cryptoCurrency: Bitcoin(CryptoCurrencyNetwork.main),
      netType: TorPlainNetworkOption.both,
      failovers: [],
      globalEventBusForTesting: bus,
      connectionTimeoutForSpecialCaseJsonRPCClients: const Duration(seconds: 2),
    );
    addTearDown(client.closeAdapter);
    return client;
  }

  void status(TorConnectionStatus value) {
    bus.fire(TorConnectionStatusChangedEvent(value, 'test'));
  }

  final cancelled = isA<StateError>().having(
    (error) => error.message,
    'message',
    'Electrum client changed',
  );

  for (final batch in [false, true]) {
    final label = batch ? 'batch' : 'request';
    Future<dynamic> send(ElectrumXClient client) => batch
        ? client.batchRequest(command: 'probe', args: [<dynamic>[]])
        : client.request(command: 'probe');

    test('$label waiters cancel when closed while Tor is connecting', () async {
      final server = await start();
      final client = clientFor(server);
      status(TorConnectionStatus.connecting);
      await Future<void>.delayed(Duration.zero);
      final pending = [for (var i = 0; i < 3; i++) _outcome(send(client))];
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(server.accepted, 0);

      await client.closeAdapter();

      for (final result in pending) {
        expect(await result.timeout(const Duration(seconds: 3)), cancelled);
      }
      expect(server.accepted, 0);
      expect(client.getElectrumAdapter(), isNull);
    });

    test(
      '$label close after Tor resumes preserves setup cancellation',
      () async {
        final server = await start(stallVersion: true);
        final client = clientFor(server);
        status(TorConnectionStatus.connecting);
        await Future<void>.delayed(Duration.zero);
        final result = _outcome(send(client));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(server.accepted, 0);
        status(TorConnectionStatus.connected);
        await _until(() => server.methods.contains('server.version'));

        await client.closeAdapter();

        expect(await result.timeout(const Duration(seconds: 3)), cancelled);
        expect(client.getElectrumAdapter(), isNull);
        expect(server.methods, ['server.version']);
        await _until(() => server.disconnections == 1);
      },
    );

    for (final finished in [
      TorConnectionStatus.connected,
      TorConnectionStatus.disconnected,
    ]) {
      test(
        '$label waiters resume on $finished after repeated connecting events',
        () async {
          final server = await start();
          final client = clientFor(server);
          status(TorConnectionStatus.connecting);
          status(TorConnectionStatus.connecting);
          await Future<void>.delayed(Duration.zero);
          final pending = [for (var i = 0; i < 3; i++) _outcome(send(client))];
          await Future<void>.delayed(const Duration(milliseconds: 20));
          expect(server.accepted, 0);

          status(finished);

          for (final result in pending) {
            expect(
              await result.timeout(const Duration(seconds: 3)),
              batch ? [<String, dynamic>{}] : <String, dynamic>{},
            );
          }
          expect(server.accepted, 1);
          expect(
            server.methods.where((method) => method == 'probe'),
            hasLength(3),
          );
        },
      );
    }
  }
}
