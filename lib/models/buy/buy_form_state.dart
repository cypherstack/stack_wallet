import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stackwallet/services/buy/buy.dart';

class BuyFormState extends ChangeNotifier {
  Buy? _buy;
  Buy? get buy => _buy;
  set buy(Buy? value) {
    _buy = value;
  }

  bool reversed = false;
}
