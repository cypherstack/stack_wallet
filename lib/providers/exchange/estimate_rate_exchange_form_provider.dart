import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/exchange/estimated_rate_exchange_form_state.dart';

final estimatedRateExchangeFormProvider =
    ChangeNotifierProvider((ref) => EstimatedRateExchangeFormState());
