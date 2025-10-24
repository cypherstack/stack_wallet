//ON
import 'dart:io';

import 'package:tor_ffi_plugin/tor_ffi_plugin.dart';

import '../../services/event_bus/events/global/tor_connection_status_changed_event.dart';
import '../../services/event_bus/global_event_bus.dart';
//END_ON
import '../../services/fusion_tor_service.dart';
import '../../services/tor_service.dart';
//ON
import '../../utilities/logger.dart';
//END_ON

TorService get torService => _getInterface();
FusionTorService get fusionTorService => _getFusionInterface();

//OFF
TorService _getInterface() => throw Exception("TOR not enabled!");
FusionTorService _getFusionInterface() => throw Exception("TOR not enabled!");

//END_OFF
//ON
TorService _getInterface() => _TorServiceImpl();
FusionTorService _getFusionInterface() => _FusionTorServiceImpl();

class _TorServiceImpl extends TorService {
  Tor? _tor;
  String? _torDataDirPath;
  TorConnectionStatus _status = TorConnectionStatus.disconnected;

  @override
  TorConnectionStatus get status => _status;

  /// Getter for the proxyInfo.
  ///
  /// Throws if Tor is not connected.
  @override
  ({InternetAddress host, int port}) getProxyInfo() {
    if (status == TorConnectionStatus.connected) {
      return (host: InternetAddress.loopbackIPv4, port: _tor!.port);
    } else {
      throw Exception("Tor proxy info fetched while not connected!");
    }
  }

  /// Initialize the tor ffi lib instance if it hasn't already been set. Nothing
  /// changes if _tor is already been set.
  @override
  void init({required String torDataDirPath, Tor? mockableOverride}) {
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
  @override
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
      Logging.instance.w("TorService.start failed: ", error: e, stackTrace: s);
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
  @override
  Future<void> disable() async {
    if (_tor == null) {
      throw Exception("TorService.init has not been called!");
    }

    // No need to update status and fire event if status won't change.
    if (_status == TorConnectionStatus.disconnected) {
      return;
    }

    _tor!.disable();
    await _tor?.stop();

    _updateStatusAndFireEvent(
      status: TorConnectionStatus.disconnected,
      message: "TorService.disable call success",
    );
  }

  void _updateStatusAndFireEvent({
    required TorConnectionStatus status,
    required String message,
  }) {
    _status = status;
    GlobalEventBus.instance.fire(
      TorConnectionStatusChangedEvent(_status, message),
    );
  }
}

class _FusionTorServiceImpl extends FusionTorService {
  Tor? _tor;
  String? _torDataDirPath;

  /// Getter for the proxyInfo.
  ///
  /// Throws if Tor is not connected.
  @override
  ({InternetAddress host, int port}) getProxyInfo() {
    try {
      return (host: InternetAddress.loopbackIPv4, port: _tor!.port);
    } catch (_) {
      throw Exception("Tor proxy info fetched while not connected!");
    }
  }

  /// Initialize the tor ffi lib instance if it hasn't already been set. Nothing
  /// changes if _tor is already been set.
  @override
  void init({required String torDataDirPath, Tor? mockableOverride}) {
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
  @override
  Future<void> start() async {
    if (_tor == null || _torDataDirPath == null) {
      throw Exception("FusionTorService.init has not been called!");
    }

    // Start the Tor service.
    try {
      await _tor!.start(torDataDirPath: _torDataDirPath!);
    } catch (e, s) {
      Logging.instance.w(
        "FusionTorService.start failed: ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }
}

//END_ON
