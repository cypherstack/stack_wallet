import 'package:stackwallet/models/isar/exchange_cache/currency.dart';
import 'package:stackwallet/models/isar/exchange_cache/pair.dart';

class SPAvailableCurrencies {
  final List<Currency> floatingRateCurrencies = [];
  final List<Currency> fixedRateCurrencies = [];

  final List<Pair> floatingRatePairs = [];
  final List<Pair> fixedRatePairs = [];

  void updateFloatingCurrencies(List<Currency> newCurrencies) {
    floatingRateCurrencies.clear();
    floatingRateCurrencies.addAll(newCurrencies);
  }

  void updateFixedCurrencies(List<Currency> newCurrencies) {
    fixedRateCurrencies.clear();
    fixedRateCurrencies.addAll(newCurrencies);
  }

  void updateFloatingPairs(List<Pair> newPairs) {
    floatingRatePairs.clear();
    floatingRatePairs.addAll(newPairs);
  }

  void updateFixedPairs(List<Pair> newPairs) {
    fixedRatePairs.clear();
    fixedRatePairs.addAll(newPairs);
  }
}
