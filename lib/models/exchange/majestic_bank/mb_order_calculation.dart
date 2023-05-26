import 'package:decimal/decimal.dart';
import 'package:stackwallet/models/exchange/majestic_bank/mb_object.dart';

class MBOrderCalculation extends MBObject {
  MBOrderCalculation({
    required this.fromCurrency,
    required this.fromAmount,
    required this.receiveCurrency,
    required this.receiveAmount,
  });

  final String fromCurrency;
  final Decimal fromAmount;
  final String receiveCurrency;
  final Decimal receiveAmount;

  @override
  String toString() {
    return "MBOrderCalculation: { $fromCurrency: $fromAmount, $receiveCurrency: $receiveAmount }";
  }
}
