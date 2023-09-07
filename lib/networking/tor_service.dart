import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      return;
    }

    try {
      await _tor.start();
      // no exception or error so we can (probably?) assume tor
      // has started successfully
      _enabled = true;
    } catch (e, s) {
      Logging.instance.log(
        "TorService.start failed: $e\n$s",
        level: LogLevel.Warning,
      );
      rethrow;
    }
  }

  Future<void> stop() async {
    if (!_enabled) {
      // already stopped so just return
      // could throw an exception here or something so the caller
      // is explicitly made aware of this
      return;
    }

    try {
      await _tor.disable();
      // no exception or error so we can (probably?) assume tor
      // has started successfully
      _enabled = false;
    } catch (e, s) {
      Logging.instance.log(
        "TorService.stop failed: $e\n$s",
        level: LogLevel.Warning,
      );
      rethrow;
    }
  }
}
