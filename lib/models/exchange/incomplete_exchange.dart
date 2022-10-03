import 'package:decimal/decimal.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/exchange_rate_sheet.dart';

class IncompleteExchangeModel {
  final String sendTicker;
  final String receiveTicker;

  final String rateInfo;

  final Decimal sendAmount;
  final Decimal receiveAmount;

  final ExchangeRateType rateType;

  String? recipientAddress;
  String? refundAddress;

  String? rateId;

  Trade? trade;

  IncompleteExchangeModel({
    required this.sendTicker,
    required this.receiveTicker,
    required this.rateInfo,
    required this.sendAmount,
    required this.receiveAmount,
    required this.rateType,
    this.rateId,
  });
}
