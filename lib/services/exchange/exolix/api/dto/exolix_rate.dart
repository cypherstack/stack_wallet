import 'package:decimal/decimal.dart';

import '../helpers/parse_decimal.dart';
import 'exolix_base_dto.dart';

/// Exchange rate quote.
///
/// All numeric fields are [Decimal] to preserve precision for coin amounts
/// and exchange rates.
class ExolixRate extends ExolixBaseDto {
  final Decimal fromAmount;
  final Decimal toAmount;
  final Decimal rate;
  final String? message;
  final Decimal minAmount;
  final Decimal withdrawMin;
  final Decimal maxAmount;

  ExolixRate({
    required this.fromAmount,
    required this.toAmount,
    required this.rate,
    required this.message,
    required this.minAmount,
    required this.withdrawMin,
    required this.maxAmount,
  });

  factory ExolixRate.fromJson(Map<String, dynamic> json) {
    return ExolixRate(
      fromAmount: parseDecimal(json["fromAmount"]),
      toAmount: parseDecimal(json["toAmount"]),
      rate: parseDecimal(json["rate"]),
      message: json["message"] as String?,
      minAmount: parseDecimal(json["minAmount"]),
      withdrawMin: parseDecimal(json["withdrawMin"]),
      maxAmount: parseDecimal(json["maxAmount"]),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      "fromAmount": fromAmount.toString(),
      "toAmount": toAmount.toString(),
      "rate": rate.toString(),
      "message": message,
      "minAmount": minAmount.toString(),
      "withdrawMin": withdrawMin.toString(),
      "maxAmount": maxAmount.toString(),
    };
  }
}
