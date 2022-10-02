import 'package:decimal/decimal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stackwallet/models/exchange/response_objects/currency.dart';
import 'package:stackwallet/services/change_now/change_now.dart';
import 'package:stackwallet/utilities/logger.dart';

class EstimatedRateExchangeFormState extends ChangeNotifier {
  /// used in testing to inject mock
  ChangeNow? cnTesting;

  Decimal? _fromAmount;
  Decimal? _toAmount;

  Decimal? _minFromAmount;
  Decimal? _minToAmount;

  Decimal? rate;

  Currency? _from;
  Currency? _to;

  void Function(String)? _onError;

  Currency? get from => _from;
  Currency? get to => _to;

  String get fromAmountString =>
      _fromAmount == null ? "" : _fromAmount!.toStringAsFixed(8);
  String get toAmountString =>
      _toAmount == null ? "" : _toAmount!.toStringAsFixed(8);

  String get rateDisplayString {
    if (rate == null || from == null || to == null) {
      return "N/A";
    } else {
      return "1 ${from!.ticker.toUpperCase()} ~${rate!.toStringAsFixed(8)} ${to!.ticker.toUpperCase()}";
    }
  }

  bool get canExchange {
    return _fromAmount != null &&
        _fromAmount != Decimal.zero &&
        _toAmount != null &&
        rate != null &&
        minimumSendWarning.isEmpty;
  }

  String get minimumSendWarning {
    if (_from != null &&
        _fromAmount != null &&
        _minFromAmount != null &&
        _fromAmount! < _minFromAmount!) {
      return "Minimum amount ${_minFromAmount!.toString()} ${from!.ticker.toUpperCase()}";
    }

    return "";
  }

  Future<void> init(Currency? from, Currency? to) async {
    _from = from;
    _to = to;
  }

  void clearAmounts(bool shouldNotifyListeners) {
    _fromAmount = null;
    _toAmount = null;
    _minFromAmount = null;
    _minToAmount = null;
    rate = null;

    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  Future<void> swap() async {
    final Decimal? newToAmount = _fromAmount;
    final Decimal? newFromAmount = _toAmount;

    final Decimal? newMinFromAmount = _minToAmount;
    final Decimal? newMinToAmount = _minFromAmount;

    final Currency? newTo = from;
    final Currency? newFrom = to;

    _fromAmount = newFromAmount;
    _toAmount = newToAmount;

    _minToAmount = newMinToAmount;
    _minFromAmount = newMinFromAmount;

    // rate = newRate;

    _to = newTo;
    _from = newFrom;

    await _updateMinFromAmount(shouldNotifyListeners: false);

    await updateRate();

    notifyListeners();
  }

  Future<void> updateTo(Currency to, bool shouldNotifyListeners) async {
    try {
      _to = to;
      if (_from == null) {
        rate = null;
        notifyListeners();
        return;
      }

      await _updateMinFromAmount(shouldNotifyListeners: shouldNotifyListeners);

      await updateRate(shouldNotifyListeners: shouldNotifyListeners);

      debugPrint(
          "_updated TO: _from=${_from!.ticker} _to=${_to!.ticker} _fromAmount=$_fromAmount _toAmount=$_toAmount rate:$rate");

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

      await _updateMinFromAmount(shouldNotifyListeners: shouldNotifyListeners);

      await updateRate(shouldNotifyListeners: shouldNotifyListeners);

      debugPrint(
          "_updated FROM: _from=${_from!.ticker} _to=${_to!.ticker} _fromAmount=$_fromAmount _toAmount=$_toAmount rate:$rate");
      if (shouldNotifyListeners) {
        notifyListeners();
      }
    } catch (e, s) {
      Logging.instance.log("$e\n$s", level: LogLevel.Error);
    }
  }

  Future<void> _updateMinFromAmount(
      {required bool shouldNotifyListeners}) async {
    _minFromAmount = await getStandardMinExchangeAmount(from: from!, to: to!);
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  // Future<void> setToAmountAndCalculateFromAmount(
  //   Decimal newToAmount,
  //   bool shouldNotifyListeners,
  // ) async {
  //   if (newToAmount == Decimal.zero) {
  //     _fromAmount = Decimal.zero;
  //   }
  //
  //   _toAmount = newToAmount;
  //   await updateRate();
  //   if (shouldNotifyListeners) {
  //     notifyListeners();
  //   }
  // }

  Future<void> setFromAmountAndCalculateToAmount(
    Decimal newFromAmount,
    bool shouldNotifyListeners,
  ) async {
    if (newFromAmount == Decimal.zero) {
      _toAmount = Decimal.zero;
    }

    _fromAmount = newFromAmount;
    await updateRate(shouldNotifyListeners: shouldNotifyListeners);

    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  Future<Decimal?> getStandardEstimatedToAmount({
    required Decimal fromAmount,
    required Currency from,
    required Currency to,
  }) async {
    final response =
        await (cnTesting ?? ChangeNow.instance).getEstimatedExchangeAmount(
      fromTicker: from.ticker,
      toTicker: to.ticker,
      fromAmount: fromAmount,
    );

    if (response.value != null) {
      return response.value!.estimatedAmount;
    } else {
      _onError?.call(
          "Failed to fetch estimated amount: ${response.exception?.toString()}");
      return null;
    }
  }

  // Future<Decimal?> getStandardEstimatedFromAmount({
  //   required Decimal toAmount,
  //   required Currency from,
  //   required Currency to,
  // }) async {
  //   final response = await (cnTesting ?? ChangeNow.instance)
  //       .getEstimatedExchangeAmount(
  //           fromTicker: from.ticker,
  //           toTicker: to.ticker,
  //       fromAmount: toAmount, );
  //
  //   if (response.value != null) {
  //     return response.value!.fromAmount;
  //   } else {
  //     _onError?.call(
  //         "Failed to fetch estimated amount: ${response.exception?.toString()}");
  //     return null;
  //   }
  // }

  Future<Decimal?> getStandardMinExchangeAmount({
    required Currency from,
    required Currency to,
  }) async {
    final response = await (cnTesting ?? ChangeNow.instance)
        .getMinimalExchangeAmount(fromTicker: from.ticker, toTicker: to.ticker);

    if (response.value != null) {
      return response.value!;
    } else {
      _onError?.call(
          "Could not update minimal exchange amounts: ${response.exception?.toString()}");
      return null;
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

  Future<void> updateRate({bool shouldNotifyListeners = false}) async {
    rate = null;
    final amount = _fromAmount;
    final minAmount = _minFromAmount;
    if (amount != null && amount > Decimal.zero) {
      Decimal? amt;
      if (minAmount != null) {
        if (minAmount <= amount) {
          amt = await getStandardEstimatedToAmount(
              fromAmount: amount, from: _from!, to: _to!);
          if (amt != null) {
            rate = (amt / amount).toDecimal(scaleOnInfinitePrecision: 12);
          }
        }
      }
      if (rate != null && amt != null) {
        _toAmount = amt;
      }
    }
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }
}
