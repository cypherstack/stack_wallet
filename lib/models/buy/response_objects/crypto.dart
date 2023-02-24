class Crypto {
  /// Crypto ticker
  final String ticker;

  /// Crypto name
  final String name;

  /// Crypto network
  final String? network;

  /// Crypto contract address
  final String? contractAddress;

  Crypto({
    required this.ticker,
    required this.name,
    required this.network,
    required this.contractAddress,
  });

  factory Crypto.fromJson(Map<String, dynamic> json) {
    try {
      return Crypto(
        ticker: "${json['ticker']}",
        name: "${json['name']}",
        network: "${json['network']}",
        contractAddress: "${json['contractAddress']}",
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
    };

    return map;
  }
}
