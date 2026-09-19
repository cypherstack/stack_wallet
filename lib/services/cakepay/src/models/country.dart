class CakePayCountry {
  final String name;
  final String countryCode;
  final String currencyCode;
  final String? image;
  final bool available;

  CakePayCountry({
    required this.name,
    required this.countryCode,
    required this.currencyCode,
    this.image,
    required this.available,
  });

  factory CakePayCountry.fromJson(Map<String, dynamic> json) {
    return CakePayCountry(
      name: (json['name'] ?? '') as String,
      countryCode: (json['country_code'] ?? '') as String,
      currencyCode: (json['currency_code'] ?? '') as String,
      image: json['image'] as String?,
      available: json['available'] as bool? ?? true,
    );
  }

  @override
  String toString() => 'CakePayCountry($countryCode, $name)';
}
