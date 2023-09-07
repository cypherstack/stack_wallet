import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/services/event_bus/events/global/tor_connection_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/global_event_bus.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:tor/tor.dart';

final pTorService = Provider((_) => TorService.sharedInstance);

class TorService {
  final _tor = Tor();
  bool _enabled = false;

  TorService._();

  static final sharedInstance = TorService._();

  ({
    InternetAddress host,
    int port,
  }) get proxyInfo => (
        host: InternetAddress.loopbackIPv4,
        port: _tor.port,
      );

  bool get enabled => _enabled;

  Future<void> start() async {
    if (_enabled) {
      // already started so just return
      // could throw an exception here or something so the caller
      // is explicitly made aware of this
      // TODO restart tor after that's been added to the tor-ffi crate
      return;
    }

    try {
      GlobalEventBus.instance.fire(
        TorConnectionStatusChangedEvent(
          TorConnectionStatus.connecting,
          "Tor connection status changed: connecting",
        ),
      );
      await _tor.start();
      // no exception or error so we can (probably?) assume tor
      // has started successfully
      _enabled = true;
      GlobalEventBus.instance.fire(
        TorConnectionStatusChangedEvent(
          TorConnectionStatus.connected,
          "Tor connection status changed: connect ($_enabled)",
        ),
      );
    } catch (e, s) {
      Logging.instance.log(
        "TorService.start failed: $e\n$s",
        level: LogLevel.Warning,
      );
      // _enabled should already be false
      GlobalEventBus.instance.fire(
        TorConnectionStatusChangedEvent(
          TorConnectionStatus.disconnected,
          "Tor connection status changed: $_enabled (failed)",
        ),
      );
      rethrow;
    }
  }

  Future<void> stop() async {
    if (!_enabled) {
      // already stopped so just return
      // could throw an exception here or something so the caller
      // is explicitly made aware of this
      // TODO make sure to kill
      return;
    }

    try {
      await _tor.disable();
      // no exception or error so we can (probably?) assume tor
      // has started successfully
      _enabled = false;
      GlobalEventBus.instance.fire(
        TorConnectionStatusChangedEvent(
          TorConnectionStatus.disconnected,
          "Tor connection status changed: $_enabled (disabled)",
        ),
      );
    } catch (e, s) {
      Logging.instance.log(
        "TorService.stop failed: $e\n$s",
        level: LogLevel.Warning,
      );
      rethrow;
    }
  }
}
