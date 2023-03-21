import 'package:decimal/decimal.dart';
import 'package:stackduo/models/exchange/majestic_bank/mb_object.dart';

enum MBOrderType {
  fixed,
  floating,
}

class MBOrder extends MBObject {
  MBOrder({
    required this.orderId,
    required this.fromCurrency,
    required this.fromAmount,
    required this.receiveCurrency,
    required this.receiveAmount,
    required this.address,
    required this.orderType,
    required this.expiration,
    required this.createdAt,
  });

  final String orderId;
  final String fromCurrency;
  final Decimal fromAmount;
  final String receiveCurrency;
  final String address;
  final Decimal receiveAmount;
  final MBOrderType orderType;

  ///     minutes
  final int expiration;

  final DateTime createdAt;

  bool isExpired() =>
      (DateTime.now().difference(createdAt) >= Duration(minutes: expiration));

  @override
  String toString() {
    // todo: full toString
    return orderId;
  }
}
