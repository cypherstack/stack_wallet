import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/exchange_rate_sheet.dart';

class IncompleteExchangeModel extends ChangeNotifier {
  final String sendTicker;
  final String receiveTicker;

  final String rateInfo;

  final Decimal sendAmount;
  final Decimal receiveAmount;

  final ExchangeRateType rateType;

  final bool reversed;

  String? _recipientAddress;

  String? get recipientAddress => _recipientAddress;

  set recipientAddress(String? recipientAddress) {
    if (_recipientAddress != recipientAddress) {
      _recipientAddress = recipientAddress;
      notifyListeners();
    }
  }

  String? _refundAddress;

  String? get refundAddress => _refundAddress;

  set refundAddress(String? refundAddress) {
    if (_refundAddress != refundAddress) {
      _refundAddress = refundAddress;
      notifyListeners();
    }
  }

  String? _rateId;

  String? get rateId => _rateId;

  set rateId(String? rateId) {
    if (_rateId != rateId) {
      _rateId = rateId;
      notifyListeners();
    }
  }

  Trade? _trade;

  Trade? get trade => _trade;

  set trade(Trade? trade) {
    if (_trade != trade) {
      _trade = trade;
      notifyListeners();
    }
  }

  IncompleteExchangeModel({
    required this.sendTicker,
    required this.receiveTicker,
    required this.rateInfo,
    required this.sendAmount,
    required this.receiveAmount,
    required this.rateType,
    required this.reversed,
    String? rateId,
  }) : _rateId = rateId;
}
