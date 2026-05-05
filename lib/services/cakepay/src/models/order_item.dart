class CakePayOrderItem {
  final int? cardId;
  final String? name;

  /// The price string as returned by the API.
  ///
  /// May be a bare number (`"20.00"`) or include the currency
  /// (`"20.00 EUR"`).  Use [priceValue] when you need only the numeric
  /// portion and [currencyCode] for the currency.
  final String? price;

  /// The numeric portion of [price] (e.g. `"20.00"`).
  final String? priceValue;

  /// Price expressed in USD, as returned by the API (e.g. `"$24.12"`).
  final String? priceUsd;

  final int? quantity;
  final String? currencyCode;
  final String? cardImageUrl;

  CakePayOrderItem({
    this.cardId,
    this.name,
    this.price,
    this.priceValue,
    this.priceUsd,
    this.quantity,
    this.currencyCode,
    this.cardImageUrl,
  });

  factory CakePayOrderItem.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price']?.toString();

    // The API may return price as "20.00 EUR" (with currency) or just
    // "20.00".  Extract the leading numeric portion so the UI can display
    // it without duplicating the currency code.
    String? priceValue;
    if (rawPrice != null) {
      final match = RegExp(r'^[\d.]+').firstMatch(rawPrice);
      priceValue = match?.group(0) ?? rawPrice;
    }

    return CakePayOrderItem(
      cardId: json['card_id'] as int?,
      name: json['name'] as String?,
      price: rawPrice,
      priceValue: priceValue,
      priceUsd: json['price_usd']?.toString(),
      quantity: json['quantity'] as int?,
      currencyCode: json['currency_code'] as String?,
      cardImageUrl: json['card_image_url'] as String?,
    );
  }

  @override
  String toString() => 'CakePayOrderItem($cardId, $name)';
}
