// import 'package:decimal/decimal.dart';
// import 'package:flutter/foundation.dart';
// import 'package:stackduo/models/exchange/response_objects/currency.dart';
// import 'package:stackduo/pages/exchange_view/sub_widgets/exchange_rate_sheet.dart';
// import 'package:stackduo/services/exchange/change_now/change_now_exchange.dart';
// import 'package:stackduo/services/exchange/exchange.dart';
// import 'package:stackduo/utilities/logger.dart';
//
// class ExchangeFormState extends ChangeNotifier {
//   ExchangeFormState(this.exchangeRateType);
//   final ExchangeRateType exchangeRateType;
//
//   Exchange? _exchange;
//   Exchange get exchange =>
//       _exchange ??= ChangeNowExchange(); // default to change now
//   set exchange(Exchange value) {
//     _exchange = value;
//     _updateRangesAndEstimate(
//       shouldNotifyListeners: true,
//     );
//   }
//
//   bool _reversed = false;
//   bool get reversed => _reversed;
//   // set reversed(bool reversed) {
//   //   _reversed = reversed;
//   //   //
//   // }
//
//   Decimal? _rate;
//   Decimal? get rate => _rate;
//   // set rate(Decimal? rate) {
//   //   _rate = rate;
//   //   //
//   // }
//
//   Decimal? _sendAmount;
//   Decimal? get sendAmount => _sendAmount;
//   // set sendAmount(Decimal? sendAmount) {
//   //   _sendAmount = sendAmount;
//   //   //
//   // }
//
//   Decimal? _receiveAmount;
//   Decimal? get receiveAmount => _receiveAmount;
//   // set receiveAmount(Decimal? receiveAmount) {
//   //   _receiveAmount = receiveAmount;
//   //   //
//   // }
//
//   Currency? _sendCurrency;
//   Currency? get sendCurrency => _sendCurrency;
//   // set sendCurrency(Currency? sendCurrency) {
//   //   _sendCurrency = sendCurrency;
//   //   //
//   // }
//
//   Currency? _receiveCurrency;
//   Currency? get receiveCurrency => _receiveCurrency;
//   // set receiveCurrency(Currency? receiveCurrency) {
//   //   _receiveCurrency = receiveCurrency;
//   //   //
//   // }
//
//   Decimal? _minSendAmount;
//   Decimal? get minSendAmount => _minSendAmount;
//   // set minSendAmount(Decimal? minSendAmount) {
//   //   _minSendAmount = minSendAmount;
//   //   //
//   // }
//
//   Decimal? _minReceiveAmount;
//   Decimal? get minReceiveAmount => _minReceiveAmount;
//   // set minReceiveAmount(Decimal? minReceiveAmount) {
//   //   _minReceiveAmount = minReceiveAmount;
//   //   //
//   // }
//
//   Decimal? _maxSendAmount;
//   Decimal? get maxSendAmount => _maxSendAmount;
//   // set maxSendAmount(Decimal? maxSendAmount) {
//   //   _maxSendAmount = maxSendAmount;
//   //   //
//   // }
//
//   Decimal? _maxReceiveAmount;
//   Decimal? get maxReceiveAmount => _maxReceiveAmount;
//   // set maxReceiveAmount(Decimal? maxReceiveAmount) {
//   //   _maxReceiveAmount = maxReceiveAmount;
//   //   //
//   // }
//
//   //============================================================================
//   // computed properties
//   //============================================================================
//
//   String? get fromTicker => _sendCurrency?.ticker;
//
//   String? get toTicker => _receiveCurrency?.ticker;
//
//   String get warning {
//     if (reversed) {
//       if (_receiveCurrency != null && _receiveAmount != null) {
//         if (_minReceiveAmount != null &&
//             _receiveAmount! < _minReceiveAmount! &&
//             _receiveAmount! > Decimal.zero) {
//           return "Minimum amount ${_minReceiveAmount!.toString()} ${_receiveCurrency!.ticker.toUpperCase()}";
//         } else if (_maxReceiveAmount != null &&
//             _receiveAmount! > _maxReceiveAmount!) {
//           return "Maximum amount ${_maxReceiveAmount!.toString()} ${_receiveCurrency!.ticker.toUpperCase()}";
//         }
//       }
//     } else {
//       if (_sendCurrency != null && _sendAmount != null) {
//         if (_minSendAmount != null &&
//             _sendAmount! < _minSendAmount! &&
//             _sendAmount! > Decimal.zero) {
//           return "Minimum amount ${_minSendAmount!.toString()} ${_sendCurrency!.ticker.toUpperCase()}";
//         } else if (_maxSendAmount != null && _sendAmount! > _maxSendAmount!) {
//           return "Maximum amount ${_maxSendAmount!.toString()} ${_sendCurrency!.ticker.toUpperCase()}";
//         }
//       }
//     }
//
//     return "";
//   }
//
//   //============================================================================
//   // public state updaters
//   //============================================================================
//
//   void reset(bool shouldNotifyListeners) {
//     _exchange = null;
//     _reversed = false;
//     _rate = null;
//     _sendAmount = null;
//     _receiveAmount = null;
//     _sendCurrency = null;
//     _receiveCurrency = null;
//     _minSendAmount = null;
//     _minReceiveAmount = null;
//     _maxSendAmount = null;
//     _maxReceiveAmount = null;
//
//     if (shouldNotifyListeners) {
//       notifyListeners();
//     }
//   }
//
//   Future<void> setFromAmountAndCalculateToAmount(
//     Decimal? newSendAmount,
//     bool shouldNotifyListeners,
//   ) async {
//     if (newSendAmount == null) {
//       // todo: check if this breaks things and stuff
//       _receiveAmount = null;
//       _sendAmount = null;
//     } else {
//       if (newSendAmount <= Decimal.zero) {
//         _receiveAmount = Decimal.zero;
//       }
//
//       _sendAmount = newSendAmount;
//       _reversed = false;
//
//       await _updateRangesAndEstimate(
//         shouldNotifyListeners: false,
//       );
//     }
//
//     if (shouldNotifyListeners) {
//       notifyListeners();
//     }
//   }
//
//   Future<void> setToAmountAndCalculateFromAmount(
//     Decimal? newReceiveAmount,
//     bool shouldNotifyListeners,
//   ) async {
//     if (newReceiveAmount == null) {
//       // todo: check if this breaks things and stuff
//       _receiveAmount = null;
//       _sendAmount = null;
//     } else {
//       if (newReceiveAmount <= Decimal.zero) {
//         _sendAmount = Decimal.zero;
//       }
//
//       _receiveAmount = newReceiveAmount;
//       _reversed = true;
//
//       await _updateRangesAndEstimate(
//         shouldNotifyListeners: false,
//       );
//     }
//
//     if (shouldNotifyListeners) {
//       notifyListeners();
//     }
//   }
//
//   Future<void> updateFrom(
//     Currency sendCurrency,
//     bool shouldNotifyListeners,
//   ) async {
//     try {
//       _sendCurrency = sendCurrency;
//       if (_receiveCurrency == null) {
//         _rate = null;
//       } else {
//         await _updateRangesAndEstimate(
//           shouldNotifyListeners: false,
//         );
//       }
//     } catch (e, s) {
//       Logging.instance.log("$e\n$s", level: LogLevel.Error);
//     }
//     if (shouldNotifyListeners) {
//       notifyListeners();
//     }
//   }
//
//   Future<void> updateTo(
//     Currency receiveCurrency,
//     bool shouldNotifyListeners,
//   ) async {
//     try {
//       _receiveCurrency = receiveCurrency;
//
//       if (_sendCurrency == null) {
//         _rate = null;
//       } else {
//         await _updateRangesAndEstimate(
//           shouldNotifyListeners: false,
//         );
//       }
//     } catch (e, s) {
//       Logging.instance.log("$e\n$s", level: LogLevel.Error);
//     }
//     if (shouldNotifyListeners) {
//       notifyListeners();
//     }
//   }
//
//   Future<void> swap(
//       {required bool shouldNotifyListeners,}) async {
//     final Decimal? temp = sendAmount;
//     _sendAmount = receiveAmount;
//     _receiveAmount = temp;
//
//     _minSendAmount = null;
//     _maxSendAmount = null;
//     _minReceiveAmount = null;
//     _maxReceiveAmount = null;
//
//     final Currency? tmp = sendCurrency;
//     _sendCurrency = receiveCurrency;
//     _receiveCurrency = tmp;
//
//     await _updateRangesAndEstimate(
//       shouldNotifyListeners: false,
//     );
//   }
//
//   //============================================================================
//   // private state updaters
//   //============================================================================
//
//   Future<void> _updateRangesAndEstimate(
//       {required bool shouldNotifyListeners,}) async {
//     await _updateRanges(shouldNotifyListeners: false);
//     await _updateEstimate(shouldNotifyListeners: false);
//     if (shouldNotifyListeners) {
//       notifyListeners();
//     }
//   }
//
//   Future<void> _updateRanges({required bool shouldNotifyListeners,}) async {
//     // if (exchange?.name == SimpleSwapExchange.exchangeName) {
//     //   reversed = false;
//     // }
//     final _send = sendCurrency;
//     final _receive = receiveCurrency;
//     if (_send == null || _receive == null) {
//       Logging.instance.log(
//         "Tried to $runtimeType.updateRanges where ( $_send || $_receive) for: $exchange",
//         level: LogLevel.Info,
//       );
//       return;
//     }
//     final response = await exchange.getRange(
//       _send.ticker,
//       _receive.ticker,
//       exchangeRateType == ExchangeRateType.fixed,
//     );
//
//     if (response.value == null) {
//       Logging.instance.log(
//         "Tried to $runtimeType.updateRanges for: $exchange where response: $response",
//         level: LogLevel.Info,
//       );
//       return;
//     }
//     final responseReversed = await exchange.getRange(
//       _receive.ticker,
//       _send.ticker,
//       exchangeRateType == ExchangeRateType.fixed,
//     );
//
//     if (responseReversed.value == null) {
//       Logging.instance.log(
//         "Tried to $runtimeType.updateRanges for: $exchange where response: $responseReversed",
//         level: LogLevel.Info,
//       );
//       return;
//     }
//
//     final range = response.value!;
//     final rangeReversed = responseReversed.value!;
//
//     _minSendAmount = range.min;
//     _maxSendAmount = range.max;
//     _minReceiveAmount = rangeReversed.min;
//     _maxReceiveAmount = rangeReversed.max;
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
//   Future<void> _updateEstimate({
//     required bool shouldNotifyListeners,
//   }) async {
//     // if (exchange?.name == SimpleSwapExchange.exchangeName) {
//     //   reversed = false;
//     // }
//     final amount = reversed ? receiveAmount : sendAmount;
//     if (sendCurrency == null ||
//         receiveCurrency == null ||
//         amount == null ||
//         amount <= Decimal.zero) {
//       Logging.instance.log(
//         "Tried to $runtimeType.updateEstimate for: $exchange where (from: $sendCurrency || to: $receiveCurrency || amount: $amount)",
//         level: LogLevel.Info,
//       );
//       return;
//     }
//     final response = await exchange.getEstimate(
//       sendCurrency!.ticker,
//       receiveCurrency!.ticker,
//       amount,
//       exchangeRateType == ExchangeRateType.fixed,
//       reversed,
//     );
//
//     if (response.value == null) {
//       Logging.instance.log(
//         "Tried to $runtimeType.updateEstimate for: $exchange where response: $response",
//         level: LogLevel.Info,
//       );
//       return;
//     }
//
//     final estimate = response.value!;
//
//     if (reversed) {
//       _sendAmount = estimate.estimatedAmount;
//     } else {
//       _receiveAmount = estimate.estimatedAmount;
//     }
//
//     _rate =
//         (receiveAmount! / sendAmount!).toDecimal(scaleOnInfinitePrecision: 12);
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
//
// }
