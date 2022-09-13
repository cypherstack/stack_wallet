class Currency {
  /// Currency ticker
  final String ticker;

  /// Currency name
  final String name;

  /// Currency logo url
  final String image;

  /// Indicates if a currency has an Extra ID
  final bool hasExternalId;

  /// Indicates if a currency is a fiat currency (EUR, USD)
  final bool isFiat;

  /// Indicates if a currency is popular
  final bool featured;

  /// Indicates if a currency is stable
  final bool isStable;

  /// Indicates if a currency is available on a fixed-rate flow
  final bool supportsFixedRate;

  /// Currency network
  final String network;

  /// Contract for token or null for non-token
  final String? tokenContract;

  /// Indicates if a currency is available to buy
  final bool buy;

  /// Indicates if a currency is available to sell
  final bool sell;

  Currency({
    required this.ticker,
    required this.name,
    required this.image,
    required this.hasExternalId,
    required this.isFiat,
    required this.featured,
    required this.isStable,
    required this.supportsFixedRate,
    required this.network,
    this.tokenContract,
    required this.buy,
    required this.sell,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    try {
      return Currency(
        ticker: json["ticker"] as String,
        name: json["name"] as String,
        image: json["image"] as String,
        hasExternalId: json["hasExternalId"] as bool,
        isFiat: json["isFiat"] as bool,
        featured: json["featured"] as bool,
        isStable: json["isStable"] as bool,
        supportsFixedRate: json["supportsFixedRate"] as bool,
        network: json["network"] as String,
        tokenContract: json["tokenContract"] as String?,
        buy: json["buy"] as bool,
        sell: json["sell"] as bool,
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
      "hasExternalId": hasExternalId,
      "isFiat": isFiat,
      "featured": featured,
      "isStable": isStable,
      "supportsFixedRate": supportsFixedRate,
      "network": network,
      "buy": buy,
      "sell": sell,
    };

    if (tokenContract != null) {
      map["tokenContract"] = tokenContract!;
    }

    return map;
  }

  Currency copyWith({
    String? ticker,
    String? name,
    String? image,
    bool? hasExternalId,
    bool? isFiat,
    bool? featured,
    bool? isStable,
    bool? supportsFixedRate,
    bool? isAvailable,
    String? network,
    String? tokenContract,
    bool? buy,
    bool? sell,
  }) {
    return Currency(
      ticker: ticker ?? this.ticker,
      name: name ?? this.name,
      image: image ?? this.image,
      hasExternalId: hasExternalId ?? this.hasExternalId,
      isFiat: isFiat ?? this.isFiat,
      featured: featured ?? this.featured,
      isStable: isStable ?? this.isStable,
      supportsFixedRate: supportsFixedRate ?? this.supportsFixedRate,
      network: network ?? this.network,
      tokenContract: tokenContract ?? this.tokenContract,
      buy: buy ?? this.buy,
      sell: sell ?? this.sell,
    );
  }

  @override
  String toString() {
    return "Currency: ${toJson()}";
  }
}
