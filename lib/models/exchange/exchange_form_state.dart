import 'package:decimal/decimal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stackwallet/models/exchange/response_objects/currency.dart';
import 'package:stackwallet/models/exchange/response_objects/estimate.dart';
import 'package:stackwallet/models/exchange/response_objects/fixed_rate_market.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/exchange_rate_sheet.dart';
import 'package:stackwallet/services/exchange/exchange.dart';
import 'package:stackwallet/services/exchange/simpleswap/simpleswap_exchange.dart';
import 'package:stackwallet/utilities/logger.dart';

class ExchangeFormState extends ChangeNotifier {
  Exchange? _exchange;
  Exchange? get exchange => _exchange;
  set exchange(Exchange? value) {
    _exchange = value;
    _onExchangeTypeChanged();
  }

  ExchangeRateType _exchangeType = ExchangeRateType.estimated;
  ExchangeRateType get exchangeType => _exchangeType;
  set exchangeType(ExchangeRateType value) {
    _exchangeType = value;
    _onExchangeRateTypeChanged();
  }

  bool reversed = false;

  Decimal? fromAmount;
  Decimal? toAmount;

  Decimal? minAmount;
  Decimal? maxAmount;

  Decimal? rate;
  Estimate? estimate;

  FixedRateMarket? _market;
  FixedRateMarket? get market => _market;

  Currency? _from;
  Currency? _to;

  String? get fromTicker {
    switch (exchangeType) {
      case ExchangeRateType.estimated:
        return _from?.ticker;
      case ExchangeRateType.fixed:
        return _market?.from;
    }
  }

  String? get toTicker {
    switch (exchangeType) {
      case ExchangeRateType.estimated:
        return _to?.ticker;
      case ExchangeRateType.fixed:
        return _market?.to;
    }
  }

  void Function(String)? _onError;

  Currency? get from => _from;
  Currency? get to => _to;

  void setCurrencies(Currency from, Currency to) {
    _from = from;
    _to = to;
  }

  String get warning {
    if (reversed) {
      if (toTicker != null && toAmount != null) {
        if (minAmount != null && toAmount! < minAmount!) {
          return "Minimum amount ${minAmount!.toString()} ${toTicker!.toUpperCase()}";
        } else if (maxAmount != null && toAmount! > maxAmount!) {
          return "Maximum amount ${maxAmount!.toString()} ${toTicker!.toUpperCase()}";
        }
      }
    } else {
      if (fromTicker != null && fromAmount != null) {
        if (minAmount != null && fromAmount! < minAmount!) {
          return "Minimum amount ${minAmount!.toString()} ${fromTicker!.toUpperCase()}";
        } else if (maxAmount != null && fromAmount! > maxAmount!) {
          return "Maximum amount ${maxAmount!.toString()} ${fromTicker!.toUpperCase()}";
        }
      }
    }

    return "";
  }

  String get fromAmountString => fromAmount?.toStringAsFixed(8) ?? "";
  String get toAmountString => toAmount?.toStringAsFixed(8) ?? "";

  bool get canExchange {
    switch (exchangeType) {
      case ExchangeRateType.estimated:
        return fromAmount != null &&
            fromAmount != Decimal.zero &&
            toAmount != null &&
            rate != null &&
            warning.isEmpty;
      case ExchangeRateType.fixed:
        return _market != null &&
            fromAmount != null &&
            toAmount != null &&
            warning.isEmpty;
    }
  }

  void clearAmounts(bool shouldNotifyListeners) {
    fromAmount = null;
    toAmount = null;
    minAmount = null;
    maxAmount = null;
    rate = null;

    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  Future<void> setFromAmountAndCalculateToAmount(
    Decimal newFromAmount,
    bool shouldNotifyListeners,
  ) async {
    if (newFromAmount == Decimal.zero) {
      toAmount = Decimal.zero;
    }

    fromAmount = newFromAmount;
    reversed = false;

    await updateRanges(shouldNotifyListeners: false);

    await updateEstimate(
      shouldNotifyListeners: false,
      reversed: reversed,
    );

    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  Future<void> setToAmountAndCalculateFromAmount(
    Decimal newToAmount,
    bool shouldNotifyListeners,
  ) async {
    if (newToAmount == Decimal.zero) {
      fromAmount = Decimal.zero;
    }

    toAmount = newToAmount;
    reversed = true;

    await updateRanges(shouldNotifyListeners: false);

    await updateEstimate(
      shouldNotifyListeners: false,
      reversed: reversed,
    );

    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  Future<void> updateTo(Currency to, bool shouldNotifyListeners) async {
    try {
      _to = to;
      if (_from == null) {
        rate = null;
        notifyListeners();
        return;
      }

      await updateRanges(shouldNotifyListeners: false);

      await updateEstimate(
        shouldNotifyListeners: false,
        reversed: reversed,
      );

      debugPrint(
          "_updated TO: _from=${_from!.ticker} _to=${_to!.ticker} _fromAmount=$fromAmount _toAmount=$toAmount rate:$rate for: $exchange");

      if (shouldNotifyListeners) {
        notifyListeners();
      }
    } catch (e, s) {
      Logging.instance.log("$e\n$s", level: LogLevel.Error);
    }
  }

  Future<void> updateFrom(Currency from, bool shouldNotifyListeners) async {
    try {
      _from = from;

      if (_to == null) {
        rate = null;
        notifyListeners();
        return;
      }

      await updateRanges(shouldNotifyListeners: false);

      await updateEstimate(
        shouldNotifyListeners: false,
        reversed: reversed,
      );

      debugPrint(
          "_updated FROM: _from=${_from!.ticker} _to=${_to!.ticker} _fromAmount=$fromAmount _toAmount=$toAmount rate:$rate for: $exchange");
      if (shouldNotifyListeners) {
        notifyListeners();
      }
    } catch (e, s) {
      Logging.instance.log("$e\n$s", level: LogLevel.Error);
    }
  }

  Future<void> updateMarket(
    FixedRateMarket? market,
    bool shouldNotifyListeners,
  ) async {
    _market = market;

    if (_market == null) {
      fromAmount = null;
      toAmount = null;
    } else {
      if (fromAmount != null) {
        if (fromAmount! <= Decimal.zero) {
          toAmount = Decimal.zero;
        } else {
          await updateRanges(shouldNotifyListeners: false);
          await updateEstimate(
            shouldNotifyListeners: false,
            reversed: reversed,
          );
        }
      }
    }

    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  void _onExchangeRateTypeChanged() {
    print("_onExchangeRateTypeChanged");
  }

  void _onExchangeTypeChanged() {
    updateRanges(shouldNotifyListeners: true).then(
      (_) => updateEstimate(
        shouldNotifyListeners: true,
        reversed: reversed,
      ),
    );
  }

  Future<void> updateRanges({required bool shouldNotifyListeners}) async {
    if (exchange?.name == SimpleSwapExchange.exchangeName) {
      reversed = false;
    }
    final _fromTicker = reversed ? toTicker : fromTicker;
    final _toTicker = reversed ? fromTicker : toTicker;
    if (_fromTicker == null || _toTicker == null) {
      Logging.instance.log(
        "Tried to $runtimeType.updateRanges where (from: $_fromTicker || to: $_toTicker) for: $exchange",
        level: LogLevel.Info,
      );
      return;
    }
    final response = await exchange?.getRange(
      _fromTicker,
      _toTicker,
      exchangeType == ExchangeRateType.fixed,
    );

    if (response?.value == null) {
      Logging.instance.log(
        "Tried to $runtimeType.updateRanges for: $exchange where response: $response",
        level: LogLevel.Info,
      );
      return;
    }

    final range = response!.value!;

    minAmount = range.min;
    maxAmount = range.max;

    debugPrint(
        "updated range for: $exchange for $_fromTicker-$_toTicker: $range");

    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  Future<void> updateEstimate({
    required bool shouldNotifyListeners,
    required bool reversed,
  }) async {
    if (exchange?.name == SimpleSwapExchange.exchangeName) {
      reversed = false;
    }
    final amount = reversed ? toAmount : fromAmount;
    if (fromTicker == null ||
        toTicker == null ||
        amount == null ||
        amount <= Decimal.zero) {
      Logging.instance.log(
        "Tried to $runtimeType.updateEstimate for: $exchange where (from: $fromTicker || to: $toTicker || amount: $amount)",
        level: LogLevel.Info,
      );
      return;
    }
    final response = await exchange?.getEstimate(
      fromTicker!,
      toTicker!,
      amount,
      exchangeType == ExchangeRateType.fixed,
      reversed,
    );

    if (response?.value == null) {
      Logging.instance.log(
        "Tried to $runtimeType.updateEstimate for: $exchange where response: $response",
        level: LogLevel.Info,
      );
      return;
    }

    estimate = response!.value!;

    if (reversed) {
      fromAmount = estimate!.estimatedAmount;
    } else {
      toAmount = estimate!.estimatedAmount;
    }

    rate = (toAmount! / fromAmount!).toDecimal(scaleOnInfinitePrecision: 12);

    debugPrint(
        "updated estimate for: $exchange for $fromTicker-$toTicker: $estimate");

    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  void setOnError({
    required void Function(String)? onError,
    bool shouldNotifyListeners = false,
  }) {
    _onError = onError;
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  Future<void> swap({FixedRateMarket? market}) async {
    final Decimal? newToAmount = fromAmount;
    final Decimal? newFromAmount = toAmount;

    fromAmount = newFromAmount;
    toAmount = newToAmount;

    minAmount = null;
    maxAmount = null;

    switch (exchangeType) {
      case ExchangeRateType.estimated:
        final Currency? newTo = from;
        final Currency? newFrom = to;

        _to = newTo;
        _from = newFrom;

        await updateRanges(shouldNotifyListeners: false);

        await updateEstimate(
          shouldNotifyListeners: false,
          reversed: reversed,
        );
        break;
      case ExchangeRateType.fixed:
        await updateMarket(market, false);
        break;
    }

    notifyListeners();
  }
}
