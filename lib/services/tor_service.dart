import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tor_ffi_plugin/tor_ffi_plugin.dart';

import '../utilities/logger.dart';
import 'event_bus/events/global/tor_connection_status_changed_event.dart';
import 'event_bus/global_event_bus.dart';

final pTorService = Provider((_) => TorService.sharedInstance);

class TorService {
  Tor? _tor;
  String? _torDataDirPath;

  /// Current status. Same as that fired on the event bus.
  TorConnectionStatus get status => _status;
  TorConnectionStatus _status = TorConnectionStatus.disconnected;

  /// Singleton instance of the TorService.
  ///
  /// Use this to access the TorService and its properties.
  static final sharedInstance = TorService._();

  // private constructor for singleton
  TorService._();

  /// Getter for the proxyInfo.
  ///
  /// Throws if Tor is not connected.
  ({
    InternetAddress host,
    int port,
  }) getProxyInfo() {
    if (status == TorConnectionStatus.connected) {
      return (
        host: InternetAddress.loopbackIPv4,
        port: _tor!.port,
      );
    } else {
      throw Exception("Tor proxy info fetched while not connected!");
    }
  }

  /// Initialize the tor ffi lib instance if it hasn't already been set. Nothing
  /// changes if _tor is already been set.
  void init({
    required String torDataDirPath,
    Tor? mockableOverride,
  }) {
    _tor ??= mockableOverride ?? Tor.instance;
    _torDataDirPath ??= torDataDirPath;
  }

  /// Start the Tor service.
  ///
  /// This will start the Tor service and establish a Tor circuit.
  ///
  /// Throws an exception if the Tor library was not inited or if the Tor
  /// service fails to start.
  ///
  /// Returns a Future that completes when the Tor service has started.
  Future<void> start() async {
    if (_tor == null || _torDataDirPath == null) {
      throw Exception("TorService.init has not been called!");
    }

    // Start the Tor service.
    try {
      _updateStatusAndFireEvent(
        status: TorConnectionStatus.connecting,
        message: "TorService.start call in progress",
      );

      await _tor!.start(torDataDirPath: _torDataDirPath!);

      // no exception or error so we can (probably?) assume tor
      // has started successfully
      // Fire a TorConnectionStatusChangedEvent on the event bus.
      _updateStatusAndFireEvent(
        status: TorConnectionStatus.connected,
        message: "TorService.start call success",
      );

      // Complete the future.
      return;
    } catch (e, s) {
      Logging.instance.log(
        "TorService.start failed: $e\n$s",
        level: LogLevel.Warning,
      );
      // _enabled should already be false

      // Fire a TorConnectionStatusChangedEvent on the event bus.
      _updateStatusAndFireEvent(
        status: TorConnectionStatus.disconnected,
        message: "TorService.start call failed",
      );
      rethrow;
    }
  }

  /// Disable Tor.
  Future<void> disable() async {
    if (_tor == null) {
      throw Exception("TorService.init has not been called!");
    }

    // No need to update status and fire event if status won't change.
    if (_status == TorConnectionStatus.disconnected) {
      return;
    }

    await _tor?.stop();

    _updateStatusAndFireEvent(
      status: TorConnectionStatus.disconnected,
      message: "TorService.disable call success",
    );

    return;
  }

  void _updateStatusAndFireEvent({
    required TorConnectionStatus status,
    required String message,
  }) {
    _status = status;
    GlobalEventBus.instance.fire(
      TorConnectionStatusChangedEvent(
        _status,
        message,
      ),
    );
  }
}
