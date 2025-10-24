import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../wl_gen/generated/tor_service_impl.dart';
import 'event_bus/events/global/tor_connection_status_changed_event.dart';

final pTorService = Provider<TorService>((_) => torService);

abstract class TorService {
  static TorService get sharedInstance => torService;

  /// Current status. Same as that fired on the event bus.
  TorConnectionStatus get status;

  /// Getter for the proxyInfo.
  ///
  /// Throws if Tor is not connected.
  ({InternetAddress host, int port}) getProxyInfo();

  /// Initialize the tor ffi lib instance if it hasn't already been set. Nothing
  /// changes if _tor is already been set.
  void init({required String torDataDirPath});

  /// Start the Tor service.
  ///
  /// This will start the Tor service and establish a Tor circuit.
  ///
  /// Throws an exception if the Tor library was not inited or if the Tor
  /// service fails to start.
  ///
  /// Returns a Future that completes when the Tor service has started.
  Future<void> start();

  /// Disable Tor.
  Future<void> disable();
}
