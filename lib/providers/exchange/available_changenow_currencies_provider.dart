import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epicmobile/models/exchange/change_now/cn_available_currencies.dart';

final availableChangeNowCurrenciesProvider = Provider<CNAvailableCurrencies>(
  (ref) => CNAvailableCurrencies(),
);
