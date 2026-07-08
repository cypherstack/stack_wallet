import 'package:decimal/decimal.dart';

class PaymentInfo {
  final String status;
  final String customerPrice;
  final String partnerPrice;
  final Decimal? vatRate;
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
      customerPrice: json['customer_price'] as String,
      partnerPrice: json['partner_price'] as String,
      vatRate: Decimal.tryParse(json['vat_rate'].toString()),
      currency: json['currency'] as String,
      rateLockedUntil: DateTime.tryParse(
        json['rate_locked_until']?.toString() ?? '',
      ),
      paymentLinks: linksRaw.map((k, v) => MapEntry(k, v as String)),
      due: json['due'] as String?,
    );
  }
}
