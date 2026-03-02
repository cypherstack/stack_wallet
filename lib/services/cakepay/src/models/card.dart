class CakePayCard {
  final int id;
  final String name;
  final String? type;
  final String? description;
  final String? termsAndConditions;
  final String? howToUse;
  final String? expiryAndValidity;
  final String? cardImageUrl;
  final String? country;
  final String? currencyCode;
  final List<double> denominations;
  final double? minValue;
  final double? maxValue;
  final double? minValueUsd;
  final double? maxValueUsd;
  final bool available;
  final String? lastUpdated;

  CakePayCard({
    required this.id,
    required this.name,
    this.type,
    this.description,
    this.termsAndConditions,
    this.howToUse,
    this.expiryAndValidity,
    this.cardImageUrl,
    this.country,
    this.currencyCode,
    required this.denominations,
    this.minValue,
    this.maxValue,
    this.minValueUsd,
    this.maxValueUsd,
    required this.available,
    this.lastUpdated,
  });

  factory CakePayCard.fromJson(Map<String, dynamic> json) {
    final rawDenoms = json['denominations'] ?? json['denominations_list'];
    final denominations = <double>[];
    if (rawDenoms is List) {
      for (final d in rawDenoms) {
        if (d is num) {
          denominations.add(d.toDouble());
        } else if (d is String) {
          final parsed = double.tryParse(d);
          if (parsed != null) denominations.add(parsed);
        } else if (d is Map) {
          final v = d['value'];
          if (v is num) {
            denominations.add(v.toDouble());
          } else if (v is String) {
            final parsed = double.tryParse(v);
            if (parsed != null) denominations.add(parsed);
          }
        }
      }
    }

    return CakePayCard(
      id: json['id'] as int? ?? 0,
      name: (json['name'] ?? '') as String,
      type: json['type'] as String?,
      description: json['description'] as String?,
      termsAndConditions: json['terms_and_conditions'] as String?,
      howToUse: json['how_to_use'] as String?,
      expiryAndValidity: json['expiry_and_validity'] as String?,
      cardImageUrl: json['card_image_url'] as String?,
      country: json['country'] is Map
          ? (json['country'] as Map<String, dynamic>)['name'] as String?
          : json['country'] as String?,
      currencyCode: json['currency_code'] as String?,
      denominations: denominations,
      minValue: _toDouble(json['min_value']),
      maxValue: _toDouble(json['max_value']),
      minValueUsd: _toDouble(json['min_value_usd']),
      maxValueUsd: _toDouble(json['max_value_usd']),
      available: json['available'] as bool? ?? true,
      lastUpdated: json['last_updated'] as String?,
    );
  }

  bool get isFixedDenomination => denominations.isNotEmpty;
  bool get isRangeDenomination =>
      denominations.isEmpty && minValue != null && maxValue != null;

  String get denominationRange {
    if (isFixedDenomination) {
      return denominations.map((d) => d.toStringAsFixed(0)).join(', ');
    }
    if (isRangeDenomination) {
      return '${minValue!.toStringAsFixed(0)} - ${maxValue!.toStringAsFixed(0)}';
    }
    return '';
  }

  @override
  String toString() => 'CakePayCard($id, $name)';
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}
