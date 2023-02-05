import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/exchange/exchange_form_state.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/exchange_rate_sheet.dart';

final exchangeFormStateProvider =
    ChangeNotifierProvider.family<ExchangeFormState, ExchangeRateType>(
        (ref, type) {
  switch (type) {
    case ExchangeRateType.estimated:
      return _estimatedInstance;
    case ExchangeRateType.fixed:
      return _fixedInstance;
  }
});

final _fixedInstance = ExchangeFormState(ExchangeRateType.fixed);

final _estimatedInstance = ExchangeFormState(ExchangeRateType.estimated);
