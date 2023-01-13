import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/buy/simplex/simplex_supported_currencies.dart';

final supportedSimplexCurrenciesProvider = Provider<SimplexSupportedCurrencies>(
  (ref) => SimplexSupportedCurrencies(),
);
