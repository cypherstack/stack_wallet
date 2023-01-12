class Fiat {
  /// Fiat ticker
  final String ticker;

  /// Fiat name
  final String name;

  /// Fiat logo url
  final String image;

  Fiat({required this.ticker, required this.name, required this.image});

  factory Fiat.fromJson(Map<String, dynamic> json) {
    try {
      return Fiat(
        ticker: json["ticker"] as String,
        name: json["name"] as String,
        image: json["image"] as String,
      );
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    final map = {
      "ticker": ticker,
      "name": name,
      "image": image,
    };

    return map;
  }

  Fiat copyWith({
    String? ticker,
    String? name,
    String? image,
  }) {
    return Fiat(
      ticker: ticker ?? this.ticker,
      name: name ?? this.name,
      image: image ?? this.image,
    );
  }

  @override
  String toString() {
    return "Fiat: ${toJson()}";
  }
}
