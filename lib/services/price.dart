import 'dart:async';
import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:tuple/tuple.dart';

class PriceAPI {
  static const refreshInterval = 60;

  // initialize to older than current time minus at least refreshInterval
  static DateTime _lastCalled =
      DateTime.now().subtract(const Duration(seconds: refreshInterval + 10));

  static String _lastUsedBaseCurrency = "";

  static const Duration refreshIntervalDuration =
      Duration(seconds: refreshInterval);

  final Client client;

  PriceAPI(this.client);

  @visibleForTesting
  void resetLastCalledToForceNextCallToUpdateCache() {
    _lastCalled = DateTime(1970);
  }

  Future<void> _updateCachedPrices(
      Map<Coin, Tuple2<Decimal, double>> data) async {
    final Map<String, dynamic> map = {};

    for (final coin in Coin.values) {
      final entry = data[coin];
      if (entry == null) {
        map[coin.prettyName] = ["0", 0.0];
      } else {
        map[coin.prettyName] = [entry.item1.toString(), entry.item2];
      }
    }

    await DB.instance
        .put<dynamic>(boxName: DB.boxNamePriceCache, key: 'cache', value: map);
  }

  Map<Coin, Tuple2<Decimal, double>> get _cachedPrices {
    final map =
        DB.instance.get<dynamic>(boxName: DB.boxNamePriceCache, key: 'cache')
                as Map? ??
            {};
    // init with 0
    final result = {
      for (final coin in Coin.values) coin: Tuple2(Decimal.zero, 0.0)
    };

    for (final entry in map.entries) {
      result[coinFromPrettyName(entry.key as String)] = Tuple2(
          Decimal.parse(entry.value[0] as String), entry.value[1] as double);
    }

    return result;
  }

  Future<Map<Coin, Tuple2<Decimal, double>>> getPricesAnd24hChange(
      {required String baseCurrency}) async {
    final now = DateTime.now();
    if (_lastUsedBaseCurrency != baseCurrency ||
        now.difference(_lastCalled).inSeconds > 0) {
      _lastCalled = now;
      _lastUsedBaseCurrency = baseCurrency;
    } else {
      return _cachedPrices;
    }

    final externalCalls = Prefs.instance.externalCalls;
    if ((!Logger.isTestEnv && !externalCalls) ||
        !(await Prefs.instance.isExternalCallsSet())) {
      Logging.instance.log("User does not want to use external calls",
          level: LogLevel.Info);
      return _cachedPrices;
    }
    Map<Coin, Tuple2<Decimal, double>> result = {};
    try {
      final uri =
          Uri.parse("https://api.coingecko.com/api/v3/coins/markets?vs_currency"
              "=${baseCurrency.toLowerCase()}"
              "&ids=monero,bitcoin,litecoin,ecash,epic-cash,zcoin,dogecoin,"
              "bitcoin-cash,namecoin,wownero,ethereum,particl"
              "&order=market_cap_desc&per_page=50&page=1&sparkline=false");

      final coinGeckoResponse = await client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final coinGeckoData = jsonDecode(coinGeckoResponse.body) as List<dynamic>;

      for (final map in coinGeckoData) {
        final String coinName = map["name"] as String;
        final coin = coinFromPrettyName(coinName);

        final price = Decimal.parse(map["current_price"].toString());
        final change24h =
            double.parse(map["price_change_percentage_24h"].toString());

        result[coin] = Tuple2(price, change24h);
      }

      // update cache
      await _updateCachedPrices(result);

      return _cachedPrices;
    } catch (e, s) {
      Logging.instance.log("getPricesAnd24hChange($baseCurrency): $e\n$s",
          level: LogLevel.Error);
      // return previous cached values
      return _cachedPrices;
    }
  }

  static Future<List<String>?> availableBaseCurrencies() async {
    final externalCalls = Prefs.instance.externalCalls;
    if ((!Logger.isTestEnv && !externalCalls) ||
        !(await Prefs.instance.isExternalCallsSet())) {
      Logging.instance.log("User does not want to use external calls",
          level: LogLevel.Info);
      return null;
    }
    const uriString =
        "https://api.coingecko.com/api/v3/simple/supported_vs_currencies";
    try {
      final uri = Uri.parse(uriString);
      final response = await Client().get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final json = jsonDecode(response.body) as List<dynamic>;
      return List<String>.from(json);
    } catch (e, s) {
      Logging.instance.log("availableBaseCurrencies() using $uriString: $e\n$s",
          level: LogLevel.Error);
      return null;
    }
  }

  Future<Map<String, Tuple2<Decimal, double>>>
      getPricesAnd24hChangeForEthTokens({
    required Set<String> contractAddresses,
    required String baseCurrency,
  }) async {
    final Map<String, Tuple2<Decimal, double>> tokenPrices = {};

    if (contractAddresses.isEmpty) return tokenPrices;

    final externalCalls = Prefs.instance.externalCalls;
    if ((!Logger.isTestEnv && !externalCalls) ||
        !(await Prefs.instance.isExternalCallsSet())) {
      Logging.instance.log("User does not want to use external calls",
          level: LogLevel.Info);
      return tokenPrices;
    }

    try {
      final contractAddressesString =
          contractAddresses.reduce((value, element) => "$value,$element");
      final uri = Uri.parse(
          "https://api.coingecko.com/api/v3/simple/token_price/ethereum"
          "?vs_currencies=${baseCurrency.toLowerCase()}&contract_addresses"
          "=$contractAddressesString&include_24hr_change=true");

      final coinGeckoResponse = await client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final coinGeckoData = jsonDecode(coinGeckoResponse.body) as Map;

      for (final key in coinGeckoData.keys) {
        final contractAddress = key as String;

        final map = coinGeckoData[contractAddress] as Map;

        final price = Decimal.parse(map[baseCurrency.toLowerCase()].toString());
        final change24h = double.parse(
            map["${baseCurrency.toLowerCase()}_24h_change"].toString());

        tokenPrices[contractAddress] = Tuple2(price, change24h);
      }

      return tokenPrices;
    } catch (e, s) {
      Logging.instance.log(
        "getPricesAnd24hChangeForEthTokens($baseCurrency,$contractAddresses): $e\n$s",
        level: LogLevel.Error,
      );
      // return previous cached values
      return tokenPrices;
    }
  }
}
