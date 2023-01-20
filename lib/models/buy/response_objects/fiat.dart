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

  /// Fiat logo url
  final String image;

  Fiat(
      {required this.ticker,
      required this.name,
      required this.min_amount,
      required this.max_amount,
      required this.image});

  factory Fiat.fromJson(Map<String, dynamic> json) {
    try {
      return Fiat(
        ticker: "${json['ticker']}",
        name: "${json['name']}", // TODO nameFromTicker
        min_amount: Decimal.parse("${json['min_amount'] ?? 0}"),
        max_amount: Decimal.parse("${json['max_amount'] ?? 0}"),
        image: "${json['image']}",
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
      "image": image,
    };

    return map;
  }

  Fiat copyWith({
    String? ticker,
    String? name,
    Decimal? min_amount,
    Decimal? max_amount,
    String? image,
  }) {
    return Fiat(
      ticker: ticker ?? this.ticker,
      name: name ?? this.name,
      min_amount: min_amount ?? this.min_amount,
      max_amount: max_amount ?? this.max_amount,
      image: image ?? this.image,
    );
  }

  @override
  String toString() {
    return "Fiat: ${toJson()}";
  }
}
