import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epicmobile/models/exchange/simpleswap/sp_available_currencies.dart';

final availableSimpleswapCurrenciesProvider = Provider<SPAvailableCurrencies>(
  (ref) => SPAvailableCurrencies(),
);
