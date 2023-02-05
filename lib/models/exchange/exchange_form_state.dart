// import 'package:decimal/decimal.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:stackwallet/models/exchange/response_objects/currency.dart';
// import 'package:stackwallet/models/exchange/response_objects/estimate.dart';
// import 'package:stackwallet/models/exchange/response_objects/fixed_rate_market.dart';
// import 'package:stackwallet/pages/exchange_view/sub_widgets/exchange_rate_sheet.dart';
// import 'package:stackwallet/services/exchange/change_now/change_now_exchange.dart';
// import 'package:stackwallet/services/exchange/exchange.dart';
// // import 'package:stackwallet/services/exchange/simpleswap/simpleswap_exchange.dart';
// import 'package:stackwallet/utilities/logger.dart';
//
// class ExchangeFormState extends ChangeNotifier {
//   Exchange? _exchange;
//   Exchange? get exchange => _exchange;
//   set exchange(Exchange? value) {
//     _exchange = value;
//     _onExchangeTypeChanged();
//   }
//
//   ExchangeRateType _exchangeType = ExchangeRateType.estimated;
//   ExchangeRateType get exchangeType => _exchangeType;
//   set exchangeType(ExchangeRateType value) {
//     _exchangeType = value;
//     _onExchangeRateTypeChanged();
//   }
//
//   bool reversed = false;
//
//   Decimal? fromAmount;
//   Decimal? toAmount;
//
//   Decimal? minAmount;
//   Decimal? maxAmount;
//
//   Decimal? rate;
//   Estimate? estimate;
//
//   FixedRateMarket? _market;
//   FixedRateMarket? get market => _market;
//
//   Currency? _from;
//   Currency? _to;
//
//   @override
//   String toString() {
//     return 'ExchangeFormState: {_exchange: $_exchange, _exchangeType: $_exchangeType, reversed: $reversed, fromAmount: $fromAmount, toAmount: $toAmount, minAmount: $minAmount, maxAmount: $maxAmount, rate: $rate, estimate: $estimate, _market: $_market, _from: $_from, _to: $_to, _onError: $_onError}';
//   }
//
//   String? get fromTicker {
//     switch (exchangeType) {
//       case ExchangeRateType.estimated:
//         return _from?.ticker;
//       case ExchangeRateType.fixed:
//         switch (exchange?.name) {
//           // case SimpleSwapExchange.exchangeName:
//           //   return _from?.ticker;
//           case ChangeNowExchange.exchangeName:
//             return market?.from;
//           default:
//             return null;
//         }
//     }
//   }
//
//   String? get toTicker {
//     switch (exchangeType) {
//       case ExchangeRateType.estimated:
//         return _to?.ticker;
//       case ExchangeRateType.fixed:
//         switch (exchange?.name) {
//           // case SimpleSwapExchange.exchangeName:
//           //   return _to?.ticker;
//           case ChangeNowExchange.exchangeName:
//             return market?.to;
//           default:
//             return null;
//         }
//     }
//   }
//
//   void Function(String)? _onError;
//
//   Currency? get from => _from;
//   Currency? get to => _to;
//
//   void setCurrencies(Currency from, Currency to) {
//     _from = from;
//     _to = to;
//   }
//
//   String get warning {
//     if (reversed) {
//       if (toTicker != null && toAmount != null) {
//         if (minAmount != null &&
//             toAmount! < minAmount! &&
//             toAmount! > Decimal.zero) {
//           return "Minimum amount ${minAmount!.toString()} ${toTicker!.toUpperCase()}";
//         } else if (maxAmount != null && toAmount! > maxAmount!) {
//           return "Maximum amount ${maxAmount!.toString()} ${toTicker!.toUpperCase()}";
//         }
//       }
//     } else {
//       if (fromTicker != null && fromAmount != null) {
//         if (minAmount != null &&
//             fromAmount! < minAmount! &&
//             fromAmount! > Decimal.zero) {
//           return "Minimum amount ${minAmount!.toString()} ${fromTicker!.toUpperCase()}";
//         } else if (maxAmount != null && fromAmount! > maxAmount!) {
//           return "Maximum amount ${maxAmount!.toString()} ${fromTicker!.toUpperCase()}";
//         }
//       }
//     }
//
//     return "";
//   }
//
//   String get fromAmountString => fromAmount?.toStringAsFixed(8) ?? "";
//   String get toAmountString => toAmount?.toStringAsFixed(8) ?? "";
//
//   bool get canExchange {
//     if (exchange?.name == ChangeNowExchange.exchangeName &&
//         exchangeType == ExchangeRateType.fixed) {
//       return _market != null &&
//           fromAmount != null &&
//           toAmount != null &&
//           warning.isEmpty;
//     } else {
//       return fromAmount != null &&
//           fromAmount != Decimal.zero &&
//           toAmount != null &&
//           rate != null &&
//           warning.isEmpty;
//     }
//   }
//
//   void clearAmounts(bool shouldNotifyListeners) {
//     fromAmount = null;
//     toAmount = null;
//     minAmount = null;
//     maxAmount = null;
//     rate = null;
//
//     if (shouldNotifyListeners) {
//       notifyListeners();
//     }
//   }
//
//   Future<void> setFromAmountAndCalculateToAmount(
//     Decimal newFromAmount,
//     bool shouldNotifyListeners,
//   ) async {
//     if (newFromAmount == Decimal.zero) {
//       toAmount = Decimal.zero;
//     }
//
//     fromAmount = newFromAmount;
//     reversed = false;
//
//     await updateRanges(shouldNotifyListeners: false);
//
//     await updateEstimate(
//       shouldNotifyListeners: false,
//       reversed: reversed,
//     );
//
//     if (shouldNotifyListeners) {
//       notifyListeners();
//     }
//   }
//
//   Future<void> setToAmountAndCalculateFromAmount(
//     Decimal newToAmount,
//     bool shouldNotifyListeners,
//   ) async {
//     if (newToAmount == Decimal.zero) {
//       fromAmount = Decimal.zero;
//     }
//
//     toAmount = newToAmount;
//     reversed = true;
//
//     await updateRanges(shouldNotifyListeners: false);
//
//     await updateEstimate(
//       shouldNotifyListeners: false,
//       reversed: reversed,
//     );
//
//     if (shouldNotifyListeners) {
//       notifyListeners();
//     }
//   }
//
//   Future<void> updateTo(Currency to, bool shouldNotifyListeners) async {
//     try {
//       _to = to;
//       if (_from == null) {
//         rate = null;
//         notifyListeners();
//         return;
//       }
//
//       await updateRanges(shouldNotifyListeners: false);
//
//       await updateEstimate(
//         shouldNotifyListeners: false,
//         reversed: reversed,
//       );
//
//       //todo: check if print needed
//       // debugPrint(
//       //     "_updated TO: _from=${_from!.ticker} _to=${_to!.ticker} _fromAmount=$fromAmount _toAmount=$toAmount rate:$rate for: $exchange");
//
//       if (shouldNotifyListeners) {
//         notifyListeners();
//       }
//     } catch (e, s) {
//       Logging.instance.log("$e\n$s", level: LogLevel.Error);
//     }
//   }
//
//   Future<void> updateFrom(Currency from, bool shouldNotifyListeners) async {
//     try {
//       _from = from;
//
//       if (_to == null) {
//         rate = null;
//         notifyListeners();
//         return;
//       }
//
//       await updateRanges(shouldNotifyListeners: false);
//
//       await updateEstimate(
//         shouldNotifyListeners: false,
//         reversed: reversed,
//       );
//
//       //todo: check if print needed
//       // debugPrint(
//       //     "_updated FROM: _from=${_from!.ticker} _to=${_to!.ticker} _fromAmount=$fromAmount _toAmount=$toAmount rate:$rate for: $exchange");
//       if (shouldNotifyListeners) {
//         notifyListeners();
//       }
//     } catch (e, s) {
//       Logging.instance.log("$e\n$s", level: LogLevel.Error);
//     }
//   }
//
//   Future<void> updateMarket(
//     FixedRateMarket? market,
//     bool shouldNotifyListeners,
//   ) async {
//     _market = market;
//
//     if (_market == null) {
//       fromAmount = null;
//       toAmount = null;
//     } else {
//       if (fromAmount != null) {
//         if (fromAmount! <= Decimal.zero) {
//           toAmount = Decimal.zero;
//         } else {
//           await updateRanges(shouldNotifyListeners: false);
//           await updateEstimate(
//             shouldNotifyListeners: false,
//             reversed: reversed,
//           );
//         }
//       }
//     }
//
//     if (shouldNotifyListeners) {
//       notifyListeners();
//     }
//   }
//
//   void _onExchangeRateTypeChanged() {
//     print("_onExchangeRateTypeChanged");
//     updateRanges(shouldNotifyListeners: true).then(
//       (_) => updateEstimate(
//         shouldNotifyListeners: true,
//         reversed: reversed,
//       ),
//     );
//   }
//
//   void _onExchangeTypeChanged() {
//     updateRanges(shouldNotifyListeners: true).then(
//       (_) => updateEstimate(
//         shouldNotifyListeners: true,
//         reversed: reversed,
//       ),
//     );
//   }
//
//   Future<void> updateRanges({required bool shouldNotifyListeners}) async {
//     // if (exchange?.name == SimpleSwapExchange.exchangeName) {
//     //   reversed = false;
//     // }
//     final _fromTicker = reversed ? toTicker : fromTicker;
//     final _toTicker = reversed ? fromTicker : toTicker;
//     if (_fromTicker == null || _toTicker == null) {
//       Logging.instance.log(
//         "Tried to $runtimeType.updateRanges where (from: $_fromTicker || to: $_toTicker) for: $exchange",
//         level: LogLevel.Info,
//       );
//       return;
//     }
//     final response = await exchange?.getRange(
//       _fromTicker,
//       _toTicker,
//       exchangeType == ExchangeRateType.fixed,
//     );
//
//     if (response?.value == null) {
//       Logging.instance.log(
//         "Tried to $runtimeType.updateRanges for: $exchange where response: $response",
//         level: LogLevel.Info,
//       );
//       return;
//     }
//
//     final range = response!.value!;
//
//     minAmount = range.min;
//     maxAmount = range.max;
//
//     //todo: check if print needed
//     // debugPrint(
//     //     "updated range for: $exchange for $_fromTicker-$_toTicker: $range");
//
//     if (shouldNotifyListeners) {
//       notifyListeners();
//     }
//   }
//
//   Future<void> updateEstimate({
//     required bool shouldNotifyListeners,
//     required bool reversed,
//   }) async {
//     // if (exchange?.name == SimpleSwapExchange.exchangeName) {
//     //   reversed = false;
//     // }
//     final amount = reversed ? toAmount : fromAmount;
//     if (fromTicker == null ||
//         toTicker == null ||
//         amount == null ||
//         amount <= Decimal.zero) {
//       Logging.instance.log(
//         "Tried to $runtimeType.updateEstimate for: $exchange where (from: $fromTicker || to: $toTicker || amount: $amount)",
//         level: LogLevel.Info,
//       );
//       return;
//     }
//     final response = await exchange?.getEstimate(
//       fromTicker!,
//       toTicker!,
//       amount,
//       exchangeType == ExchangeRateType.fixed,
//       reversed,
//     );
//
//     if (response?.value == null) {
//       Logging.instance.log(
//         "Tried to $runtimeType.updateEstimate for: $exchange where response: $response",
//         level: LogLevel.Info,
//       );
//       return;
//     }
//
//     estimate = response!.value!;
//
//     if (reversed) {
//       fromAmount = estimate!.estimatedAmount;
//     } else {
//       toAmount = estimate!.estimatedAmount;
//     }
//
//     rate = (toAmount! / fromAmount!).toDecimal(scaleOnInfinitePrecision: 12);
//
//     //todo: check if print needed
//     // debugPrint(
//     //     "updated estimate for: $exchange for $fromTicker-$toTicker: $estimate");
//
//     if (shouldNotifyListeners) {
//       notifyListeners();
//     }
//   }
//
//   void setOnError({
//     required void Function(String)? onError,
//     bool shouldNotifyListeners = false,
//   }) {
//     _onError = onError;
//     if (shouldNotifyListeners) {
//       notifyListeners();
//     }
//   }
//
//   Future<void> swap({FixedRateMarket? market}) async {
//     final Decimal? newToAmount = fromAmount;
//     final Decimal? newFromAmount = toAmount;
//
//     fromAmount = newFromAmount;
//     toAmount = newToAmount;
//
//     minAmount = null;
//     maxAmount = null;
//
//     if (exchangeType == ExchangeRateType.fixed &&
//         exchange?.name == ChangeNowExchange.exchangeName) {
//       await updateMarket(market, false);
//     } else {
//       final Currency? newTo = from;
//       final Currency? newFrom = to;
//
//       _to = newTo;
//       _from = newFrom;
//
//       await updateRanges(shouldNotifyListeners: false);
//
//       await updateEstimate(
//         shouldNotifyListeners: false,
//         reversed: reversed,
//       );
//     }
//
//     notifyListeners();
//   }
// }

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:stackwallet/models/exchange/response_objects/estimate.dart';
import 'package:stackwallet/models/isar/exchange_cache/currency.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/exchange_rate_sheet.dart';
import 'package:stackwallet/services/exchange/exchange.dart';
import 'package:stackwallet/utilities/logger.dart';

class ExchangeFormState extends ChangeNotifier {
  ExchangeFormState(this.exchangeRateType);
  final ExchangeRateType exchangeRateType;

  Exchange? _exchange;
  Exchange get exchange => _exchange ??= Exchange.defaultExchange;
  set exchange(Exchange value) {
    _exchange = value;
    _updateRangesAndEstimate(
      shouldNotifyListeners: true,
    );
  }

  Estimate? _estimate;
  Estimate? get estimate => _estimate;

  bool _reversed = false;
  bool get reversed => _reversed;
  set reversed(bool reversed) {
    _reversed = reversed;
    //
  }

  Decimal? _rate;
  Decimal? get rate => _rate;
  // set rate(Decimal? rate) {
  //   _rate = rate;
  //   //
  // }

  Decimal? _sendAmount;
  Decimal? get sendAmount => _sendAmount;
  // set sendAmount(Decimal? sendAmount) {
  //   _sendAmount = sendAmount;
  //   //
  // }

  Decimal? _receiveAmount;
  Decimal? get receiveAmount => _receiveAmount;
  set receiveAmount(Decimal? receiveAmount) {
    _receiveAmount = receiveAmount;
    //
  }

  Currency? _sendCurrency;
  Currency? get sendCurrency => _sendCurrency;
  // set sendCurrency(Currency? sendCurrency) {
  //   _sendCurrency = sendCurrency;
  //   //
  // }

  Currency? _receiveCurrency;
  Currency? get receiveCurrency => _receiveCurrency;
  // set receiveCurrency(Currency? receiveCurrency) {
  //   _receiveCurrency = receiveCurrency;
  //   //
  // }

  Decimal? _minSendAmount;
  Decimal? get minSendAmount => _minSendAmount;
  // set minSendAmount(Decimal? minSendAmount) {
  //   _minSendAmount = minSendAmount;
  //   //
  // }

  Decimal? _minReceiveAmount;
  Decimal? get minReceiveAmount => _minReceiveAmount;
  // set minReceiveAmount(Decimal? minReceiveAmount) {
  //   _minReceiveAmount = minReceiveAmount;
  //   //
  // }

  Decimal? _maxSendAmount;
  Decimal? get maxSendAmount => _maxSendAmount;
  // set maxSendAmount(Decimal? maxSendAmount) {
  //   _maxSendAmount = maxSendAmount;
  //   //
  // }

  Decimal? _maxReceiveAmount;
  Decimal? get maxReceiveAmount => _maxReceiveAmount;
  // set maxReceiveAmount(Decimal? maxReceiveAmount) {
  //   _maxReceiveAmount = maxReceiveAmount;
  //   //
  // }

  //============================================================================
  // computed properties
  //============================================================================

  String? get fromTicker => _sendCurrency?.ticker;
  String? get toTicker => _receiveCurrency?.ticker;

  String get fromAmountString => _sendAmount?.toStringAsFixed(8) ?? "";
  String get toAmountString => _receiveAmount?.toStringAsFixed(8) ?? "";

  bool get canExchange {
    return sendCurrency != null &&
        receiveCurrency != null &&
        sendAmount != null &&
        sendAmount! >= Decimal.zero &&
        receiveAmount != null &&
        rate != null &&
        rate! >= Decimal.zero &&
        warning.isEmpty;
  }

  String get warning {
    if (reversed) {
      if (_receiveCurrency != null && _receiveAmount != null) {
        if (_minReceiveAmount != null &&
            _receiveAmount! < _minReceiveAmount! &&
            _receiveAmount! > Decimal.zero) {
          return "Minimum amount ${_minReceiveAmount!.toString()} ${_receiveCurrency!.ticker.toUpperCase()}";
        } else if (_maxReceiveAmount != null &&
            _receiveAmount! > _maxReceiveAmount!) {
          return "Maximum amount ${_maxReceiveAmount!.toString()} ${_receiveCurrency!.ticker.toUpperCase()}";
        }
      }
    } else {
      if (_sendCurrency != null && _sendAmount != null) {
        if (_minSendAmount != null &&
            _sendAmount! < _minSendAmount! &&
            _sendAmount! > Decimal.zero) {
          return "Minimum amount ${_minSendAmount!.toString()} ${_sendCurrency!.ticker.toUpperCase()}";
        } else if (_maxSendAmount != null && _sendAmount! > _maxSendAmount!) {
          return "Maximum amount ${_maxSendAmount!.toString()} ${_sendCurrency!.ticker.toUpperCase()}";
        }
      }
    }

    return "";
  }

  //============================================================================
  // public state updaters
  //============================================================================

  void setCurrencies(Currency from, Currency to) {
    _sendCurrency = from;
    _receiveCurrency = to;
  }

  void reset({
    required bool shouldNotifyListeners,
  }) {
    _exchange = null;
    _reversed = false;
    _rate = null;
    _sendAmount = null;
    _receiveAmount = null;
    _sendCurrency = null;
    _receiveCurrency = null;
    _minSendAmount = null;
    _minReceiveAmount = null;
    _maxSendAmount = null;
    _maxReceiveAmount = null;

    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  Future<void> setSendAmountAndCalculateReceiveAmount(
    Decimal? newSendAmount,
    bool shouldNotifyListeners,
  ) async {
    if (newSendAmount == null) {
      // todo: check if this breaks things and stuff
      _receiveAmount = null;
      _sendAmount = null;
    } else {
      if (newSendAmount <= Decimal.zero) {
        _receiveAmount = Decimal.zero;
      }

      _sendAmount = newSendAmount;
      _reversed = false;

      await _updateRangesAndEstimate(
        shouldNotifyListeners: false,
      );
    }

    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  Future<void> setToAmountAndCalculateFromAmount(
    Decimal? newReceiveAmount,
    bool shouldNotifyListeners,
  ) async {
    if (newReceiveAmount == null) {
      // todo: check if this breaks things and stuff
      _receiveAmount = null;
      _sendAmount = null;
    } else {
      if (newReceiveAmount <= Decimal.zero) {
        _sendAmount = Decimal.zero;
      }

      _receiveAmount = newReceiveAmount;
      _reversed = true;

      await _updateRangesAndEstimate(
        shouldNotifyListeners: false,
      );
    }

    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  Future<void> updateSendCurrency(
    Currency sendCurrency,
    bool shouldNotifyListeners,
  ) async {
    try {
      _sendCurrency = sendCurrency;
      if (_receiveCurrency == null) {
        _rate = null;
      } else {
        await _updateRangesAndEstimate(
          shouldNotifyListeners: false,
        );
      }
      if (shouldNotifyListeners) {
        notifyListeners();
      }
    } catch (e, s) {
      Logging.instance.log("$e\n$s", level: LogLevel.Error);
    }
  }

  Future<void> updateReceivingCurrency(
    Currency receiveCurrency,
    bool shouldNotifyListeners,
  ) async {
    try {
      _receiveCurrency = receiveCurrency;

      if (_sendCurrency == null) {
        _rate = null;
      } else {
        await _updateRangesAndEstimate(
          shouldNotifyListeners: false,
        );
      }
      if (shouldNotifyListeners) {
        notifyListeners();
      }
    } catch (e, s) {
      Logging.instance.log("$e\n$s", level: LogLevel.Error);
    }
  }

  Future<void> swap({
    required bool shouldNotifyListeners,
  }) async {
    final Decimal? temp = sendAmount;
    _sendAmount = receiveAmount;
    _receiveAmount = temp;

    _minSendAmount = null;
    _maxSendAmount = null;
    _minReceiveAmount = null;
    _maxReceiveAmount = null;

    final Currency? tmp = sendCurrency;
    _sendCurrency = receiveCurrency;
    _receiveCurrency = tmp;

    await _updateRangesAndEstimate(
      shouldNotifyListeners: false,
    );
  }

  //============================================================================
  // private state updaters
  //============================================================================

  Future<void> _updateRangesAndEstimate({
    required bool shouldNotifyListeners,
  }) async {
    try {
      await _updateRanges(shouldNotifyListeners: false);
      await _updateEstimate(shouldNotifyListeners: false);
      if (shouldNotifyListeners) {
        notifyListeners();
      }
    } catch (_) {
      //
    }
  }

  Future<void> _updateRanges({
    required bool shouldNotifyListeners,
  }) async {
    // if (exchange?.name == SimpleSwapExchange.exchangeName) {
    //   reversed = false;
    // }
    final _send = sendCurrency;
    final _receive = receiveCurrency;
    if (_send == null || _receive == null) {
      Logging.instance.log(
        "Tried to $runtimeType.updateRanges where ( $_send || $_receive) for: $exchange",
        level: LogLevel.Info,
      );
      return;
    }
    final response = await exchange.getRange(
      _send.ticker,
      _receive.ticker,
      exchangeRateType == ExchangeRateType.fixed,
    );

    if (response.value == null) {
      Logging.instance.log(
        "Tried to $runtimeType.updateRanges for: $exchange where response: $response",
        level: LogLevel.Info,
      );
      return;
    }
    final responseReversed = await exchange.getRange(
      _receive.ticker,
      _send.ticker,
      exchangeRateType == ExchangeRateType.fixed,
    );

    if (responseReversed.value == null) {
      Logging.instance.log(
        "Tried to $runtimeType.updateRanges for: $exchange where response: $responseReversed",
        level: LogLevel.Info,
      );
      return;
    }

    final range = response.value!;
    final rangeReversed = responseReversed.value!;

    _minSendAmount = range.min;
    _maxSendAmount = range.max;
    _minReceiveAmount = rangeReversed.min;
    _maxReceiveAmount = rangeReversed.max;

    //todo: check if print needed
    // debugPrint(
    //     "updated range for: $exchange for $_fromTicker-$_toTicker: $range");

    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  Future<void> _updateEstimate({
    required bool shouldNotifyListeners,
  }) async {
    // if (exchange?.name == SimpleSwapExchange.exchangeName) {
    //   reversed = false;
    // }
    final amount = reversed ? receiveAmount : sendAmount;
    if (sendCurrency == null ||
        receiveCurrency == null ||
        amount == null ||
        amount <= Decimal.zero) {
      Logging.instance.log(
        "Tried to $runtimeType.updateEstimate for: $exchange where (from: $sendCurrency || to: $receiveCurrency || amount: $amount)",
        level: LogLevel.Info,
      );
      return;
    }
    final response = await exchange.getEstimate(
      sendCurrency!.ticker,
      receiveCurrency!.ticker,
      amount,
      exchangeRateType == ExchangeRateType.fixed,
      reversed,
    );

    if (response.value == null) {
      Logging.instance.log(
        "Tried to $runtimeType.updateEstimate for: $exchange where response: $response",
        level: LogLevel.Info,
      );
      return;
    }

    _estimate = response.value!;

    if (reversed) {
      _sendAmount = _estimate!.estimatedAmount;
    } else {
      _receiveAmount = _estimate!.estimatedAmount;
    }

    _rate =
        (receiveAmount! / sendAmount!).toDecimal(scaleOnInfinitePrecision: 12);

    //todo: check if print needed
    // debugPrint(
    //     "updated estimate for: $exchange for $fromTicker-$toTicker: $estimate");

    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }
}
