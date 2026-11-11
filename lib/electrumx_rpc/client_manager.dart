import 'dart:async';

import 'package:electrum_adapter/electrum_adapter.dart';

import '../utilities/logger.dart';
import '../utilities/prefs.dart';
import '../utilities/tor_plain_net_option_enum.dart';
import '../wallets/crypto_currency/crypto_currency.dart';
import 'draining_electrum_client.dart';

typedef _DetachedClient = ({
  ElectrumClient? client,
  TorPlainNetworkOption? network,
  StreamSubscription<BlockHeader>? subscription,
  String? certificate,
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
  final _retiring = <ElectrumClient, ({String key, String? certificate})>{};

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
    bool drainPrevious = false,
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
    await _closeDetached(previous, drainFor: drainPrevious ? key : null);
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
    // Other wallets' requests already sent on it finish first: a failed
    // subscription does not mean those responses will not arrive.
    unawaited(
      _closeDetached(detached, drainFor: key).catchError((
        Object err,
        StackTrace stack,
      ) {
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
      return (
        client: null,
        network: null,
        subscription: null,
        certificate: null,
      );
    }
    final detached = (
      client: _map.remove(key),
      network: _mapNet.remove(key),
      subscription: _subscriptions.remove(key),
      certificate: _certificates.remove(key),
    );
    _heights.remove(key);
    final firstHeight = _heightCompleters.remove(key);
    if (firstHeight != null && !firstHeight.isCompleted) {
      firstHeight.completeError(error, stackTrace);
    }
    return detached;
  }

  Future<void> _closeDetached(
    _DetachedClient detached, {
    String? drainFor,
  }) async {
    final client = detached.client;
    if (drainFor != null && client is DrainingElectrumClient) {
      _retiring[client] = (key: drainFor, certificate: detached.certificate);
      unawaited(
        client.done.then<void>(
          (_) => _retiring.remove(client),
          onError: (Object _) {
            _retiring.remove(client);
          },
        ),
      );
      // Retirement does not wait for the outstanding RPCs: the replacement
      // must be usable immediately. Their existing deadlines bound the drain.
      await client.retire();
      await detached.subscription?.cancel();
      return;
    }
    try {
      await detached.subscription?.cancel();
    } finally {
      await detached.client?.close();
    }
  }

  Future<void> retireClient({
    required CryptoCurrency cryptoCurrency,
    required ElectrumClient client,
  }) {
    final key = _keyHelper(cryptoCurrency);
    return _closeDetached(
      _detachClient(
        key,
        expectedClient: client,
        error: StateError('Electrum client for $key was replaced'),
      ),
      drainFor: key,
    );
  }

  /// Retired sockets still obey certificate and network changes. With no
  /// predicate, close all retiring connections for this currency immediately.
  Future<void> closeRetiredClients({
    required CryptoCurrency cryptoCurrency,
    bool Function(ElectrumClient, String?)? keep,
  }) async {
    final key = _keyHelper(cryptoCurrency);
    final clients = [
      for (final entry in _retiring.entries)
        if (entry.value.key == key &&
            (keep == null || !keep(entry.key, entry.value.certificate)))
          entry.key,
    ];
    for (final client in clients) {
      _retiring.remove(client);
    }
    await Future.wait(clients.map((client) => client.close()));
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
    final retiring = _retiring.keys.toList();
    _retiring.clear();
    await Future.wait([
      ...detached.map(_closeDetached),
      ...retiring.map((client) => client.close()),
    ]);
  }
}
