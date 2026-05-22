import "package:decimal/decimal.dart";

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
  final List<Decimal> denominations;
  final Decimal? minValue;
  final Decimal? maxValue;
  final Decimal? minValueUsd;
  final Decimal? maxValueUsd;
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
    final dynamic rawDenoms =
        json["denominations"] ?? json["denominations_list"];
    final List<Decimal> denominations = <Decimal>[];
    if (rawDenoms is List) {
      for (final dynamic d in rawDenoms) {
        final Decimal? parsed = _toDecimal(d is Map ? d["value"] : d);
        if (parsed != null) denominations.add(parsed);
      }
    }

    return CakePayCard(
      id: json["id"] as int? ?? 0,
      name: (json["name"] ?? "") as String,
      type: json["type"] as String?,
      description: json["description"] as String?,
      termsAndConditions: json["terms_and_conditions"] as String?,
      howToUse: json["how_to_use"] as String?,
      expiryAndValidity: json["expiry_and_validity"] as String?,
      cardImageUrl: json["card_image_url"] as String?,
      country: json["country"] is Map
          ? (json["country"] as Map<String, dynamic>)["name"] as String?
          : json["country"] as String?,
      currencyCode: json["currency_code"] as String?,
      denominations: denominations,
      minValue: _toDecimal(json["min_value"]),
      maxValue: _toDecimal(json["max_value"]),
      minValueUsd: _toDecimal(json["min_value_usd"]),
      maxValueUsd: _toDecimal(json["max_value_usd"]),
      available: json["available"] as bool? ?? true,
      lastUpdated: json["last_updated"] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      "id": id,
      "name": name,
      "type": type,
      "description": description,
      "terms_and_conditions": termsAndConditions,
      "how_to_use": howToUse,
      "expiry_and_validity": expiryAndValidity,
      "card_image_url": cardImageUrl,
      "country": country,
      "currency_code": currencyCode,
      "denominations": denominations.map((Decimal d) => d.toString()).toList(),
      "min_value": minValue?.toString(),
      "max_value": maxValue?.toString(),
      "min_value_usd": minValueUsd?.toString(),
      "max_value_usd": maxValueUsd?.toString(),
      "available": available,
      "last_updated": lastUpdated,
    };
  }

  bool get isFixedDenomination => denominations.isNotEmpty;
  bool get isRangeDenomination =>
      denominations.isEmpty && minValue != null && maxValue != null;

  String get denominationRange {
    if (isFixedDenomination) {
      return denominations.map((Decimal d) => d.toStringAsFixed(0)).join(", ");
    }
    if (isRangeDenomination) {
      return "${minValue!.toStringAsFixed(0)} - ${maxValue!.toStringAsFixed(0)}";
    }
    return "";
  }

  @override
  String toString() => toMap().toString();
}

Decimal? _toDecimal(dynamic v) {
  if (v == null) return null;
  if (v is Decimal) return v;
  if (v is int) return Decimal.fromInt(v);
  if (v is double) return Decimal.parse(v.toString());
  if (v is String) return Decimal.tryParse(v);
  return null;
}
