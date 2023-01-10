import 'package:decimal/decimal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stackwallet/services/buy/buy.dart';

class BuyFormState extends ChangeNotifier {
  Buy? _buy;
  Buy? get buy => _buy;
  set buy(Buy? value) {
    _buy = value;
    _onBuyTypeChanged();
  }

  // BuyRateType _buyType = BuyRateType.estimated;
  // BuyRateType get buyType => _buyType;
  // set buyType(BuyRateType value) {
  //   _buyType = value;
  //   _onBuyRateTypeChanged();
  // }

  bool reversed = false;

  Decimal? fromAmount;
  Decimal? toAmount;

  Decimal? minAmount;
  Decimal? maxAmount;

  Decimal? rate;
  // Estimate? estimate;
  //
  // dynamic? _market;
  // dynamic? get market => _market;
  //
  // dynamic? _from;
  // dynamic? _to;

  @override
  String toString() {
    return 'BuyFormState: {test: "test"}';
    // return 'BuyFormState: {_buy: $_buy, _buyType: $_buyType, reversed: $reversed, fromAmount: $fromAmount, toAmount: $toAmount, minAmount: $minAmount, maxAmount: $maxAmount, rate: $rate, estimate: $estimate, _market: $_market, _from: $_from, _to: $_to, _onError: $_onError}';
  }

  String? get fromTicker {
    // switch (buyType) {
    //   case BuyRateType.estimated:
    //     return _from?.ticker;
    //   case BuyRateType.fixed:
    //     switch (buy?.name) {
    //       // case SimpleSwapBuy.buyName:
    //       //   return _from?.ticker;
    //       case ChangeNowBuy.buyName:
    //         return market?.from;
    //       default:
    //         return null;
    //     }
    // }
  }

  String? get toTicker {
    // switch (buyType) {
    //   case BuyRateType.estimated:
    //     return _to?.ticker;
    //   case BuyRateType.fixed:
    //     switch (buy?.name) {
    //       // case SimpleSwapBuy.buyName:
    //       //   return _to?.ticker;
    //       case ChangeNowBuy.buyName:
    //         return market?.to;
    //       default:
    //         return null;
    //     }
    // }
  }

  void Function(String)? _onError;

  // dynamic? get from => _from;
  // dynamic? get to => _to;
  //
  // void setCurrencies(dynamic from, dynamic to) {
  //   _from = from;
  //   _to = to;
  // }

  String get warning {
    // if (reversed) {
    //   if (toTicker != null && toAmount != null) {
    //     if (minAmount != null &&
    //         toAmount! < minAmount! &&
    //         toAmount! > Decimal.zero) {
    //       return "Minimum amount ${minAmount!.toString()} ${toTicker!.toUpperCase()}";
    //     } else if (maxAmount != null && toAmount! > maxAmount!) {
    //       return "Maximum amount ${maxAmount!.toString()} ${toTicker!.toUpperCase()}";
    //     }
    //   }
    // } else {
    //   if (fromTicker != null && fromAmount != null) {
    //     if (minAmount != null &&
    //         fromAmount! < minAmount! &&
    //         fromAmount! > Decimal.zero) {
    //       return "Minimum amount ${minAmount!.toString()} ${fromTicker!.toUpperCase()}";
    //     } else if (maxAmount != null && fromAmount! > maxAmount!) {
    //       return "Maximum amount ${maxAmount!.toString()} ${fromTicker!.toUpperCase()}";
    //     }
    //   }
    // }

    return "";
  }

  String get fromAmountString => fromAmount?.toStringAsFixed(8) ?? "";
  String get toAmountString => toAmount?.toStringAsFixed(8) ?? "";

  bool get canBuy {
    // if (buy?.name == ChangeNowBuy.buyName && buyType == BuyRateType.fixed) {
    //   return _market != null &&
    //       fromAmount != null &&
    //       toAmount != null &&
    //       warning.isEmpty;
    // } else {
    //   return fromAmount != null &&
    //       fromAmount != Decimal.zero &&
    //       toAmount != null &&
    //       rate != null &&
    //       warning.isEmpty;
    // }
    return true;
  }

  void clearAmounts(bool shouldNotifyListeners) {
    // fromAmount = null;
    // toAmount = null;
    // minAmount = null;
    // maxAmount = null;
    // rate = null;
    //
    // if (shouldNotifyListeners) {
    //   notifyListeners();
    // }
  }

  Future<void> setFromAmountAndCalculateToAmount(
    Decimal newFromAmount,
    bool shouldNotifyListeners,
  ) async {
    // if (newFromAmount == Decimal.zero) {
    //   toAmount = Decimal.zero;
    // }
    //
    // fromAmount = newFromAmount;
    // reversed = false;
    //
    // await updateRanges(shouldNotifyListeners: false);
    //
    // await updateEstimate(
    //   shouldNotifyListeners: false,
    //   reversed: reversed,
    // );
    //
    // if (shouldNotifyListeners) {
    //   notifyListeners();
    // }
  }

  Future<void> setToAmountAndCalculateFromAmount(
    Decimal newToAmount,
    bool shouldNotifyListeners,
  ) async {
    // if (newToAmount == Decimal.zero) {
    //   fromAmount = Decimal.zero;
    // }
    //
    // toAmount = newToAmount;
    // reversed = true;
    //
    // await updateRanges(shouldNotifyListeners: false);
    //
    // await updateEstimate(
    //   shouldNotifyListeners: false,
    //   reversed: reversed,
    // );
    //
    // if (shouldNotifyListeners) {
    //   notifyListeners();
    // }
  }

  // Future<void> updateTo(dynamic to, bool shouldNotifyListeners) async {
  Future<void> updateTo(dynamic to, bool shouldNotifyListeners) async {
    // try {
    //   _to = to;
    //   if (_from == null) {
    //     rate = null;
    //     notifyListeners();
    //     return;
    //   }
    //
    //   await updateRanges(shouldNotifyListeners: false);
    //
    //   await updateEstimate(
    //     shouldNotifyListeners: false,
    //     reversed: reversed,
    //   );
    //
    //   //todo: check if print needed
    //   // debugPrint(
    //   //     "_updated TO: _from=${_from!.ticker} _to=${_to!.ticker} _fromAmount=$fromAmount _toAmount=$toAmount rate:$rate for: $buy");
    //
    //   if (shouldNotifyListeners) {
    //     notifyListeners();
    //   }
    // } catch (e, s) {
    //   Logging.instance.log("$e\n$s", level: LogLevel.Error);
    // }
  }

  // Future<void> updateFrom(dynamic from, bool shouldNotifyListeners) async {
  Future<void> updateFrom(dynamic from, bool shouldNotifyListeners) async {
    // try {
    //   _from = from;
    //
    //   if (_to == null) {
    //     rate = null;
    //     notifyListeners();
    //     return;
    //   }
    //
    //   await updateRanges(shouldNotifyListeners: false);
    //
    //   await updateEstimate(
    //     shouldNotifyListeners: false,
    //     reversed: reversed,
    //   );
    //
    //   //todo: check if print needed
    //   // debugPrint(
    //   //     "_updated FROM: _from=${_from!.ticker} _to=${_to!.ticker} _fromAmount=$fromAmount _toAmount=$toAmount rate:$rate for: $buy");
    //   if (shouldNotifyListeners) {
    //     notifyListeners();
    //   }
    // } catch (e, s) {
    //   Logging.instance.log("$e\n$s", level: LogLevel.Error);
    // }
  }

  Future<void> updateMarket(
    // dynamic? market,
    dynamic? market,
    bool shouldNotifyListeners,
  ) async {
    // _market = market;
    //
    // if (_market == null) {
    //   fromAmount = null;
    //   toAmount = null;
    // } else {
    //   if (fromAmount != null) {
    //     if (fromAmount! <= Decimal.zero) {
    //       toAmount = Decimal.zero;
    //     } else {
    //       await updateRanges(shouldNotifyListeners: false);
    //       await updateEstimate(
    //         shouldNotifyListeners: false,
    //         reversed: reversed,
    //       );
    //     }
    //   }
    // }
    //
    // if (shouldNotifyListeners) {
    //   notifyListeners();
    // }
  }

  void _onBuyRateTypeChanged() {
    // print("_onBuyRateTypeChanged");
    // updateRanges(shouldNotifyListeners: true).then(
    //   (_) => updateEstimate(
    //     shouldNotifyListeners: true,
    //     reversed: reversed,
    //   ),
    // );
  }

  void _onBuyTypeChanged() {
    // updateRanges(shouldNotifyListeners: true).then(
    //   (_) => updateEstimate(
    //     shouldNotifyListeners: true,
    //     reversed: reversed,
    //   ),
    // );
  }

  Future<void> updateRanges({required bool shouldNotifyListeners}) async {
    // // if (buy?.name == SimpleSwapBuy.buyName) {
    // //   reversed = false;
    // // }
    // final _fromTicker = reversed ? toTicker : fromTicker;
    // final _toTicker = reversed ? fromTicker : toTicker;
    // if (_fromTicker == null || _toTicker == null) {
    //   Logging.instance.log(
    //     "Tried to $runtimeType.updateRanges where (from: $_fromTicker || to: $_toTicker) for: $buy",
    //     level: LogLevel.Info,
    //   );
    //   return;
    // }
    // final response = await buy?.getRange(
    //   _fromTicker,
    //   _toTicker,
    //   buyType == BuyRateType.fixed,
    // );
    //
    // if (response?.value == null) {
    //   Logging.instance.log(
    //     "Tried to $runtimeType.updateRanges for: $buy where response: $response",
    //     level: LogLevel.Info,
    //   );
    //   return;
    // }
    //
    // final range = response!.value!;
    //
    // minAmount = range.min;
    // maxAmount = range.max;
    //
    // //todo: check if print needed
    // // debugPrint(
    // //     "updated range for: $buy for $_fromTicker-$_toTicker: $range");
    //
    // if (shouldNotifyListeners) {
    //   notifyListeners();
    // }
  }

  Future<void> updateEstimate({
    required bool shouldNotifyListeners,
    required bool reversed,
  }) async {
    // // if (buy?.name == SimpleSwapBuy.buyName) {
    // //   reversed = false;
    // // }
    // final amount = reversed ? toAmount : fromAmount;
    // if (fromTicker == null ||
    //     toTicker == null ||
    //     amount == null ||
    //     amount <= Decimal.zero) {
    //   Logging.instance.log(
    //     "Tried to $runtimeType.updateEstimate for: $buy where (from: $fromTicker || to: $toTicker || amount: $amount)",
    //     level: LogLevel.Info,
    //   );
    //   return;
    // }
    // final response = await buy?.getEstimate(
    //   fromTicker!,
    //   toTicker!,
    //   amount,
    //   buyType == BuyRateType.fixed,
    //   reversed,
    // );
    //
    // if (response?.value == null) {
    //   Logging.instance.log(
    //     "Tried to $runtimeType.updateEstimate for: $buy where response: $response",
    //     level: LogLevel.Info,
    //   );
    //   return;
    // }
    //
    // estimate = response!.value!;
    //
    // if (reversed) {
    //   fromAmount = estimate!.estimatedAmount;
    // } else {
    //   toAmount = estimate!.estimatedAmount;
    // }
    //
    // rate = (toAmount! / fromAmount!).toDecimal(scaleOnInfinitePrecision: 12);
    //
    // //todo: check if print needed
    // // debugPrint(
    // //     "updated estimate for: $buy for $fromTicker-$toTicker: $estimate");
    //
    // if (shouldNotifyListeners) {
    //   notifyListeners();
    // }
  }

  void setOnError({
    required void Function(String)? onError,
    bool shouldNotifyListeners = false,
  }) {
    // _onError = onError;
    // if (shouldNotifyListeners) {
    //   notifyListeners();
    // }
  }

  Future<void> swap({dynamic? market}) async {
    // final Decimal? newToAmount = fromAmount;
    // final Decimal? newFromAmount = toAmount;
    //
    // fromAmount = newFromAmount;
    // toAmount = newToAmount;
    //
    // minAmount = null;
    // maxAmount = null;
    //
    // if (buyType == BuyRateType.fixed && buy?.name == ChangeNowBuy.buyName) {
    //   await updateMarket(market, false);
    // } else {
    //   final dynamic? newTo = from;
    //   final dynamic? newFrom = to;
    //
    //   _to = newTo;
    //   _from = newFrom;
    //
    //   await updateRanges(shouldNotifyListeners: false);
    //
    //   await updateEstimate(
    //     shouldNotifyListeners: false,
    //     reversed: reversed,
    //   );
    // }
    //
    // notifyListeners();
  }
}
