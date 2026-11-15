/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2026 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 *
 */

import 'package:decimal/decimal.dart';

import '../../../app_config.dart';
import '../../../models/exchange/active_pair.dart';
import '../../../models/exchange/aggregate_currency.dart';
import '../../../models/exchange/response_objects/estimate.dart';
import '../../../services/exchange/exchange.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/enums/exchange_rate_type_enum.dart';

/// Orders quotes best rate first; providers without a quote come last.
/// Exchanges that return several quotes (Trocador) contribute one entry per
/// quote.
List<(Exchange, Estimate?)> rankExchangeEstimates(
  Iterable<(Exchange, List<Estimate>?)> estimates, {
  required Decimal amount,
  required String receiveTicker,
}) {
  final List<(Exchange, Estimate?)> ranked = [];

  for (final (exchange, quotes) in estimates) {
    if (quotes != null && quotes.isNotEmpty) {
      for (final quote in quotes) {
        ranked.add((exchange, quote));
      }
    } else {
      ranked.add((exchange, null));
    }
  }

  ranked.sort((a, b) {
    final aRate = a.$2 == null
        ? null
        : exchangeRate(a.$2!, amount, receiveTicker);
    final bRate = b.$2 == null
        ? null
        : exchangeRate(b.$2!, amount, receiveTicker);

    if (aRate == null) return bRate == null ? 0 : 1;
    if (bRate == null) return -1;
    return bRate.decimal.compareTo(aRate.decimal);
  });

  return ranked;
}

/// Units of the receive currency per unit sent, as shown next to each quote.
Amount exchangeRate(Estimate estimate, Decimal amount, String receiveTicker) {
  int decimals;
  try {
    decimals = AppConfig.getCryptoCurrencyForTicker(receiveTicker)!
        .fractionDigits;
  } catch (_) {
    decimals = 8; // some reasonable alternative
  }

  final rate = estimate.reversed
      ? (amount / estimate.estimatedAmount)
      : (estimate.estimatedAmount / amount);
  return rate
      .toDecimal(scaleOnInfinitePrecision: 18)
      .toAmount(fractionDigits: decimals);
}

/// Identifies the swap a manual provider choice was made for. A choice only
/// holds while the pair and rate type are unchanged; editing the amount keeps
/// it.
String exchangeChoiceContext(ActivePair pair, ExchangeRateType rateType) {
  String part(AggregateCurrency? currency) => currency == null
      ? ""
      : "${currency.ticker.toLowerCase()}|${currency.fuzzyNet}";
  return "${part(pair.send)}>${part(pair.receive)}|${rateType.name}";
}

/// The provider to select after a quote refresh, or null to keep the current
/// selection.
///
/// Selects the best quote unless the user picked [currentExchange] for this
/// swap and it still has a matching quote.
(Exchange, String)? exchangeToSelect({
  required List<(Exchange, Estimate?)> ranked,
  required Exchange currentExchange,
  required String currentProviderName,
  required bool userChose,
  required bool fixedRate,
  required bool reversed,
}) {
  bool matches(Estimate e) =>
      e.fixedRate == fixedRate && e.reversed == reversed;

  final best = ranked
      .where((entry) => entry.$2 != null && matches(entry.$2!))
      .firstOrNull;
  if (best == null) return null;

  if (userChose) {
    final chosenHasQuote = ranked.any(
      (entry) =>
          entry.$1.name == currentExchange.name &&
          entry.$2 != null &&
          entry.$2!.exchangeProvider == currentProviderName &&
          matches(entry.$2!),
    );
    if (chosenHasQuote) return null;
  }

  return (best.$1, best.$2!.exchangeProvider);
}
