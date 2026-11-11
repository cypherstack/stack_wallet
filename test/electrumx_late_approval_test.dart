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
  _Prefs(this.tor);
  final bool tor;
  @override
  bool get useTor => tor;
  @override
  bool get wifiOnly => false;
  @override
  bool get torKillSwitch => true;
}

class _Tor extends Mock implements TorService {
  _Tor(this.proxyInfo);
  final ({InternetAddress host, int port}) proxyInfo;
  final requested = Completer<void>();
  @override
  TorConnectionStatus get status => TorConnectionStatus.connected;
  @override
  ({InternetAddress host, int port}) getProxyInfo() {
    if (!requested.isCompleted) requested.complete();
    return proxyInfo;
  }
}

void main() {
  test(
    'late adapter completion cannot republish a retired certificate approval',
    () async {
      final logs = await Directory.systemTemp.createTemp(
        'tls_only_late_approval',
      );
      await Logging.instance.initialize(logs.path, level: Level.off);
      final oldServer = await TlsElectrumServer.start();
      final newServer = await TlsElectrumServer.start(certificateName: null);
      final proxy = await TlsTestProxy.start(
        oldServer.port,
        greetingDelay: const Duration(milliseconds: 200),
      );
      final tor = _Tor(proxy.info);
      final coin = Bitcoin(CryptoCurrencyNetwork.main);
      final bus = EventBus();
      final oldClient = ElectrumXClient(
        host: 'old.example',
        port: oldServer.port,
        useSSL: true,
        trustedCertificatePem: TlsElectrumServer.certificate('node_a'),
        prefs: _Prefs(true),
        netType: TorPlainNetworkOption.both,
        failovers: [],
        cryptoCurrency: coin,
        torService: tor,
        globalEventBusForTesting: bus,
      );
      final newClient = ElectrumXClient(
        host: '127.0.0.1',
        port: newServer.port,
        useSSL: false,
        prefs: _Prefs(false),
        netType: TorPlainNetworkOption.both,
        failovers: [],
        cryptoCurrency: coin,
        torService: tor,
        globalEventBusForTesting: bus,
      );
      addTearDown(() async {
        await oldClient.closeAdapter();
        await newClient.closeAdapter();
        await ClientManager.sharedInstance.closeAll();
        bus.destroy();
        await proxy.close();
        await oldServer.close();
        await newServer.close();
        await logs.delete(recursive: true);
      });

      final oldOutcome = oldClient.ping().then<Object?>(
        (value) => value,
        onError: (Object error) => error,
      );
      await tor.requested.future.timeout(const Duration(seconds: 2));
      await oldClient.closeAdapter();
      expect(await newClient.ping(), true);
      final replacement = newClient.getElectrumAdapter();
      expect(replacement, isNotNull);

      expect(
        await oldOutcome.timeout(const Duration(seconds: 3)),
        isA<StateError>(),
      );
      expect(proxy.destinations, ['old.example']);
      expect(oldServer.requests, 0);
      expect(newClient.getElectrumAdapter(), same(replacement));
      expect(await newClient.ping(), true);
    },
  );
}
