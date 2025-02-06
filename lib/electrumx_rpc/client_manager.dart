import 'dart:async';

import 'package:electrum_adapter/electrum_adapter.dart';

import '../utilities/logger.dart';
import '../utilities/prefs.dart';
import '../utilities/tor_plain_net_option_enum.dart';
import '../wallets/crypto_currency/crypto_currency.dart';

class ClientManager {
  ClientManager._();
  static final ClientManager sharedInstance = ClientManager._();

  final Map<String, ElectrumClient> _map = {};
  final Map<String, TorPlainNetworkOption> _mapNet = {};
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
    required TorPlainNetworkOption netType,
  }) {
    final _key = _keyHelper(cryptoCurrency);

    if (netType == _mapNet[_key]) {
      return _map[_key];
    } else {
      return null;
    }
  }

  Future<void> addClient(
    ElectrumClient client, {
    required CryptoCurrency cryptoCurrency,
    required TorPlainNetworkOption netType,
  }) async {
    final key = _keyHelper(cryptoCurrency);
    if (_map[key] != null) {
      if (_mapNet[key] == netType) {
        throw Exception(
          "ElectrumX Client for $key and $netType already exists.",
        );
      }

      await remove(cryptoCurrency: cryptoCurrency);

      _map[key] = client;
      _mapNet[key] = netType;
    } else {
      _map[key] = client;
      _mapNet[key] = netType;
    }

    _heightCompleters[key] = Completer<int>();
    _subscriptions[key] = client.subscribeHeaders().listen(
      (event) {
        _heights[key] = event.height;

        if (!_heightCompleters[key]!.isCompleted) {
          _heightCompleters[key]!.complete(event.height);
        }
      },
      onError: (Object err, StackTrace s) => Logging.instance.e(
        "ClientManager listen",
        error: err,
        stackTrace: s,
      ),
    );
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

    if (Prefs.instance.useTor) {
      if (_mapNet[key]! == TorPlainNetworkOption.clear) {
        throw Exception(
          "Non-TOR only client for $key found.",
        );
      }
    } else {
      if (_mapNet[key]! == TorPlainNetworkOption.tor) {
        throw Exception(
          "TOR only client for $key found.",
        );
      }
    }

    return _heights[key] ?? await _heightCompleters[key]!.future;
  }

  Future<(ElectrumClient?, TorPlainNetworkOption?)> remove({
    required CryptoCurrency cryptoCurrency,
  }) async {
    final key = _keyHelper(cryptoCurrency);
    await _subscriptions[key]?.cancel();
    _subscriptions.remove(key);
    _heights.remove(key);
    _heightCompleters.remove(key);

    return (_map.remove(key), _mapNet.remove(key));
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
    _mapNet.clear();
    _map.clear();
  }
}
