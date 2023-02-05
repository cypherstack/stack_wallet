import 'package:stackwallet/models/isar/exchange_cache/currency.dart';
import 'package:stackwallet/models/isar/exchange_cache/pair.dart';

class MBAvailableCurrencies {
  final List<Currency> currencies = [];
  // final List<Currency> fixedRateCurrencies = [];

  final List<Pair> pairs = [];
  // final List<Pair> fixedRatePairs = [];

  // void updateFloatingCurrencies(List<Currency> newCurrencies) {
  //   floatingRateCurrencies.clear();
  //   floatingRateCurrencies.addAll(newCurrencies);
  // }

  void updateCurrencies(List<Currency> newCurrencies) {
    currencies.clear();
    currencies.addAll(newCurrencies);
  }

  // void updateFloatingPairs(List<Pair> newPairs) {
  //   floatingRatePairs.clear();
  //   floatingRatePairs.addAll(newPairs);
  // }

  void updatePairs(List<Pair> newPairs) {
    pairs.clear();
    pairs.addAll(newPairs);
  }
}
