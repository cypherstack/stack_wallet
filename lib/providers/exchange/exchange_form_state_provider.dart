import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/exchange/active_pair.dart';
import 'package:stackwallet/models/exchange/response_objects/estimate.dart';
import 'package:stackwallet/models/exchange/response_objects/range.dart';
import 'package:stackwallet/services/exchange/exchange.dart';
import 'package:stackwallet/utilities/enums/exchange_rate_type_enum.dart';
import 'package:tuple/tuple.dart';

final efEstimatesListProvider =
    StateProvider.family<Tuple2<List<Estimate>, Range>?, String>(
        (ref, exchangeName) => null);

final efRateTypeProvider =
    StateProvider<ExchangeRateType>((ref) => ExchangeRateType.estimated);

final efExchangeProvider =
    StateProvider<Exchange>((ref) => Exchange.defaultExchange);
final efExchangeProviderNameProvider =
    StateProvider<String>((ref) => Exchange.defaultExchange.name);

final currentCombinedExchangeIdProvider = Provider<String>((ref) {
  return "${ref.watch(efExchangeProvider).name}"
      " (${ref.watch(efExchangeProviderNameProvider)})";
});

final efSendAmountProvider = StateProvider<Decimal?>((ref) => null);
final efReceiveAmountProvider = StateProvider<Decimal?>((ref) => null);

final efSendAmountStringProvider = StateProvider<String>((ref) {
  final refreshing = ref.watch(efRefreshingProvider);
  final reversed = ref.watch(efReversedProvider);
  if (refreshing && reversed) {
    return "-";
  } else {
    return ref.watch(efSendAmountProvider)?.toStringAsFixed(8) ?? "";
  }
});
final efReceiveAmountStringProvider = StateProvider<String>((ref) {
  final refreshing = ref.watch(efRefreshingProvider);
  final reversed = ref.watch(efReversedProvider);

  if (refreshing && reversed == false) {
    return "-";
  } else {
    return ref.watch(efReceiveAmountProvider)?.toStringAsFixed(8) ?? "";
  }
});

final efReversedProvider = StateProvider<bool>((ref) => false);

final efCurrencyPairProvider = ChangeNotifierProvider<ActivePair>(
  (ref) => ActivePair(),
);

final efRangeProvider = StateProvider<Range?>((ref) {
  final exchange = ref.watch(efExchangeProvider);
  return ref.watch(efEstimatesListProvider(exchange.name))?.item2;
});

final efEstimateProvider = StateProvider<Estimate?>((ref) {
  final exchange = ref.watch(efExchangeProvider);
  final provider = ref.watch(efExchangeProviderNameProvider);
  final reversed = ref.watch(efReversedProvider);
  final fixedRate = ref.watch(efRateTypeProvider) == ExchangeRateType.fixed;

  final matches =
      ref.watch(efEstimatesListProvider(exchange.name))?.item1.where((e) {
    return e.exchangeProvider == provider &&
        e.fixedRate == fixedRate &&
        e.reversed == reversed;
  });

  Estimate? result;

  if (matches != null && matches.isNotEmpty) {
    result = matches.first;
  } else {
    result = null;
  }

  return result;
});

final efCanExchangeProvider = StateProvider<bool>((ref) {
  final Estimate? estimate = ref.watch(efEstimateProvider);
  final refreshing = ref.watch(efRefreshingProvider);

  return !refreshing && estimate != null;
});

final efRefreshingProvider = StateProvider<bool>((ref) => false);
