import 'package:decimal/decimal.dart';
import 'package:stackwallet/utilities/logger.dart';

class EstimatedExchangeAmount {
  /// Estimated exchange amount
  final Decimal estimatedAmount;

  /// Dash-separated min and max estimated time in minutes
  final String transactionSpeedForecast;

  /// Some warnings like warnings that transactions on this network
  /// take longer or that the currency has moved to another network
  final String? warningMessage;

  /// (Optional) Use rateId for fixed-rate flow. If this field is true, you
  /// could use returned field "rateId" in next method for creating transaction
  /// to freeze estimated amount that you got in this method. Current estimated
  /// amount would be valid until time in field "validUntil"
  final String? rateId;

  /// ONLY for fixed rate.
  /// Network fee for transferring funds between wallets, it should be deducted
  /// from the result.  Formula for calculating the estimated amount is given below
  /// estimatedAmount = (rate * amount) - networkFee
  final Decimal? networkFee;

  EstimatedExchangeAmount({
    required this.estimatedAmount,
    required this.transactionSpeedForecast,
    required this.warningMessage,
    required this.rateId,
    this.networkFee,
  });

  factory EstimatedExchangeAmount.fromJson(Map<String, dynamic> json) {
    try {
      return EstimatedExchangeAmount(
        estimatedAmount: Decimal.parse(json["estimatedAmount"].toString()),
        transactionSpeedForecast: json["transactionSpeedForecast"] as String,
        warningMessage: json["warningMessage"] as String?,
        rateId: json["rateId"] as String?,
        networkFee: Decimal.tryParse(json["networkFee"].toString()),
      );
    } catch (e, s) {
      Logging.instance
          .log("Failed to parse: $json \n$e\n$s", level: LogLevel.Fatal);
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "estimatedAmount": estimatedAmount,
      "transactionSpeedForecast": transactionSpeedForecast,
      "warningMessage": warningMessage,
      "rateId": rateId,
      "networkFee": networkFee,
    };
  }

  EstimatedExchangeAmount copyWith({
    Decimal? estimatedAmount,
    String? transactionSpeedForecast,
    String? warningMessage,
    String? rateId,
    Decimal? networkFee,
  }) {
    return EstimatedExchangeAmount(
      estimatedAmount: estimatedAmount ?? this.estimatedAmount,
      transactionSpeedForecast:
          transactionSpeedForecast ?? this.transactionSpeedForecast,
      warningMessage: warningMessage ?? this.warningMessage,
      rateId: rateId ?? this.rateId,
      networkFee: networkFee ?? this.networkFee,
    );
  }

  @override
  String toString() {
    return "EstimatedExchangeAmount: ${toJson()}";
  }
}
