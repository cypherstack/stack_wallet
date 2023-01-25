import 'package:decimal/decimal.dart';

class Fiat {
  /// Fiat ticker
  final String ticker;

  /// Fiat name
  final String name;

  /// Fiat name
  final Decimal min_amount;

  /// Fiat name
  final Decimal max_amount;

  Fiat(
      {required this.ticker,
      required this.name,
      required this.min_amount,
      required this.max_amount});

  factory Fiat.fromJson(Map<String, dynamic> json) {
    try {
      return Fiat(
        ticker: "${json['ticker']}",
        name: "${json['name']}", // TODO nameFromTicker
        min_amount: Decimal.parse("${json['min_amount'] ?? 0}"),
        max_amount: Decimal.parse("${json['max_amount'] ?? 0}"),
      );
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    final map = {
      "ticker": ticker,
      "name": name,
      "min_amount": min_amount,
      "max_amount": max_amount,
    };

    return map;
  }
}
