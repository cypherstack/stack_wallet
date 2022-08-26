import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/exchange/change_now/fixed_rate_market.dart';

final fixedRateMarketPairsStateProvider =
    StateProvider<List<FixedRateMarket>>((ref) => []);
