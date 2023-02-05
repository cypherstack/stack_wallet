import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/exchange/exchange_form_state.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/exchange_rate_sheet.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';

final exchangeFormStateProvider =
    ChangeNotifierProvider<ExchangeFormState>((ref) {
  final type = ref.watch(
    prefsChangeNotifierProvider.select(
      (value) => value.exchangeRateType,
    ),
  );

  switch (type) {
    case ExchangeRateType.estimated:
      return ref.watch(_estimatedFormState);
    case ExchangeRateType.fixed:
      return ref.watch(_fixedFormState);
  }
});

final _fixedInstance = ExchangeFormState(ExchangeRateType.fixed);
final _fixedFormState = ChangeNotifierProvider(
  (ref) => _fixedInstance,
);

final _estimatedInstance = ExchangeFormState(ExchangeRateType.estimated);
final _estimatedFormState = ChangeNotifierProvider(
  (ref) => _estimatedInstance,
);
