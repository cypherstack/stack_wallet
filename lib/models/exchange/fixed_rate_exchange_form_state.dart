import 'package:decimal/decimal.dart';
import 'package:flutter/cupertino.dart';
import 'package:stackwallet/models/exchange/change_now/fixed_rate_market.dart';

class FixedRateExchangeFormState extends ChangeNotifier {
  Decimal? _fromAmount;
  Decimal? _toAmount;

  FixedRateMarket? _market;

  FixedRateMarket? get market => _market;

  Future<void> swap(FixedRateMarket reverseFixedRateMarket) async {
    final Decimal? tmp = _fromAmount;
    _fromAmount = _toAmount;
    _toAmount = tmp;

    await updateMarket(reverseFixedRateMarket, true);
  }

  String get fromAmountString =>
      _fromAmount == null ? "-" : _fromAmount!.toStringAsFixed(8);
  String get toAmountString =>
      _toAmount == null ? "-" : _toAmount!.toStringAsFixed(8);

  Future<void> updateMarket(
    FixedRateMarket? market,
    bool shouldNotifyListeners,
  ) async {
    _market = market;

    if (_market == null) {
      _fromAmount = null;
      _toAmount = null;
    } else {
      if (_fromAmount != null) {
        if (_fromAmount! <= Decimal.zero) {
          _toAmount = Decimal.zero;
        } else {
          _toAmount = (_fromAmount! * _market!.rate) - _market!.minerFee;
        }
      }
    }

    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  String get rateDisplayString {
    if (_market == null) {
      return "N/A";
    } else {
      return "1 ${_market!.from.toUpperCase()} ~${_market!.rate.toStringAsFixed(8)} ${_market!.to.toUpperCase()}";
    }
  }

  bool get canExchange {
    return _market != null &&
        _fromAmount != null &&
        _toAmount != null &&
        sendAmountWarning.isEmpty;
  }

  String get sendAmountWarning {
    if (_market != null && _fromAmount != null) {
      if (_fromAmount! < _market!.min) {
        return "Minimum amount ${_market!.min.toString()} ${_market!.from.toUpperCase()}";
      } else if (_fromAmount! > _market!.max) {
        return "Maximum amount ${_market!.max.toString()} ${_market!.from.toUpperCase()}";
      }
    }

    return "";
  }

  Future<void> setToAmountAndCalculateFromAmount(
    Decimal newToAmount,
    bool shouldNotifyListeners,
  ) async {
    if (_market != null) {
      _fromAmount = (newToAmount / _market!.rate)
              .toDecimal(scaleOnInfinitePrecision: 12) +
          _market!.minerFee;
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
    if (_market != null) {
      _toAmount = (newFromAmount * _market!.rate) - _market!.minerFee;
    }

    _fromAmount = newFromAmount;
    if (shouldNotifyListeners) {
      notifyListeners();
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
