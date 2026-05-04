class PaymentInfo {
  final String status;
  final String customerPrice;
  final String partnerPrice;
  final int vatRate;
  final String currency;
  final DateTime? rateLockedUntil;
  final Map<String, String> paymentLinks;
  final String? due;

  PaymentInfo({
    required this.status,
    required this.customerPrice,
    required this.partnerPrice,
    required this.vatRate,
    required this.currency,
    this.rateLockedUntil,
    required this.paymentLinks,
    this.due,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    final linksRaw = json['payment_links'] as Map<String, dynamic>? ?? {};
    return PaymentInfo(
      status: json['status'] as String,
      customerPrice: (json['customer_price'] ?? '') as String,
      partnerPrice: (json['partner_price'] ?? '') as String,
      vatRate: _toInt(json['vat_rate']),
      currency: (json['currency'] ?? 'EUR') as String,
      rateLockedUntil: json['rate_locked_until'] != null
          ? DateTime.parse(json['rate_locked_until'] as String)
          : null,
      paymentLinks: linksRaw.map((k, v) => MapEntry(k, v as String)),
      due: json['due'] as String?,
    );
  }
}

int _toInt(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.parse(v);
  if (v is double) return v.toInt();
  return 0;
}
