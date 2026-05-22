class CarResearchInvoice {
  final String btcpayInvoice;
  final DateTime expiresAt;
  final Map<String, String> paymentLinks;

  CarResearchInvoice({
    required this.btcpayInvoice,
    required this.expiresAt,
    required this.paymentLinks,
  });

  factory CarResearchInvoice.fromJson(Map<String, dynamic> json) {
    final linksRaw = json['payment_links'] as Map<String, dynamic>? ?? {};
    return CarResearchInvoice(
      btcpayInvoice: json['btcpay_invoice'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      paymentLinks: linksRaw.map((k, v) => MapEntry(k, v as String)),
    );
  }
}

class CarResearchPaymentResult {
  final String status;
  final int ticketId;
  final String ticketNumber;
  final String externalCustomerKey;

  CarResearchPaymentResult({
    required this.status,
    required this.ticketId,
    required this.ticketNumber,
    required this.externalCustomerKey,
  });

  factory CarResearchPaymentResult.fromJson(Map<String, dynamic> json) {
    return CarResearchPaymentResult(
      status: json['status'] as String,
      ticketId: json['ticket_id'] as int,
      ticketNumber: json['ticket_number'] as String,
      externalCustomerKey: json['external_customer_key'] as String,
    );
  }
}
