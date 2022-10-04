import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/services/exchange/change_now/change_now_exchange.dart';

final currentExchangeNameStateProvider = StateProvider<String>(
  (ref) => ChangeNowExchange.exchangeName,
);
