class NCurrency {
  final String id;
  final String ticker;
  final String name;
  final String image;
  final String network;
  final bool hasExternalId;
  final bool feeLess;

  NCurrency({
    required this.id,
    required this.ticker,
    required this.name,
    required this.image,
    required this.network,
    required this.hasExternalId,
    required this.feeLess,
  });

  factory NCurrency.fromJson(Map<String, dynamic> json) {
    return NCurrency(
      id: json["id"] as String,
      ticker: json['ticker'] as String,
      name: json['name'] as String,
      image: json['image'] as String,
      network: json['network'] as String,
      hasExternalId: json['hasExternalId'] as bool,
      feeLess: json['feeless'] as bool,
    );
  }

  @override
  String toString() {
    return 'NCurrency {'
        'ticker: $ticker, '
        'name: $name, '
        'image: $image, '
        'network: $network, '
        'hasExternalId: $hasExternalId, '
        'feeless: $feeLess'
        '}';
  }
}
