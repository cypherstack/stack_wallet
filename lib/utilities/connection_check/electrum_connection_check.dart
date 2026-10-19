import 'dart:async';
import 'dart:io';

import 'package:electrum_adapter/electrum_adapter.dart';

import '../../app_config.dart';
import '../../models/node_form_data.dart';
import '../../services/event_bus/events/global/tor_connection_status_changed_event.dart';
import '../../services/tor_service.dart';
import '../logger.dart';
import '../prefs.dart';
import '../tls_certificate.dart';

/// The outcome of one connection attempt. [certificate] is the server's TLS
/// certificate when the attempt failed because that certificate was rejected.
class ElectrumConnectionResult {
  const ElectrumConnectionResult({
    required this.success,
    this.certificate,
    this.error,
  });

  final bool success;
  final X509Certificate? certificate;
  final Object? error;
}

/// Connects, sends server.version and disconnects. A certificate the
/// platform rejects is accepted only when it is the approved one; any other
/// is returned for review without being accepted.
Future<ElectrumConnectionResult> testElectrumConnection({
  required String host,
  required int port,
  required bool useSSL,
  required Duration timeout,
  String? trustedCertificatePem,
  ({InternetAddress host, int port})? proxyInfo,
}) async {
  ElectrumClient? client;
  X509Certificate? rejected;
  try {
    final trusted = useSSL
        ? trustedCertificateCheck(trustedCertificatePem)
        : null;
    client = await ElectrumClient.connect(
      host: host,
      port: port,
      useSSL: useSSL,
      proxyInfo: proxyInfo,
      connectionTimeout: timeout,
      acceptUnverified: false,
      onBadCertificate: (certificate) {
        if (trusted != null && trusted(certificate)) return true;
        rejected = certificate;
        return false;
      },
    ).timeout(timeout);
    await client.request('server.version').timeout(timeout);
    return const ElectrumConnectionResult(success: true);
  } catch (error) {
    return ElectrumConnectionResult(
      success: false,
      certificate: rejected,
      error: error,
    );
  } finally {
    await client?.close();
  }
}

/// Applies the Tor preference, then runs [testElectrumConnection].
Future<ElectrumConnectionResult> checkElectrumServer({
  required String host,
  required int port,
  required bool useSSL,
  Prefs? overridePrefs,
  TorService? overrideTorService,
  String? trustedCertificatePem,
}) async {
  final _prefs = overridePrefs ?? Prefs.instance;

  ({InternetAddress host, int port})? proxyInfo;

  try {
    if (AppConfig.hasFeature(AppFeature.tor) && _prefs.useTor) {
      final _torService = overrideTorService ?? TorService.sharedInstance;
      // But Tor isn't running...
      if (_torService.status != TorConnectionStatus.connected) {
        // And the killswitch isn't set...
        if (!_prefs.torKillSwitch) {
          // Then we'll just proceed and connect to ElectrumX through clearnet at the bottom of this function.
          Logging.instance.w(
            "Tor preference set but Tor is not enabled, killswitch not set, connecting to Electrum adapter through clearnet",
          );
        } else {
          // ... But if the killswitch is set, then we throw an exception.
          throw Exception(
            "Tor preference and killswitch set but Tor is not enabled, not connecting to Electrum adapter",
          );
          // TODO [prio=low]: Try to start Tor.
        }
      } else {
        // Get the proxy info from the TorService.
        proxyInfo = _torService.getProxyInfo();
      }
    }

    return await testElectrumConnection(
      host: host,
      port: port,
      useSSL: useSSL,
      trustedCertificatePem: trustedCertificatePem,
      proxyInfo: proxyInfo,
      timeout: Duration(seconds: proxyInfo == null ? 5 : 30),
    );
  } catch (e, s) {
    Logging.instance.e("$e\n$s", error: e, stackTrace: s);
    return ElectrumConnectionResult(success: false, error: e);
  }
}

typedef ElectrumNodeTester = Future<ElectrumConnectionResult> Function({
  required String host,
  required int port,
  required bool useSSL,
  String? trustedCertificatePem,
});

/// Tests the node in [data]. A rejected certificate is offered for review
/// through [requestTrust]; after approval the test is retried with it, and
/// only a successful retry keeps the approval in the form. The UI supplies
/// the approval dialog.
Future<bool> testElectrumNodeConnection(
  NodeFormData data, {
  required ElectrumNodeTester testConnection,
  required Future<bool> Function(X509Certificate, String, int) requestTrust,
  required bool Function() isActive,
  void Function(NodeFormData)? onSuccess,
}) async {
  final host = data.host!;
  final port = data.port!;
  final useSSL = data.useSSL!;
  final netOption = data.netOption;
  final certificatePem = data.trustedCertificatePem;
  final decision = data.certificateRevision;
  bool unchanged() =>
      isActive() &&
      data.host == host &&
      data.port == port &&
      data.useSSL == useSSL &&
      data.netOption == netOption &&
      data.certificateRevision == decision &&
      data.trustedCertificatePem == certificatePem;

  var response = await testConnection(
    host: host,
    port: port,
    useSSL: useSSL,
    trustedCertificatePem: certificatePem,
  );
  if (!unchanged()) return false;
  final certificate = response.certificate;
  if (certificate != null) {
    final shouldTrust = await requestTrust(certificate, host, port);
    if (!shouldTrust || !unchanged()) return false;
    response = await testConnection(
      host: host,
      port: port,
      useSSL: useSSL,
      trustedCertificatePem: certificate.pem,
    );
    if (!unchanged()) return false;
    if (response.success) {
      data.trustedCertificatePem = certificate.pem;
    }
  }
  if (response.success) onSuccess?.call(data);
  return response.success;
}
