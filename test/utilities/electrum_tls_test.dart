import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/connection_check/electrum_connection_check.dart';
import 'package:stackwallet/utilities/tls_certificate.dart';

import 'tls_test_server.dart';

void main() {
  final servers = <TlsElectrumServer>[];
  final proxies = <TlsTestProxy>[];

  Future<TlsElectrumServer> start({
    String? certificateName = 'node_a',
    bool respond = true,
  }) async {
    final server = await TlsElectrumServer.start(
      certificateName: certificateName,
      respond: respond,
    );
    servers.add(server);
    return server;
  }

  Future<ElectrumConnectionResult> check(
    TlsElectrumServer server, {
    String? trustedCertificatePem,
    String host = '127.0.0.1',
    bool useSSL = true,
    ({InternetAddress host, int port})? proxyInfo,
    Duration timeout = const Duration(seconds: 2),
  }) => testElectrumConnection(
    host: host,
    port: server.port,
    useSSL: useSSL,
    trustedCertificatePem: trustedCertificatePem,
    proxyInfo: proxyInfo,
    timeout: timeout,
  );

  tearDown(() async {
    for (final proxy in proxies) {
      await proxy.close();
    }
    for (final server in servers) {
      await server.close();
    }
    proxies.clear();
    servers.clear();
  });

  test('untrusted TLS returns a certificate without sending an RPC', () async {
    final server = await start();
    final result = await check(server);
    expect(result.success, false);
    expect(result.certificate, isNotNull);
    expect(
      certificateDer(result.certificate!.pem),
      certificateDer(TlsElectrumServer.certificate('node_a')),
    );
    expect(
      trustedCertificateCheck(TlsElectrumServer.certificate('node_a'))!(
        result.certificate!,
      ),
      true,
    );
    expect(
      trustedCertificateCheck(TlsElectrumServer.certificate('node_b'))!(
        result.certificate!,
      ),
      false,
    );
    expect(server.requests, 0);
  });

  test('approval enables RPC and closes the test connection', () async {
    final server = await start();
    final rejected = await check(server);
    final approved = await check(
      server,
      trustedCertificatePem: rejected.certificate!.pem,
    );
    expect(approved.success, true, reason: approved.error?.toString());
    expect(server.requests, 1);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(server.disconnections, 1);
  });

  test('approval does not change the default trust store', () async {
    final server = await start();
    expect(
      (await check(
        server,
        trustedCertificatePem: TlsElectrumServer.certificate('node_a'),
      )).success,
      true,
    );
    expect((await check(server)).success, false);
  });

  test('another certificate is rejected and returned for review', () async {
    final server = await start(certificateName: 'node_b');
    final result = await check(
      server,
      trustedCertificatePem: TlsElectrumServer.certificate('node_a'),
    );
    expect(result.success, false);
    expect(
      certificateDer(result.certificate!.pem),
      certificateDer(TlsElectrumServer.certificate('node_b')),
    );
    expect(server.requests, 0);
  });

  test('invalid saved PEM fails without connecting', () async {
    final server = await start();
    final result = await check(server, trustedCertificatePem: 'invalid');
    expect(result.success, false);
    expect(result.error, isA<FormatException>());
    expect(server.requests, 0);
  });

  test('approval pins the certificate even after it expired', () async {
    final server = await start(certificateName: 'expired');
    final rejected = await check(server);
    expect(rejected.success, false);
    expect(rejected.certificate, isNotNull);
    final approved = await check(
      server,
      trustedCertificatePem: TlsElectrumServer.certificate('expired'),
    );
    expect(approved.success, true, reason: approved.error?.toString());
    expect(server.requests, 1);
  });

  test('plain TCP can be tested without a certificate', () async {
    final server = await start(certificateName: null);
    final result = await check(server, useSSL: false);
    expect(result.success, true);
    expect(result.certificate, null);
  });

  test('RPC timeout fails and closes the connection', () async {
    final server = await start(respond: false);
    final result = await check(
      server,
      trustedCertificatePem: TlsElectrumServer.certificate('node_a'),
      timeout: const Duration(milliseconds: 200),
    );
    expect(result.success, false);
    expect(result.certificate, null);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(server.disconnections, 1);
  });

  test('SOCKS TLS rejection and approval use the same proxy', () async {
    final server = await start();
    final proxy = await TlsTestProxy.start(server.port);
    proxies.add(proxy);
    final rejected = await check(
      server,
      host: 'tlsx.test.onion',
      proxyInfo: proxy.info,
    );
    expect(rejected.success, false);
    expect(rejected.certificate, isNotNull);
    expect(server.requests, 0);
    final approved = await check(
      server,
      host: 'tlsx.test.onion',
      proxyInfo: proxy.info,
      trustedCertificatePem: rejected.certificate!.pem,
    );
    expect(approved.success, true, reason: approved.error?.toString());
    expect(proxy.destinations, everyElement('tlsx.test.onion'));
    expect(proxy.destinations.length, 2);
  });

  test('approved certificate does not have to match the hostname', () async {
    final server = await start();
    final proxy = await TlsTestProxy.start(server.port);
    proxies.add(proxy);
    final result = await check(
      server,
      host: 'wrong.example',
      proxyInfo: proxy.info,
      trustedCertificatePem: TlsElectrumServer.certificate('node_a'),
    );
    expect(result.success, true, reason: result.error?.toString());
    expect(server.requests, 1);
  });

  test('a stalled handshake fails when the timeout fires', () async {
    final stalled = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final accepted = <Socket>[];
    // Accept, then never answer the handshake.
    stalled.listen((socket) {
      accepted.add(socket);
      socket.listen((_) {}, onError: (Object _) {});
    });
    final stopwatch = Stopwatch()..start();
    final result = await testElectrumConnection(
      host: '127.0.0.1',
      port: stalled.port,
      useSSL: true,
      timeout: const Duration(milliseconds: 300),
    );
    expect(result.success, false);
    expect(result.error, isA<TimeoutException>());
    expect(result.certificate, null);
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 3)));
    for (final socket in accepted) {
      socket.destroy();
    }
    await stalled.close();
  });

  test('PEM parsing accepts one certificate and rejects bundles', () {
    final pem = TlsElectrumServer.certificate('node_a');
    expect(
      certificateFingerprint(certificateDer(pem)),
      matches(RegExp(r'^(?:[0-9A-F]{2}:){31}[0-9A-F]{2}$')),
    );
    expect(() => certificateDer('$pem$pem'), throwsFormatException);
    expect(trustedCertificateCheck(null), null);
    expect(() => trustedCertificateCheck('invalid'), throwsFormatException);
  });
}
