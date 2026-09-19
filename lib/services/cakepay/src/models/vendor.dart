import 'card.dart';

class CakePayVendor {
  final int id;
  final String name;
  final bool available;
  final String? cakeWarnings;
  final String? country;
  final List<CakePayCard> cards;

  CakePayVendor({
    required this.id,
    required this.name,
    required this.available,
    this.cakeWarnings,
    this.country,
    required this.cards,
  });

  factory CakePayVendor.fromJson(Map<String, dynamic> json) {
    final rawCards = json['cards'];
    final cards = <CakePayCard>[];
    if (rawCards is List) {
      for (final c in rawCards) {
        if (c is Map<String, dynamic>) {
          cards.add(CakePayCard.fromJson(c));
        }
      }
    }

    return CakePayVendor(
      id: json['id'] as int? ?? 0,
      name: (json['name'] ?? '') as String,
      available: json['available'] as bool? ?? true,
      cakeWarnings: json['cake_warnings'] as String?,
      country: json['country'] as String?,
      cards: cards,
    );
  }

  @override
  String toString() => 'CakePayVendor($id, $name)';
}
