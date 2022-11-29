import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epicmobile/providers/exchange/current_exchange_name_state_provider.dart';
import 'package:epicmobile/services/exchange/exchange.dart';

final exchangeProvider = Provider<Exchange>(
  (ref) => Exchange.fromName(
    ref.watch(currentExchangeNameStateProvider.state).state,
  ),
);
