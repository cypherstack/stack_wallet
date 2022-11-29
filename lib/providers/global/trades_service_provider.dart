import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epicmobile/services/trade_service.dart';

final tradesServiceProvider =
    ChangeNotifierProvider<TradesService>((ref) => TradesService());
