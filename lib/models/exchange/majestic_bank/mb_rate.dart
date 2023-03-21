import 'package:decimal/decimal.dart';
import 'package:stackduo/models/exchange/majestic_bank/mb_object.dart';

class MBRate extends MBObject {
  MBRate({
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
  });

  final String fromCurrency;
  final String toCurrency;
  final Decimal rate;

  @override
  String toString() {
    return "MBRate: { $fromCurrency-$toCurrency: $rate }";
  }
}
