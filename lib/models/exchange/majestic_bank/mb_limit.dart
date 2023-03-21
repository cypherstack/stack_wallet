import 'package:decimal/decimal.dart';
import 'package:stackduo/models/exchange/majestic_bank/mb_object.dart';

class MBLimit extends MBObject {
  MBLimit({
    required this.currency,
    required this.min,
    required this.max,
  });

  final String currency;
  final Decimal min;
  final Decimal max;

  @override
  String toString() {
    return "MBLimit: { $currency: { min: $min, max: $max } }";
  }
}
