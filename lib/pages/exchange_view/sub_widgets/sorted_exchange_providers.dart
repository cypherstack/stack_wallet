import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuple/tuple.dart';

import '../../../app_config.dart';
import '../../../models/exchange/response_objects/estimate.dart';
import '../../../models/exchange/response_objects/range.dart';
import '../../../providers/exchange/exchange_form_state_provider.dart';
import '../../../providers/global/locale_provider.dart';
import '../../../services/exchange/exchange.dart';
import '../../../services/exchange/exchange_response.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/amount/amount_formatter.dart';
import '../../../utilities/amount/amount_unit.dart';
import '../../../utilities/enums/exchange_rate_type_enum.dart';
import '../../../utilities/util.dart';
import '../../../wallets/crypto_currency/crypto_currency.dart';
import '../../../widgets/conditional_parent.dart';
import '../../../widgets/loading_indicator.dart';
import 'exchange_provider_option.dart';

class SortedExchangeProviders extends ConsumerStatefulWidget {
  const SortedExchangeProviders({
    super.key,
    required this.exchangees,
    required this.fixedRate,
    required this.reversed,
  });

  final List<Exchange> exchangees;
  final bool fixedRate;
  final bool reversed;

  @override
  ConsumerState<SortedExchangeProviders> createState() =>
      _SortedExchangeProvidersState();
}

class _SortedExchangeProvidersState
    extends ConsumerState<SortedExchangeProviders> {
  final List<(Exchange, Tuple2<ExchangeResponse<List<Estimate>>, Range?>?)>
  dataList = [];
  final List<(Exchange, List<Estimate>?)> estimates = [];

  List<(Exchange, Estimate?)> transform(Decimal amount, String rcvTicker) {
    final List<(Exchange, Estimate?)> flattened = [];

    for (final s in estimates) {
      if (s.$2 != null && s.$2!.isNotEmpty) {
        for (final e in s.$2!) {
          flattened.add((s.$1, e));
        }
      } else {
        flattened.add((s.$1, null));
      }
    }

    flattened.sort((a, b) {
      if (a.$2 == null && b.$2 == null) return 1;
      if (a.$2 != null && b.$2 == null) return 0;
      if (a.$2 == null && b.$2 != null) return 0;

      // or we get problems!!!
      assert(a.$2!.reversed == b.$2!.reversed);

      return _getRate(a.$2!, amount, rcvTicker) >
              _getRate(b.$2!, amount, rcvTicker)
          ? 0
          : 1;
    });

    return flattened;
  }

  Amount _getRate(Estimate e, Decimal amount, String rcvTicker) {
    int decimals;
    try {
      decimals = AppConfig.getCryptoCurrencyForTicker(
        rcvTicker,
      )!.fractionDigits;
    } catch (_) {
      decimals = 8; // some reasonable alternative
    }
    Amount rate;
    if (e.reversed) {
      rate = (amount / e.estimatedAmount)
          .toDecimal(scaleOnInfinitePrecision: 18)
          .toAmount(fractionDigits: decimals);
    } else {
      rate = (e.estimatedAmount / amount)
          .toDecimal(scaleOnInfinitePrecision: 18)
          .toAmount(fractionDigits: decimals);
    }
    return rate;
  }

  @override
  Widget build(BuildContext context) {
    final sendCurrency = ref.watch(
      efCurrencyPairProvider.select((value) => value.send),
    );
    final receivingCurrency = ref.watch(
      efCurrencyPairProvider.select((value) => value.receive),
    );
    final reversed = ref.watch(efReversedProvider);
    final amount = reversed
        ? ref.watch(efReceiveAmountProvider)
        : ref.watch(efSendAmountProvider);

    dataList.clear();
    estimates.clear();
    for (final exchange in widget.exchangees) {
      final data = ref.watch(efEstimatesListProvider(exchange.name));
      dataList.add((exchange, data));
      estimates.add((exchange, data?.item1.value));
    }

    // final data = ref.watch(efEstimatesListProvider(widget.exchange.name));
    // final estimates = data?.item1.value;

    final pair = sendCurrency != null && receivingCurrency != null
        ? (from: sendCurrency, to: receivingCurrency)
        : null;

    if (ref.watch(efRefreshingProvider)) {
      return const LoadingIndicator(width: 48, height: 48);
    }

    if (sendCurrency != null &&
        receivingCurrency != null &&
        amount != null &&
        amount > Decimal.zero) {
      final estimates = transform(amount, receivingCurrency.ticker);

      if (estimates.isNotEmpty) {
        return Column(
          mainAxisSize: .min,
          children: [
            for (int i = 0; i < estimates.length; i++)
              Builder(
                builder: (context) {
                  final e = estimates[i].$2;

                  if (e == null) {
                    return Consumer(
                      builder: (_, ref, __) {
                        String? message;

                        final data = dataList
                            .firstWhere((e) => identical(e.$1, estimates[i].$1))
                            .$2;

                        final range = data?.item2;
                        if (range != null) {
                          if (range.min != null && amount < range.min!) {
                            message ??= "Amount too small";
                          } else if (range.max != null && amount > range.max!) {
                            message ??= "Amount too large";
                          }
                        } else if (data?.item1.value == null) {
                          final rateType =
                              ref.watch(efRateTypeProvider) ==
                                  ExchangeRateType.estimated
                              ? "estimated"
                              : "fixed";
                          message ??= "Pair unavailable on $rateType rate flow";
                        }

                        return ExchProviderOption(
                          exchange: estimates[i].$1,
                          estimate: null,
                          pair: pair,
                          rateString: message ?? "Failed to fetch rate",
                          rateColor: Theme.of(
                            context,
                          ).extension<StackColors>()!.textError,
                        );
                      },
                    );
                  }

                  final rate = _getRate(e, amount, receivingCurrency.ticker);

                  CryptoCurrency? coin;
                  try {
                    coin = AppConfig.getCryptoCurrencyForTicker(
                      receivingCurrency.ticker,
                    );
                  } catch (_) {
                    coin = null;
                  }

                  final String rateString;
                  if (coin != null) {
                    rateString =
                        "1 ${sendCurrency.ticker.toUpperCase()} "
                        "~ ${ref.watch(pAmountFormatter(coin)).format(rate)}";
                  } else {
                    final formatter = AmountFormatter(
                      unit: AmountUnit.normal,
                      locale: ref.watch(
                        localeServiceChangeNotifierProvider.select(
                          (value) => value.locale,
                        ),
                      ),
                      coin: Bitcoin(
                        CryptoCurrencyNetwork.main,
                      ), // some sane default
                      maxDecimals: 8, // some sane default
                    );
                    rateString =
                        "1 ${sendCurrency.ticker.toUpperCase()} "
                        "~ ${formatter.format(rate, withUnitName: false)}"
                        " ${receivingCurrency.ticker.toUpperCase()}";
                  }

                  return ConditionalParent(
                    condition: i > 0,
                    builder: (child) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Util.isDesktop
                            ? Container(
                                height: 1,
                                color: Theme.of(
                                  context,
                                ).extension<StackColors>()!.background,
                              )
                            : const SizedBox(height: 16),
                        child,
                      ],
                    ),
                    child: ExchProviderOption(
                      key: Key(estimates[i].$1.name + e.exchangeProvider),
                      exchange: estimates[i].$1,
                      pair: pair,
                      estimate: e,
                      rateString: rateString,
                      kycRating: e.kycRating,
                    ),
                  );
                },
              ),
          ],
        );
      }
    }

    return Column(
      mainAxisSize: .min,
      children: [
        ...widget.exchangees.map(
          (e) => ExchProviderOption(
            exchange: e,
            estimate: null,
            pair: pair,
            rateString: "n/a",
          ),
        ),
      ],
    );
  }
}
