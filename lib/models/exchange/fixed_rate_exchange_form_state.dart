// import 'package:decimal/decimal.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:stackwallet/models/exchange/change_now/cn_exchange_estimate.dart';
// import 'package:stackwallet/models/exchange/response_objects/fixed_rate_market.dart';
// import 'package:stackwallet/services/exchange/change_now/change_now_api.dart';
// import 'package:stackwallet/utilities/logger.dart';
//
// class FixedRateExchangeFormState extends ChangeNotifier {
//   Decimal? _fromAmount;
//   Decimal? _toAmount;
//
//   FixedRateMarket? _market;
//   FixedRateMarket? get market => _market;
//
//   CNExchangeEstimate? _estimate;
//   CNExchangeEstimate? get estimate => _estimate;
//
//   Decimal? get rate {
//     if (_estimate == null) {
//       return null;
//     } else {
//       return (_estimate!.toAmount / _estimate!.fromAmount)
//           .toDecimal(scaleOnInfinitePrecision: 12);
//     }
//   }
//
//   Future<void> swap(FixedRateMarket reverseFixedRateMarket) async {
//     final Decimal? tmp = _fromAmount;
//     _fromAmount = _toAmount;
//     _toAmount = tmp;
//
//     await updateMarket(reverseFixedRateMarket, false);
//     await updateRateEstimate(CNEstimateType.direct);
//     _toAmount = _estimate?.toAmount ?? Decimal.zero;
//     notifyListeners();
//   }
//
//   String get fromAmountString =>
//       _fromAmount == null ? "" : _fromAmount!.toStringAsFixed(8);
//   String get toAmountString =>
//       _toAmount == null ? "" : _toAmount!.toStringAsFixed(8);
//
//   Future<void> updateMarket(
//     FixedRateMarket? market,
//     bool shouldNotifyListeners,
//   ) async {
//     _market = market;
//
//     if (_market == null) {
//       _fromAmount = null;
//       _toAmount = null;
//     } else {
//       if (_fromAmount != null) {
//         if (_fromAmount! <= Decimal.zero) {
//           _toAmount = Decimal.zero;
//         } else {
//           await updateRateEstimate(CNEstimateType.direct);
//         }
//       }
//     }
//
//     if (shouldNotifyListeners) {
//       notifyListeners();
//     }
//   }
//
//   String get rateDisplayString {
//     if (_market == null || _estimate == null) {
//       return "N/A";
//     } else {
//       return "1 ${_estimate!.fromCurrency.toUpperCase()} ~${rate!.toStringAsFixed(8)} ${_estimate!.toCurrency.toUpperCase()}";
//     }
//   }
//
//   bool get canExchange {
//     return _market != null &&
//         _fromAmount != null &&
//         _toAmount != null &&
//         sendAmountWarning.isEmpty;
//   }
//
//   String get sendAmountWarning {
//     if (_market != null && _fromAmount != null) {
//       if (_fromAmount! < _market!.min) {
//         return "Minimum amount ${_market!.min.toString()} ${_market!.from.toUpperCase()}";
//       } else if (_fromAmount! > _market!.max) {
//         return "Maximum amount ${_market!.max.toString()} ${_market!.from.toUpperCase()}";
//       }
//     }
//
//     return "";
//   }
//
//   Future<void> setToAmountAndCalculateFromAmount(
//     Decimal newToAmount,
//     bool shouldNotifyListeners,
//   ) async {
//     _toAmount = newToAmount;
//
//     if (shouldNotifyListeners) {
//       await updateRateEstimate(CNEstimateType.reverse);
//       notifyListeners();
//     }
//   }
//
//   Future<void> setFromAmountAndCalculateToAmount(
//     Decimal newFromAmount,
//     bool shouldNotifyListeners,
//   ) async {
//     _fromAmount = newFromAmount;
//
//     if (shouldNotifyListeners) {
//       await updateRateEstimate(CNEstimateType.direct);
//       notifyListeners();
//     }
//   }
//
//   void Function(String)? _onError;
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
//   Future<void> updateRateEstimate(CNEstimateType direction) async {
//     if (market != null) {
//       Decimal? amount;
//       // set amount based on trade estimate direction
//       switch (direction) {
//         case CNEstimateType.direct:
//           if (_fromAmount != null
//               // &&
//               // market!.min >= _fromAmount! &&
//               // _fromAmount! <= market!.max
//               ) {
//             amount = _fromAmount!;
//           }
//           break;
//         case CNEstimateType.reverse:
//           if (_toAmount != null
//               // &&
//               // market!.min >= _toAmount! &&
//               // _toAmount! <= market!.max
//               ) {
//             amount = _toAmount!;
//           }
//           break;
//       }
//
//       if (amount != null && market != null && amount > Decimal.zero) {
//         final response =
//             await ChangeNowAPI.instance.getEstimatedExchangeAmountV2(
//           fromTicker: market!.from,
//           toTicker: market!.to,
//           fromOrTo: direction,
//           flow: CNFlowType.fixedRate,
//           amount: amount,
//         );
//
//         if (response.value != null) {
//           // update estimate if response succeeded
//           _estimate = response.value;
//
//           _toAmount = _estimate?.toAmount;
//           _fromAmount = _estimate?.fromAmount;
//           notifyListeners();
//         } else if (response.exception != null) {
//           Logging.instance.log("updateRateEstimate(): ${response.exception}",
//               level: LogLevel.Warning);
//         }
//       }
//     }
//   }
// }
