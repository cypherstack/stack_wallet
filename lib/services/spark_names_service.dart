import 'package:mutex/mutex.dart';

import '../utilities/logger.dart';
import '../wallets/crypto_currency/crypto_currency.dart';

class _BiMap<K, V> {
  final Map<K, V> _byKey = {};
  final Map<V, K> _byValue = {};

  _BiMap();

  void addAll(Map<K, V> other) {
    for (final e in other.entries) {
      add(e.key, e.value);
    }
  }

  void add(K key, V value) {
    _byKey[key] = value;
    _byValue[value] = key;
  }

  void clear() {
    _byValue.clear();
    _byKey.clear();
  }

  K? getByValue(V value) => _byValue[value];
  V? getByKey(K key) => _byKey[key];
}

/// Basic service to track all spark names on test net and main net.
/// Data is currently stored in memory only.
abstract final class SparkNamesService {
  static final _lock = {
    CryptoCurrencyNetwork.main: Mutex(),
    CryptoCurrencyNetwork.test: Mutex(),
  };

  static const _minUpdateInterval = Duration(seconds: 10);
  static DateTime _lastUpdated = DateTime(2000); // some default

  static final _cache = {
    // key is address, uppercase name is value
    CryptoCurrencyNetwork.main: _BiMap<String, String>(),
    CryptoCurrencyNetwork.test: _BiMap<String, String>(),
  };

  static final _nameMap = {
    // key is uppercase, value is as entered
    CryptoCurrencyNetwork.main: <String, String>{},
    CryptoCurrencyNetwork.test: <String, String>{},
  };

  /// Get the address for the given spark name.
  static Future<String?> getAddressFor(
    String name, {
    CryptoCurrencyNetwork network = CryptoCurrencyNetwork.main,
  }) async {
    if (_cache[network] == null) {
      throw UnsupportedError(
        "CryptoCurrencyNetwork \"${network.name}\" is not currently allowed.",
      );
    }

    return await _lock[network]!.protect(
      () async => _cache[network]?.getByValue(name.toUpperCase()),
    );
  }

  /// Get the name for the given spark address.
  static Future<String?> getNameFor(
    String address, {
    CryptoCurrencyNetwork network = CryptoCurrencyNetwork.main,
  }) async {
    if (_cache[network] == null) {
      throw UnsupportedError(
        "CryptoCurrencyNetwork \"${network.name}\" is not currently allowed.",
      );
    }

    return await _lock[network]!.protect(
      () async => _nameMap[network]![_cache[network]?.getByKey(address)],
    );
  }

  static Future<void> update(
    List<({String name, String address})> names, {
    CryptoCurrencyNetwork network = CryptoCurrencyNetwork.main,
  }) async {
    Logging.instance.t("SparkNamesService.update called");
    if (_cache[network] == null) {
      throw UnsupportedError(
        "CryptoCurrencyNetwork \"${network.name}\" is not currently allowed.",
      );
    }

    final now = DateTime.now();
    if (now.difference(_lastUpdated) > _minUpdateInterval) {
      _lastUpdated = now;
    } else {
      Logging.instance.t(
        "SparkNamesService.update called too soon. Returning early.",
      );
      // too soon, return;
      return;
    }

    await _lock[network]!.protect(() async {
      Logging.instance.t(
        "SparkNamesService.update lock acquired and updating cache",
      );
      _cache[network]!.clear();
      _nameMap[network]!.clear();

      for (final pair in names) {
        final upperName = pair.name.toUpperCase();
        _nameMap[network]![upperName] = pair.name;

        _cache[network]!.add(pair.address, upperName);
      }

      Logging.instance.t("SparkNamesService.update updating cache complete");
    });
  }
}
