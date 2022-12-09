import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:epicpay/services/price.dart';
import 'package:epicpay/utilities/enums/coin_enum.dart';
import 'package:tuple/tuple.dart';

class PriceService extends ChangeNotifier {
  late final String baseTicker;
  final Duration updateInterval = const Duration(seconds: 60);

  Timer? _timer;
  final Map<Coin, Tuple2<Decimal, double>> _cachedPrices = {
    for (final coin in Coin.values) coin: Tuple2(Decimal.zero, 0.0)
  };
  final _priceAPI = PriceAPI(Client());

  Tuple2<Decimal, double> getPrice(Coin coin) => _cachedPrices[coin]!;

  PriceService(this.baseTicker);

  Future<void> updatePrice() async {
    final priceMap =
        await _priceAPI.getPricesAnd24hChange(baseCurrency: baseTicker);

    bool shouldNotify = false;
    for (final map in priceMap.entries) {
      if (_cachedPrices[map.key] != map.value) {
        _cachedPrices[map.key] = map.value;
        shouldNotify = true;
      }
    }

    if (shouldNotify) {
      notifyListeners();
    }
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void start(bool rightAway) {
    if (rightAway) {
      updatePrice();
    }
    _timer?.cancel();
    _timer = Timer.periodic(updateInterval, (_) {
      updatePrice();
    });
  }

  @override
  void dispose() {
    cancel();
    super.dispose();
  }
}
