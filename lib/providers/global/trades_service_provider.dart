import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/services/trade_service.dart';

final tradesServiceProvider =
    ChangeNotifierProvider<TradesService>((ref) => TradesService());
