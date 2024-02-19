import 'dart:async';

import 'package:electrum_adapter/electrum_adapter.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

/// Manage chain height subscriptions for each coin.
abstract class ChainHeightServiceManager {
  // A map of chain height services for each coin.
  static final Map<Coin, ChainHeightService> _services = {};
  // Map<Coin, ChainHeightService> get services => _services;

  // Get the chain height service for a specific coin.
  static ChainHeightService? getService(Coin coin) {
    return _services[coin];
  }

  // Add a chain height service for a specific coin.
  static void add(ChainHeightService service, Coin coin) {
    // Don't add a new service if one already exists.
    if (_services[coin] == null) {
      _services[coin] = service;
    } else {
      throw Exception("Chain height service for $coin already managed");
    }
  }

  // Remove a chain height service for a specific coin.
  static void remove(Coin coin) {
    _services.remove(coin);
  }

  // Close all subscriptions and clean up resources.
  static Future<void> dispose() async {
    // Close each subscription.
    for (final coin in _services.keys) {
      final ChainHeightService? service = getService(coin);
      await service?.cancelListen();
      remove(coin);
    }
  }
}

/// A service to fetch and listen for chain height updates.
///
/// TODO: Add error handling and branching to handle various other scenarios.
class ChainHeightService {
  // The electrum_adapter client to use for fetching chain height updates.
  ElectrumClient client;

  // The subscription to listen for chain height updates.
  StreamSubscription<dynamic>? _subscription;

  // Whether the service has started listening for updates.
  bool get started => _subscription != null;

  // The current chain height.
  int? _height;
  int? get height => _height;

  ChainHeightService({required this.client});

  /// Fetch the current chain height and start listening for updates.
  Future<int> fetchHeightAndStartListenForUpdates() async {
    // Don't start a new subscription if one already exists.
    if (_subscription != null) {
      throw Exception(
        "Attempted to start a chain height service where an existing"
        " subscription already exists!",
      );
    }

    // A completer to wait for the current chain height to be fetched.
    final completer = Completer<int>();

    // Fetch the current chain height.
    _subscription = client.subscribeHeaders().listen((BlockHeader event) {
      _height = event.height;

      if (!completer.isCompleted) {
        completer.complete(_height);
      }
    });

    // Wait for the current chain height to be fetched.
    return completer.future;
  }

  /// Stop listening for chain height updates.
  Future<void> cancelListen() async => await _subscription?.cancel();
}
