import 'package:stackwallet/models/isar/exchange_cache/currency.dart';
import 'package:stackwallet/models/isar/exchange_cache/pair.dart';
import 'package:tuple/tuple.dart';

class AggregateCurrency {
  final Map<String, Currency?> _map = {};

  AggregateCurrency({
    required List<Tuple2<String, Currency>> exchangeCurrencyPairs,
  }) {
    assert(exchangeCurrencyPairs.isNotEmpty);

    for (final item in exchangeCurrencyPairs) {
      _map[item.item1] = item.item2;
    }
  }

  Currency? forExchange(String exchangeName) {
    return _map[exchangeName];
  }

  String get ticker => _map.values.first!.ticker;

  String get name => _map.values.first!.name;

  String get image => _map.values.first!.image;

  SupportedRateType get rateType => _map.values.first!.rateType;

  bool get isStackCoin => _map.values.first!.isStackCoin;

  @override
  String toString() {
    String str = "AggregateCurrency: {";
    for (final key in _map.keys) {
      str += " $key: ${_map[key]},";
    }
    str += " }";
    return str;
  }
}
