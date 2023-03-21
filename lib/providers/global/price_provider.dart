import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackduo/providers/global/prefs_provider.dart';
import 'package:stackduo/services/price_service.dart';

int _count = 0;

final priceAnd24hChangeNotifierProvider =
    ChangeNotifierProvider<PriceService>((ref) {
  if (kDebugMode) {
    _count++;
  }

  final currency =
      ref.watch(prefsChangeNotifierProvider.select((value) => value.currency));
  return PriceService(currency);
});
