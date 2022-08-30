import 'package:decimal/decimal.dart';
import 'package:flutter/cupertino.dart';
import 'package:stackwallet/models/exchange/change_now/currency.dart';
import 'package:stackwallet/services/change_now/change_now.dart';
import 'package:stackwallet/utilities/logger.dart';

class ExchangeFormState extends ChangeNotifier {
  Decimal? _fromAmount;
  Decimal? _toAmount;

  Decimal? _minFromAmount;
  Decimal? _minToAmount;

  Decimal? rate;

  Currency? _from;
  Currency? _to;

  Currency? get from => _from;
  Currency? get to => _to;

  Future<void> init(Currency? from, Currency? to) async {
    _from = from;
    _to = to;
  }

  Future<void> swap() async {
    final Decimal? newToAmount = _fromAmount;
    final Decimal? newFromAmount = _toAmount;

    final Decimal? newMinFromAmount = _minToAmount;
    final Decimal? newMinToAmount = _minFromAmount;

    final Decimal? newRate = rate == null
        ? rate
        : (Decimal.one / rate!).toDecimal(scaleOnInfinitePrecision: 12);

    final Currency? newTo = from;
    final Currency? newFrom = to;

    _fromAmount = newFromAmount;
    _toAmount = newToAmount;

    _minToAmount = newMinToAmount;
    _minFromAmount = newMinFromAmount;

    rate = newRate;

    _to = newTo;
    _from = newFrom;

    notifyListeners();
  }

  String get fromAmountString =>
      _fromAmount == null ? "-" : _fromAmount!.toStringAsFixed(8);
  String get toAmountString =>
      _toAmount == null ? "-" : _toAmount!.toStringAsFixed(8);

  Future<void> updateTo(Currency to, bool shouldNotifyListeners) async {
    try {
      _to = to;
      if (_from == null) {
        rate = null;
        notifyListeners();
        return;
      }

      await _updateMinFromAmount(shouldNotifyListeners: shouldNotifyListeners);
      // await _updateMinToAmount(shouldNotifyListeners: shouldNotifyListeners);

      rate = null;

      if (_fromAmount != null) {
        Decimal? amt;
        if (_minFromAmount != null) {
          if (_minFromAmount! > _fromAmount!) {
            amt = await getStandardEstimatedToAmount(
                fromAmount: _minFromAmount!, from: _from!, to: _to!);
            if (amt != null) {
              rate = (amt / _minFromAmount!)
                  .toDecimal(scaleOnInfinitePrecision: 12);
            }
            debugPrint("A");
          } else {
            amt = await getStandardEstimatedToAmount(
                fromAmount: _fromAmount!, from: _from!, to: _to!);
            if (amt != null) {
              rate =
                  (amt / _fromAmount!).toDecimal(scaleOnInfinitePrecision: 12);
            }
            debugPrint("B");
          }
        }
        if (rate != null) {
          _toAmount = (_fromAmount! * rate!);
        }
        debugPrint("C");
      } else {
        if (_minFromAmount != null) {
          Decimal? amt = await getStandardEstimatedToAmount(
              fromAmount: _minFromAmount!, from: _from!, to: _to!);
          if (amt != null) {
            rate =
                (amt / _minFromAmount!).toDecimal(scaleOnInfinitePrecision: 12);
          }
          debugPrint("D");
        }
      }

      debugPrint(
          "_updated TO: _from=${_from!.ticker} _to=${_to!.ticker} _fromAmount=$_fromAmount _toAmount=$_toAmount rate:$rate");

      if (shouldNotifyListeners) {
        notifyListeners();
      }
    } catch (e, s) {
      Logging.instance.log("$e\n$s", level: LogLevel.Fatal);
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

      rate = null;

      if (_fromAmount != null) {
        Decimal? amt;
        if (_minFromAmount != null) {
          if (_minFromAmount! > _fromAmount!) {
            amt = await getStandardEstimatedToAmount(
                fromAmount: _minFromAmount!, from: _from!, to: _to!);
            if (amt != null) {
              rate = (amt / _minFromAmount!)
                  .toDecimal(scaleOnInfinitePrecision: 12);
            }
          } else {
            amt = await getStandardEstimatedToAmount(
                fromAmount: _fromAmount!, from: _from!, to: _to!);
            if (amt != null) {
              rate =
                  (amt / _fromAmount!).toDecimal(scaleOnInfinitePrecision: 12);
            }
          }
        }
        if (rate != null) {
          _toAmount = (_fromAmount! * rate!);
        }
      } else {
        if (_minFromAmount != null) {
          Decimal? amt = await getStandardEstimatedToAmount(
              fromAmount: _minFromAmount!, from: _from!, to: _to!);
          if (amt != null) {
            rate =
                (amt / _minFromAmount!).toDecimal(scaleOnInfinitePrecision: 12);
          }
        }
      }

      debugPrint(
          "_updated FROM: _from=${_from!.ticker} _to=${_to!.ticker} _fromAmount=$_fromAmount _toAmount=$_toAmount rate:$rate");
      if (shouldNotifyListeners) {
        notifyListeners();
      }
    } catch (e, s) {
      Logging.instance.log("$e\n$s", level: LogLevel.Fatal);
    }
  }

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
        minimumReceiveWarning.isEmpty &&
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

  String get minimumReceiveWarning {
    // TODO not sure this is needed
    // if (_toAmount != null &&
    //     _minToAmount != null &&
    //     _toAmount! < _minToAmount!) {
    //   return "Minimum amount ${_minToAmount!.toString()} ${to.ticker.toUpperCase()}";
    // }
    return "";
  }

  // Future<void> _updateMinToAmount({required bool shouldNotifyListeners}) async {
  //   _minToAmount = await getStandardMinExchangeAmount(from: to!, to: from!);
  //   if (shouldNotifyListeners) {
  //     notifyListeners();
  //   }
  // }

  Future<void> _updateMinFromAmount(
      {required bool shouldNotifyListeners}) async {
    _minFromAmount = await getStandardMinExchangeAmount(from: from!, to: to!);
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  Future<void> setToAmountAndCalculateFromAmount(
    Decimal newToAmount,
    bool shouldNotifyListeners,
  ) async {
    // if (newToAmount == Decimal.zero) {
    //   _fromAmount = Decimal.zero;
    //   _toAmount = Decimal.zero;
    //   if (shouldNotifyListeners) {
    //     notifyListeners();
    //   }
    //   return;
    // }

    if (rate != null) {
      _fromAmount =
          (newToAmount / rate!).toDecimal(scaleOnInfinitePrecision: 12);
    }

    _toAmount = newToAmount;
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  Future<void> setFromAmountAndCalculateToAmount(
    Decimal newFromAmount,
    bool shouldNotifyListeners,
  ) async {
    // if (newFromAmount == Decimal.zero) {
    //   _fromAmount = Decimal.zero;
    //   _toAmount = Decimal.zero;
    //   if (shouldNotifyListeners) {
    //     notifyListeners();
    //   }
    //   return;
    // }

    if (rate != null) {
      _toAmount = (newFromAmount * rate!);
    }

    _fromAmount = newFromAmount;
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  Future<Decimal?> getStandardEstimatedToAmount({
    required Decimal fromAmount,
    required Currency from,
    required Currency to,
  }) async {
    final response = await ChangeNow.instance.getEstimatedExchangeAmount(
        fromTicker: from.ticker, toTicker: to.ticker, fromAmount: fromAmount);

    if (response.value != null) {
      return response.value!.estimatedAmount;
    } else {
      _onError?.call(
          "Failed to fetch estimated amount: ${response.exception?.toString()}");
      return null;
    }
  }

  Future<Decimal?> getStandardMinExchangeAmount({
    required Currency from,
    required Currency to,
  }) async {
    final response = await ChangeNow.instance
        .getMinimalExchangeAmount(fromTicker: from.ticker, toTicker: to.ticker);

    if (response.value != null) {
      return response.value!;
    } else {
      _onError?.call(
          "Could not update minimal exchange amounts: ${response.exception?.toString()}");
      return null;
    }
  }

  void Function(String)? _onError;

  void setOnError({
    required void Function(String)? onError,
    bool shouldNotifyListeners = false,
  }) {
    _onError = onError;
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }
}
