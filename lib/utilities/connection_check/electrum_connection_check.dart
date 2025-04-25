import 'dart:io';

import 'package:electrum_adapter/electrum_adapter.dart';

import '../../services/event_bus/events/global/tor_connection_status_changed_event.dart';
import '../../services/tor_service.dart';
import '../logger.dart';
import '../prefs.dart';

Future<bool> checkElectrumServer({
  required String host,
  required int port,
  required bool useSSL,
  Prefs? overridePrefs,
  TorService? overrideTorService,
}) async {
  final _prefs = overridePrefs ?? Prefs.instance;
  final _torService = overrideTorService ?? TorService.sharedInstance;

  ({InternetAddress host, int port})? proxyInfo;

  try {
    if (_prefs.torKillSwitch) {
      // If the killswitch is set...
      if (_torService.status != TorConnectionStatus.connected) {
        // And Tor isn't connected, then we'll throw an exception.
        throw Exception(
          "Tor killswitch set but Tor is not connected, not connecting to Electrum adapter",
        );
      }
    }

    if (_prefs.useTor) {
      // If we're supposed to use Tor...
      if (_torService.status != TorConnectionStatus.connected) {
        // But Tor isn't connected...
        if (!_prefs.torKillSwitch) {
          // And the killswitch isn't set...
          // Then we'll just proceed and connect to ElectrumX through clearnet at the bottom of this function.
          Logging.instance.w(
            "Tor preference set but Tor is not enabled, killswitch not set, connecting to Electrum adapter through clearnet",
          );
        } else {
          // ... But if the killswitch is set, then we throw an exception.
          // This should never be reached.
          throw Exception(
            "Tor preference and killswitch set but Tor is not enabled, not connecting to Electrum adapter",
          );
          // TODO [prio=low]: Try to start Tor.
        }
      } else {
        // If Tor is connected, get the proxy info from the TorService.
        proxyInfo = _torService.getProxyInfo();
      }
    }

    final client = await ElectrumClient.connect(
      host: host,
      port: port,
      useSSL: useSSL && !host.endsWith('.onion'),
      proxyInfo: proxyInfo,
    ).timeout(
      Duration(seconds: (proxyInfo == null ? 5 : 30)),
      onTimeout: () => throw Exception(
        "The checkElectrumServer connect() call timed out.",
      ),
    );

    await client
        .ping()
        .timeout(Duration(seconds: (proxyInfo == null ? 5 : 30)));

    return true;
  } catch (e, s) {
    Logging.instance.e(
      "$e\n$s",
      error: e,
      stackTrace: s,
    );
    return false;
  }
}
