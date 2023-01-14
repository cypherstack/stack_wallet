import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stackwallet/services/buy/buy.dart';

class BuyFormState extends ChangeNotifier {
  Buy? _buy;
  Buy? get buy => _buy;
  set buy(Buy? value) {
    _buy = value;
    // _onBuyTypeChanged();
  }

  bool reversed = false;

  Future<void> updateEstimate({
    required bool shouldNotifyListeners,
    required bool reversed,
  }) async {
    // TODO implement updating estimaate based on changed selected crypto, fiat, etc
  }

  Future<void> swap({dynamic? market}) async {
    // TODO implement swapping values on FiatOrCrypto toggle (or whatever it's called)
  }
}
