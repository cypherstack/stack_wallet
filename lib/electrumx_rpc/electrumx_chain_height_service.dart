import 'dart:async';

import 'package:electrum_adapter/electrum_adapter.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

/// Manage chain height subscriptions for each coin.
abstract class ChainHeightServiceManager {
  static final Map<Coin, ChainHeightService> _services = {};

  static ChainHeightService? getService(Coin coin) {
    return _services[coin];
  }

  static void add(ChainHeightService service, Coin coin) {
    if (_services[coin] == null) {
      _services[coin] = service;
    } else {
      throw Exception("Chain height service for $coin already managed");
    }
  }
}

// Basic untested impl. Needs error handling and branching to handle
// various other scenarios
class ChainHeightService {
  ElectrumClient client;

  StreamSubscription<dynamic>? _subscription;
  bool get started => _subscription != null;

  int? _height;
  int? get height => _height;

  ChainHeightService({required this.client});

  Future<int> fetchHeightAndStartListenForUpdates() async {
    if (_subscription != null) {
      throw Exception(
        "Attempted to start a chain height service where an existing"
        " subscription already exists!",
      );
    }

    final completer = Completer<int>();
    _subscription = client.subscribeHeaders().listen((event) {
      _height = event.height;
      if (!completer.isCompleted) {
        completer.complete(_height);
      }
    });

    return completer.future;
  }

  /// Untested/Unknown implications. USE AT OWN RISK
  Future<void> cancelListen() async => await _subscription?.cancel();
}
