import 'dart:async';

import 'package:electrum_adapter/electrum_adapter.dart';
import '../wallets/crypto_currency/crypto_currency.dart';

class ClientManager {
  ClientManager._();
  static final ClientManager sharedInstance = ClientManager._();

  final Map<String, ElectrumClient> _map = {};
  final Map<String, int> _heights = {};
  final Map<String, StreamSubscription<BlockHeader>> _subscriptions = {};
  final Map<String, Completer<int>> _heightCompleters = {};

  String _keyHelper(CryptoCurrency cryptoCurrency) {
    return "${cryptoCurrency.runtimeType}_${cryptoCurrency.network.name}";
  }

  final Finalizer<ClientManager> _finalizer = Finalizer((manager) async {
    await manager._kill();
  });

  ElectrumClient? getClient({
    required CryptoCurrency cryptoCurrency,
  }) =>
      _map[_keyHelper(cryptoCurrency)];

  void addClient(
    ElectrumClient client, {
    required CryptoCurrency cryptoCurrency,
  }) {
    final key = _keyHelper(cryptoCurrency);
    if (_map[key] != null) {
      throw Exception("ElectrumX Client for $key already exists.");
    } else {
      _map[key] = client;
    }

    _heightCompleters[key] = Completer<int>();
    _subscriptions[key] = client.subscribeHeaders().listen((event) {
      _heights[key] = event.height;

      if (!_heightCompleters[key]!.isCompleted) {
        _heightCompleters[key]!.complete(event.height);
      }
    });
  }

  Future<int> getChainHeightFor(CryptoCurrency cryptoCurrency) async {
    final key = _keyHelper(cryptoCurrency);

    if (_map[key] == null) {
      throw Exception(
        "No managed ElectrumClient for $key found.",
      );
    }
    if (_heightCompleters[key] == null) {
      throw Exception(
        "No managed _heightCompleters for $key found.",
      );
    }

    return _heights[key] ?? await _heightCompleters[key]!.future;
  }

  Future<ElectrumClient?> remove({
    required CryptoCurrency cryptoCurrency,
  }) async {
    final key = _keyHelper(cryptoCurrency);
    await _subscriptions[key]?.cancel();
    _subscriptions.remove(key);
    _heights.remove(key);
    _heightCompleters.remove(key);

    return _map.remove(key);
  }

  Future<void> closeAll() async {
    await _kill();
    _finalizer.detach(this);
  }

  Future<void> _kill() async {
    for (final sub in _subscriptions.values) {
      await sub.cancel();
    }
    for (final client in _map.values) {
      await client.close();
    }

    _heightCompleters.clear();
    _heights.clear();
    _subscriptions.clear();
    _map.clear();
  }
}
