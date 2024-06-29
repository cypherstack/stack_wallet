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
    // If we're supposed to use Tor...
    if (_prefs.useTor) {
      // But Tor isn't running...
      if (_torService.status != TorConnectionStatus.connected) {
        // And the killswitch isn't set...
        if (!_prefs.torKillSwitch) {
          // Then we'll just proceed and connect to ElectrumX through clearnet at the bottom of this function.
          Logging.instance.log(
            "Tor preference set but Tor is not enabled, killswitch not set, connecting to Electrum adapter through clearnet",
            level: LogLevel.Warning,
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
  } catch (_) {
    return false;
  }
}
