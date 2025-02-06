import 'dart:io';

import 'package:tor_ffi_plugin/tor_ffi_plugin.dart';

import '../utilities/logger.dart';

class FusionTorService {
  Tor? _tor;
  String? _torDataDirPath;

  TorStatus get status => _tor!.status;

  /// Singleton instance of the TorService.
  ///
  /// Use this to access the TorService and its properties.
  static final sharedInstance = FusionTorService._();

  // private constructor for singleton
  FusionTorService._();

  /// Getter for the proxyInfo.
  ///
  /// Throws if Tor is not connected.
  ({
    InternetAddress host,
    int port,
  }) getProxyInfo() {
    try {
      return (
        host: InternetAddress.loopbackIPv4,
        port: _tor!.port,
      );
    } catch (_) {
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
      throw Exception("FusionTorService.init has not been called!");
    }

    // Start the Tor service.
    try {
      await _tor!.start(torDataDirPath: _torDataDirPath!);
    } catch (e, s) {
      Logging.instance.w("FusionTorService.start failed: ", error: e, stackTrace: s);
      rethrow;
    }
  }
}
