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
  final Map<String, String?> _certificates = {};
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
    String? trustedCertificatePem,
  }) async {
    final key = _keyHelper(cryptoCurrency);
    final previous = _map[key];
    final subscription = _subscriptions.remove(key);
    _map[key] = client;
    _mapNet[key] = netType;
    _heights.remove(key);
    _certificates[key] = trustedCertificatePem;
    final firstHeight = _heightCompleters[key] = Completer<int>();
    _subscriptions[key] = client.subscribeHeaders().listen(
      (event) {
        if (!identical(_map[key], client)) return;
        _heights[key] = event.height;
        if (!firstHeight.isCompleted) {
          firstHeight.complete(event.height);
        }
      },
      onError: (Object err, StackTrace s) =>
          Logging.instance.e("ClientManager listen", error: err, stackTrace: s),
    );
    await subscription?.cancel();
    await previous?.close();
  }

  Future<int> getChainHeightFor(CryptoCurrency cryptoCurrency) async {
    final key = _keyHelper(cryptoCurrency);

    if (_map[key] == null) {
      throw Exception("No managed ElectrumClient for $key found.");
    }
    if (_heightCompleters[key] == null) {
      throw Exception("No managed _heightCompleters for $key found.");
    }

    if (Prefs.instance.useTor) {
      if (_mapNet[key]! == TorPlainNetworkOption.clear) {
        throw Exception("Non-TOR only client for $key found.");
      }
    } else {
      if (_mapNet[key]! == TorPlainNetworkOption.tor) {
        throw Exception("TOR only client for $key found.");
      }
    }

    return _heights[key] ?? await _heightCompleters[key]!.future;
  }

  /// The certificate the managed connection for [cryptoCurrency] was opened
  /// with, or null when it relies on the platform's trusted roots.
  String? trustedCertificateFor(CryptoCurrency cryptoCurrency) =>
      _certificates[_keyHelper(cryptoCurrency)];

  Future<(ElectrumClient?, TorPlainNetworkOption?)> remove({
    required CryptoCurrency cryptoCurrency,
    ElectrumClient? expectedClient,
  }) async {
    final key = _keyHelper(cryptoCurrency);
    if (expectedClient != null && !identical(_map[key], expectedClient)) {
      return (null, null);
    }
    final client = _map.remove(key);
    final network = _mapNet.remove(key);
    final subscription = _subscriptions.remove(key);
    _heights.remove(key);
    _heightCompleters.remove(key);
    _certificates.remove(key);
    await subscription?.cancel();
    return (client, network);
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
    _certificates.clear();
  }
}
