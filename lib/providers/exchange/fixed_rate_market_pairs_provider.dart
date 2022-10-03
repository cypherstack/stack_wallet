import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/exchange/response_objects/fixed_rate_market.dart';

final fixedRateMarketPairsStateProvider =
    StateProvider<List<FixedRateMarket>>((ref) => []);
