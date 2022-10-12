import 'package:stackwallet/models/exchange/response_objects/currency.dart';
import 'package:stackwallet/models/exchange/response_objects/fixed_rate_market.dart';
import 'package:stackwallet/models/exchange/response_objects/pair.dart';

class CNAvailableCurrencies {
  final List<Currency> currencies = [];
  final List<Pair> pairs = [];
  final List<FixedRateMarket> markets = [];

  void updateCurrencies(List<Currency> newCurrencies) {
    currencies.clear();
    currencies.addAll(newCurrencies);
  }

  void updateFloatingPairs(List<Pair> newPairs) {
    pairs.clear();
    pairs.addAll(newPairs);
  }

  void updateMarkets(List<FixedRateMarket> newMarkets) {
    markets.clear();
    markets.addAll(newMarkets);
  }
}
