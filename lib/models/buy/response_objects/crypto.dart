class Crypto {
  /// Crypto ticker
  final String ticker;

  /// Crypto name
  final String name;

  /// Crypto logo url
  final String image;

  Crypto({
    required this.ticker,
    required this.name,
    required this.image,
  });

  factory Crypto.fromJson(Map<String, dynamic> json) {
    try {
      return Crypto(
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

  Crypto copyWith({
    String? ticker,
    String? name,
    String? image,
  }) {
    return Crypto(
      ticker: ticker ?? this.ticker,
      name: name ?? this.name,
      image: image ?? this.image,
    );
  }

  @override
  String toString() {
    return "Crypto: ${toJson()}";
  }
}
