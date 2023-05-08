import 'package:decimal/decimal.dart';
import 'package:stackwallet/utilities/logger.dart';

class Estimate {
  final Decimal estimatedAmount;
  final bool fixedRate;
  final bool reversed;
  final String? warningMessage;
  final String? rateId;
  final String exchangeProvider;
  final String? kycRating;

  Estimate({
    required this.estimatedAmount,
    required this.fixedRate,
    required this.reversed,
    this.warningMessage,
    this.rateId,
    required this.exchangeProvider,
    this.kycRating,
  });

  factory Estimate.fromMap(
    Map<String, dynamic> map, {
    required String exchangeProvider,
    String? kycRating,
  }) {
    try {
      return Estimate(
        estimatedAmount: Decimal.parse(map["estimatedAmount"] as String),
        fixedRate: map["fixedRate"] as bool,
        reversed: map["reversed"] as bool,
        warningMessage: map["warningMessage"] as String?,
        rateId: map["rateId"] as String?,
        exchangeProvider: exchangeProvider,
        kycRating: kycRating,
      );
    } catch (e, s) {
      Logging.instance.log("Estimate.fromMap(): $e\n$s", level: LogLevel.Error);
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      "estimatedAmount": estimatedAmount.toString(),
      "fixedRate": fixedRate,
      "reversed": reversed,
      "warningMessage": warningMessage,
      "rateId": rateId,
      "exchangeProvider": exchangeProvider,
      "kycRating": kycRating,
    };
  }

  @override
  String toString() => "Estimate: ${toMap()}";
}
