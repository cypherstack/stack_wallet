import 'package:epicpay/providers/global/prefs_provider.dart';
import 'package:epicpay/services/price_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

int _count = 0;

final priceAnd24hChangeNotifierProvider =
    ChangeNotifierProvider<PriceService>((ref) {
  if (kDebugMode) {
    _count++;
    debugPrint(
        "priceAnd24hChangeNotifierProvider instantiation count: $_count");
  }

  final currency =
      ref.watch(prefsChangeNotifierProvider.select((value) => value.currency));
  return PriceService(currency)..start(true);
});
