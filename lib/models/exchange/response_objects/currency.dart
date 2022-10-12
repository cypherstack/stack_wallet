class Currency {
  /// Currency ticker
  final String ticker;

  /// Currency name
  final String name;

  /// Currency network
  final String network;

  /// Currency logo url
  final String image;

  /// Indicates if a currency has an Extra ID
  final bool hasExternalId;

  /// external id if it exists
  final String? externalId;

  /// Indicates if a currency is a fiat currency (EUR, USD)
  final bool isFiat;

  /// Indicates if a currency is popular
  final bool featured;

  /// Indicates if a currency is stable
  final bool isStable;

  /// Indicates if a currency is available on a fixed-rate flow
  final bool supportsFixedRate;

  /// (Optional - based on api call) Indicates whether the pair is
  /// currently supported by change now
  final bool? isAvailable;

  Currency({
    required this.ticker,
    required this.name,
    required this.network,
    required this.image,
    required this.hasExternalId,
    this.externalId,
    required this.isFiat,
    required this.featured,
    required this.isStable,
    required this.supportsFixedRate,
    this.isAvailable,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    try {
      return Currency(
        ticker: json["ticker"] as String,
        name: json["name"] as String,
        network: json["network"] as String? ?? "",
        image: json["image"] as String,
        hasExternalId: json["hasExternalId"] as bool,
        externalId: json["externalId"] as String?,
        isFiat: json["isFiat"] as bool,
        featured: json["featured"] as bool,
        isStable: json["isStable"] as bool,
        supportsFixedRate: json["supportsFixedRate"] as bool,
        isAvailable: json["isAvailable"] as bool?,
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
      "image": image,
      "hasExternalId": hasExternalId,
      "externalId": externalId,
      "isFiat": isFiat,
      "featured": featured,
      "isStable": isStable,
      "supportsFixedRate": supportsFixedRate,
    };

    if (isAvailable != null) {
      map["isAvailable"] = isAvailable!;
    }

    return map;
  }

  Currency copyWith({
    String? ticker,
    String? name,
    String? network,
    String? image,
    bool? hasExternalId,
    String? externalId,
    bool? isFiat,
    bool? featured,
    bool? isStable,
    bool? supportsFixedRate,
    bool? isAvailable,
  }) {
    return Currency(
      ticker: ticker ?? this.ticker,
      name: name ?? this.name,
      network: network ?? this.network,
      image: image ?? this.image,
      hasExternalId: hasExternalId ?? this.hasExternalId,
      externalId: externalId ?? this.externalId,
      isFiat: isFiat ?? this.isFiat,
      featured: featured ?? this.featured,
      isStable: isStable ?? this.isStable,
      supportsFixedRate: supportsFixedRate ?? this.supportsFixedRate,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  @override
  String toString() {
    return "Currency: ${toJson()}";
  }
}
