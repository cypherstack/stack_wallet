import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart' show Level;
import 'package:mockito/mockito.dart';
import 'package:stackwallet/services/event_bus/events/global/tor_connection_status_changed_event.dart';
import 'package:stackwallet/services/tor_service.dart';
import 'package:stackwallet/utilities/connection_check/electrum_connection_check.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';

import 'tls_test_server.dart';

class _TorPrefs extends Mock implements Prefs {
  @override
  bool get useTor => true;
  @override
  bool get torKillSwitch => false;
}

class _ConnectedTor extends Mock implements TorService {
  _ConnectedTor(this.proxy);
  final ({InternetAddress host, int port}) proxy;
  @override
  TorConnectionStatus get status => TorConnectionStatus.connected;
  @override
  ({InternetAddress host, int port}) getProxyInfo() => proxy;
}

void main() {
  late Directory logDirectory;
  setUpAll(() async {
    logDirectory = await Directory.systemTemp.createTemp('electrum_check');
    await Logging.instance.initialize(logDirectory.path, level: Level.off);
  });
  tearDownAll(() => logDirectory.delete(recursive: true));

  // The test server and the test SOCKS proxy both listen on 127.0.0.1; the
  // onion name is only ever sent to that proxy, never resolved.
  Future<void> withOnionServer(
    String? certificateName,
    Future<void> Function(TlsElectrumServer server, TlsTestProxy proxy) body,
  ) async {
    final server = await TlsElectrumServer.start(
      certificateName: certificateName,
    );
    final proxy = await TlsTestProxy.start(server.port);
    try {
      await body(server, proxy);
    } finally {
      await proxy.close();
      await server.close();
    }
  }

  test('an onion node with SSL is tested over TLS and can be trusted', () {
    return withOnionServer('node_a', (server, proxy) async {
      final rejected = await checkElectrumServer(
        host: 'tlsx.test.onion',
        port: server.port,
        useSSL: true,
        overridePrefs: _TorPrefs(),
        overrideTorService: _ConnectedTor(proxy.info),
      );
      expect(rejected.success, false);
      expect(rejected.certificate, isNotNull);
      expect(server.requests, 0);
      final approved = await checkElectrumServer(
        host: 'tlsx.test.onion',
        port: server.port,
        useSSL: true,
        trustedCertificatePem: rejected.certificate!.pem,
        overridePrefs: _TorPrefs(),
        overrideTorService: _ConnectedTor(proxy.info),
      );
      expect(approved.success, true, reason: approved.error?.toString());
      expect(server.requests, 1);
      expect(proxy.destinations, everyElement('tlsx.test.onion'));
    });
  });

  test('an onion node without SSL is tested in plain text', () {
    return withOnionServer(null, (server, proxy) async {
      final result = await checkElectrumServer(
        host: 'tlsx.test.onion',
        port: server.port,
        useSSL: false,
        overridePrefs: _TorPrefs(),
        overrideTorService: _ConnectedTor(proxy.info),
      );
      expect(result.success, true, reason: result.error?.toString());
      expect(result.certificate, null);
      expect(proxy.destinations, ['tlsx.test.onion']);
    });
  });
}
