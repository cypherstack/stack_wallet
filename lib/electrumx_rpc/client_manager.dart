import 'dart:async';

import 'package:electrum_adapter/electrum_adapter.dart';

import '../utilities/logger.dart';
import '../utilities/prefs.dart';
import '../utilities/tor_plain_net_option_enum.dart';
import '../wallets/crypto_currency/crypto_currency.dart';

typedef _DetachedClient = ({
  ElectrumClient? client,
  TorPlainNetworkOption? network,
  StreamSubscription<BlockHeader>? subscription,
});

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
    final previous = _detachClient(
      key,
      error: StateError('Electrum client for $key was replaced'),
    );
    _map[key] = client;
    _mapNet[key] = netType;
    _heights.remove(key);
    _certificates[key] = trustedCertificatePem;
    final firstHeight = _heightCompleters[key] = Completer<int>();
    // A subscription can fail before a wallet starts waiting for its height.
    // Observe the error now without changing what later consumers receive.
    firstHeight.future.ignore();
    _subscriptions[key] = client.subscribeHeaders().listen(
      (event) {
        if (!identical(_map[key], client)) return;
        _heights[key] = event.height;
        if (!firstHeight.isCompleted) {
          firstHeight.complete(event.height);
        }
      },
      onError: (Object err, StackTrace s) {
        Logging.instance.e("ClientManager listen", error: err, stackTrace: s);
        _retireFailedClient(key, client, err, s);
      },
      onDone: () => _retireFailedClient(
        key,
        client,
        StateError('Electrum header subscription for $key ended'),
      ),
    );
    await _closeDetached(previous);
  }

  void _retireFailedClient(
    String key,
    ElectrumClient client,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    final detached = _detachClient(
      key,
      expectedClient: client,
      error: error,
      stackTrace: stackTrace,
    );
    // A rejected header subscription can leave its RPC connection open. Retire
    // it as well, so the next wallet request can establish a healthy client.
    unawaited(
      _closeDetached(detached).catchError((Object err, StackTrace stack) {
        Logging.instance.e(
          'ClientManager cleanup',
          error: err,
          stackTrace: stack,
        );
      }),
    );
  }

  _DetachedClient _detachClient(
    String key, {
    ElectrumClient? expectedClient,
    required Object error,
    StackTrace? stackTrace,
  }) {
    if (expectedClient != null && !identical(_map[key], expectedClient)) {
      return (client: null, network: null, subscription: null);
    }
    final detached = (
      client: _map.remove(key),
      network: _mapNet.remove(key),
      subscription: _subscriptions.remove(key),
    );
    _heights.remove(key);
    _certificates.remove(key);
    final firstHeight = _heightCompleters.remove(key);
    if (firstHeight != null && !firstHeight.isCompleted) {
      firstHeight.completeError(error, stackTrace);
    }
    return detached;
  }

  Future<void> _closeDetached(_DetachedClient detached) async {
    try {
      await detached.subscription?.cancel();
    } finally {
      await detached.client?.close();
    }
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
    final detached = _detachClient(
      key,
      expectedClient: expectedClient,
      error: StateError('Electrum client for $key was removed'),
    );
    await detached.subscription?.cancel();
    return (detached.client, detached.network);
  }

  Future<void> closeAll() async {
    await _kill();
    _finalizer.detach(this);
  }

  Future<void> _kill() async {
    // Detach synchronously before awaiting cancellation. Old callbacks must
    // never remove a successor that is added while cleanup is in progress.
    final detached = [
      for (final key in _map.keys.toList())
        _detachClient(key, error: StateError('Electrum clients were closed')),
    ];
    await Future.wait(detached.map(_closeDetached));
  }
}
