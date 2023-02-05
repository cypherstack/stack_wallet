import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/exchange/majestic_bank/mb_available_currencies.dart';

final availableMajesticBankCurrenciesProvider = Provider<MBAvailableCurrencies>(
  (ref) => MBAvailableCurrencies(),
);
