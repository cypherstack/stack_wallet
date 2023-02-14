import 'package:decimal/decimal.dart';
import 'package:stackwallet/models/exchange/majestic_bank/mb_object.dart';

class MBOrderStatus extends MBObject {
  MBOrderStatus({
    required this.orderId,
    required this.status,
    required this.fromCurrency,
    required this.fromAmount,
    required this.receiveCurrency,
    required this.receiveAmount,
    required this.address,
    required this.received,
    required this.confirmed,
  });

  final String orderId;
  final String status;
  final String fromCurrency;
  final Decimal fromAmount;
  final String receiveCurrency;
  final Decimal receiveAmount;
  final String address;
  final Decimal received;
  final Decimal confirmed;

  @override
  String toString() {
    // todo: full toString
    return status;
  }
}
