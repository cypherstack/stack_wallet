import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/exchange/simpleswap/sp_available_currencies.dart';

final availableSimpleswapCurrenciesProvider = Provider<SPAvailableCurrencies>(
  (ref) => SPAvailableCurrencies(),
);
