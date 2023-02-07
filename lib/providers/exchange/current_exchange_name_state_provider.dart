import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/services/exchange/exchange.dart';

final currentExchangeNameStateProvider = StateProvider<String>(
  (ref) => Exchange.defaultExchange.name,
);
