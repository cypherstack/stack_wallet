import 'dart:convert';

import 'package:decimal/decimal.dart';

import '../app_config.dart';
import '../networking/http.dart';
import '../utilities/logger.dart';
import '../utilities/prefs.dart';
import '../wallets/crypto_currency/crypto_currency.dart';
import 'tor_service.dart';

int? _getCoinloreCoinID(CryptoCurrency coin) =>
    switch (coin.ticker.toUpperCase()) {
      "BTC" => 90,
      "ETH" => 80,
      "SOL" => 48543,
      "DOGE" => 2,
      "ADA" => 257,
      "BCH" => 2321,
      "XMR" => 28,
      "XLM" => 89,
      "LTC" => 1,
      "XNO" => 65895,
      "DASH" => 8,
      "XTZ" => 3682,
      "XEC" => 51539,
      "BAN" => 151129,
      "NMC" => 323,
      "PPC" => 4,
      "EPIC" => 121831,
      "FIRO" => 147811, // Using the higher rank one (1043) instead of 7255
      "PART" => 236,
      "XEL" => 136163,
      "WOW" => 36551,
      "FACT" => 122233,
      "SAL" => 136677,
      "MWC" => 42709,

      _ => () {
        if (coin.network.isTestNet) {
          Logging.instance.i(
            "_getCoinloreCoinID($coin) is testnet and returning "
            "null as expected",
          );
        } else {
          Logging.instance.w(
            "_getCoinloreCoinID($coin) is NOT testnet and "
            "returning null!",
          );
        }
        return null;
      }(),
    };

class CoinloreApi {
  static const _baseUrl = "https://api.coinlore.net/api/";

  final HTTP _http;

  static const instance = CoinloreApi._();

  const CoinloreApi._() : _http = const HTTP();

  Future<dynamic> _get(String method) async {
    final response = await _http.get(
      url: Uri.parse("$_baseUrl/$method"),
      headers: {'Content-Type': 'application/json'},
      proxyInfo: !AppConfig.hasFeature(AppFeature.tor)
          ? null
          : Prefs.instance.useTor
          ? TorService.sharedInstance.getProxyInfo()
          : null,
    );

    if (response.code != 200) {
      throw Exception("CoinloreAPI ${response.code}: ${response.body}");
    }

    return jsonDecode(response.body);
  }

  Future<List<CoinloreTicker>> ticker({required Set<String> ids}) async {
    final json = await _get("ticker/?id=${ids.join(",")}");
    return (json as List)
        .map((e) => CoinloreTicker.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}

class CoinloreTicker {
  final String id;
  final String symbol;
  final String name;
  final String nameid;
  final int rank;
  final Decimal? priceUsd;
  final Decimal? percentChange24h;
  final Decimal? percentChange1h;
  final Decimal? percentChange7d;
  final Decimal? marketCapUsd;
  final Decimal? volume24;
  final Decimal? volume24Native;
  final Decimal? priceBtc;

  const CoinloreTicker({
    required this.id,
    required this.symbol,
    required this.name,
    required this.nameid,
    required this.rank,
    required this.priceUsd,
    required this.percentChange24h,
    required this.percentChange1h,
    required this.percentChange7d,
    required this.marketCapUsd,
    required this.volume24,
    required this.volume24Native,
    required this.priceBtc,
  });

  factory CoinloreTicker.fromMap(Map<String, dynamic> map) {
    return CoinloreTicker(
      id: map['id'] as String,
      symbol: map['symbol'] as String,
      name: map['name'] as String,
      nameid: map['nameid'] as String,
      rank: map['rank'] as int,
      priceUsd: Decimal.tryParse(map['price_usd'].toString()),
      percentChange24h: Decimal.tryParse(map['percent_change_24h'].toString()),
      percentChange1h: Decimal.tryParse(map['percent_change_1h'].toString()),
      percentChange7d: Decimal.tryParse(map['percent_change_7d'].toString()),
      marketCapUsd: Decimal.tryParse(map['market_cap_usd'].toString()),
      volume24: Decimal.tryParse(map['volume24'].toString()),
      volume24Native: Decimal.tryParse(map['volume24_native'].toString()),
      priceBtc: Decimal.tryParse(map['price_btc'].toString()),
    );
  }

  @override
  String toString() {
    return 'CoinloreTicker(\n'
        '  id: $id,\n'
        '  symbol: $symbol,\n'
        '  name: $name,\n'
        '  nameid: $nameid,\n'
        '  rank: $rank,\n'
        '  priceUsd: $priceUsd,\n'
        '  percentChange24h: $percentChange24h,\n'
        '  percentChange1h: $percentChange1h,\n'
        '  percentChange7d: $percentChange7d,\n'
        '  marketCapUsd: $marketCapUsd,\n'
        '  volume24: $volume24,\n'
        '  volume24Native: $volume24Native,\n'
        '  priceBtc: $priceBtc,\n'
        ')';
  }
}
