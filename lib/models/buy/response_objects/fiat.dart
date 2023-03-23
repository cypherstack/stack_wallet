import 'package:decimal/decimal.dart';

class Fiat {
  /// Fiat ticker
  final String ticker;

  /// Fiat name
  final String name;

  /// Fiat name
  final Decimal minAmount;

  /// Fiat name
  final Decimal maxAmount;

  Fiat(
      {required this.ticker,
      required this.name,
      required this.minAmount,
      required this.maxAmount});

  factory Fiat.fromJson(Map<String, dynamic> json) {
    try {
      return Fiat(
        ticker: "${json['ticker']}",
        name: "${json['name']}", // TODO nameFromTicker
        minAmount: Decimal.parse("${json['minAmount'] ?? 0}"),
        maxAmount: Decimal.parse("${json['maxAmount'] ?? 0}"),
      );
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    final map = {
      "ticker": ticker,
      "name": name,
      "min_amount": minAmount,
      "max_amount": maxAmount,
    };

    return map;
  }
}
