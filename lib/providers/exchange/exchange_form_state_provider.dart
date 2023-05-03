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
  return ref.watch(efSendAmountProvider)?.toStringAsFixed(8) ?? "";
});
final efReceiveAmountStringProvider = StateProvider<String>((ref) {
  return ref.watch(efReceiveAmountProvider)?.toStringAsFixed(8) ?? "";
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
  // final Decimal? amount = ref.watch(efReversedProvider)
  //     ? ref.watch(efSendAmountProvider)
  //     : ref.watch(efReceiveAmountProvider);

  return estimate != null;
});

final efRefreshingProvider = StateProvider<bool>((ref) => false);

final efWarningProvider = StateProvider((ref) {
  // if (ref.watch(efReversedProvider)) {
  //   final _receiveCurrency =
  //       ref.watch(efCurrencyPairProvider.select((value) => value.receive));
  //   final _receiveAmount = ref.watch(efReceiveAmountProvider);
  //   if (_receiveCurrency != null && _receiveAmount != null) {
  //     final range = ref.watch(efRangeProvider);
  //     if (range?.min != null &&
  //         _receiveAmount < range!.min! &&
  //         _receiveAmount > Decimal.zero) {
  //       return "Min receive amount ${range.min!.toString()} ${_receiveCurrency.ticker.toUpperCase()}";
  //     } else if (range?.max != null &&
  //         _receiveAmount > ref.watch(efRangeProvider)!.max!) {
  //       return "Max receive amount $range!.max!.toString()} ${_receiveCurrency.ticker.toUpperCase()}";
  //     }
  //   }
  // } else {
  //   final _sendCurrency =
  //       ref.watch(efCurrencyPairProvider.select((value) => value.send));
  //   final _sendAmount = ref.watch(efSendAmountProvider);
  //   if (_sendCurrency != null && _sendAmount != null) {
  //     final range = ref.watch(efRangeProvider);
  //     if (range?.min != null &&
  //         _sendAmount < range!.min! &&
  //         _sendAmount > Decimal.zero) {
  //       return "Min send amount ${range.min!.toString()} ${_sendCurrency.ticker.toUpperCase()}";
  //     } else if (range?.max != null && _sendAmount > range!.max!) {
  //       return "Max send amount ${range.max!.toString()} ${_sendCurrency.ticker.toUpperCase()}";
  //     }
  //   }
  // }

  return "";
});
