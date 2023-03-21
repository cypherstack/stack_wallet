import 'package:decimal/decimal.dart';
import 'package:stackduo/utilities/logger.dart';

class FixedRateMarket {
  /// Currency ticker
  final String from;

  /// Currency ticker
  final String to;

  /// Minimal limit for exchange
  final Decimal min;

  /// Maximum limit for exchange
  final Decimal max;

  /// Exchange rate.
  /// Formula for calculating the estimated amount:
  ///     estimatedAmount = (rate * amount) - minerFee
  final Decimal rate;

  /// Network fee for transferring funds between wallets, it should
  /// be deducted from the result.
  final Decimal? minerFee;

  FixedRateMarket({
    required this.from,
    required this.to,
    required this.min,
    required this.max,
    required this.rate,
    required this.minerFee,
  });

  factory FixedRateMarket.fromMap(Map<String, dynamic> json) {
    try {
      return FixedRateMarket(
        from: json["from"] as String,
        to: json["to"] as String,
        min: Decimal.parse(json["min"].toString()),
        max: Decimal.parse(json["max"].toString()),
        rate: Decimal.parse(json["rate"].toString()),
        minerFee: Decimal.tryParse(json["minerFee"].toString()),
      );
    } catch (e, s) {
      Logging.instance.log(
        "FixedRateMarket.fromMap(): $e\n$s",
        level: LogLevel.Error,
      );
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      "from": from,
      "to": to,
      "min": min,
      "max": max,
      "rate": rate,
      "minerFee": minerFee,
    };
  }

  FixedRateMarket copyWith({
    String? from,
    String? to,
    Decimal? min,
    Decimal? max,
    Decimal? rate,
    Decimal? minerFee,
  }) {
    return FixedRateMarket(
      from: from ?? this.from,
      to: to ?? this.to,
      min: min ?? this.min,
      max: max ?? this.max,
      rate: rate ?? this.rate,
      minerFee: minerFee ?? this.minerFee,
    );
  }

  @override
  String toString() => "FixedRateMarket: ${toMap()}";
}
