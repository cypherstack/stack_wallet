import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/exchange/fixed_rate_exchange_form_state.dart';

final fixedRateExchangeFormProvider =
    ChangeNotifierProvider<FixedRateExchangeFormState>(
        (ref) => FixedRateExchangeFormState());
