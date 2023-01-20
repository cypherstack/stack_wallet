class Crypto {
  /// Crypto ticker
  final String ticker;

  /// Crypto name
  final String name;

  /// Crypto network
  final String? network;

  /// Crypto contract address
  final String? contractAddress;

  /// Crypto logo url
  final String image;

  Crypto({
    required this.ticker,
    required this.name,
    required this.network,
    required this.contractAddress,
    required this.image,
  });

  factory Crypto.fromJson(Map<String, dynamic> json) {
    try {
      return Crypto(
        ticker: json["ticker"] as String,
        name: json["name"] as String,
        network: json["network"] as String,
        contractAddress: json["contractAddress"] as String,
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
      "network": network,
      "contractAddress": contractAddress,
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
      network: network ?? this.network,
      contractAddress: contractAddress ?? this.contractAddress,
      image: image ?? this.image,
    );
  }

  @override
  String toString() {
    return "Crypto: ${toJson()}";
  }
}
