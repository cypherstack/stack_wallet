/// Optional request payload cached with a car research fee invoice. When
/// provided, the backend creates the real car research ticket itself after the
/// fee is paid (the BTCPay webhook failsafe), so the client does not have to.
class CarResearchRequest {
  final String customerPseudonym;
  final String comment;
  final String deliveryCountry;

  CarResearchRequest({
    required this.customerPseudonym,
    required this.comment,
    required this.deliveryCountry,
  });

  Map<String, dynamic> toJson() => {
    'customer_pseudonym': customerPseudonym,
    'comment': comment,
    'delivery_country': deliveryCountry,
  };
}

/// An unresolved car research invoice returned by
/// GET /car-research/invoices/current, used to recover a payment the user
/// started but did not finish.
class CarResearchCurrentInvoice {
  final String invoiceId;
  final String status;
  final String? additional;
  final DateTime? expiresAt;
  final Map<String, String> paymentLinks;
  final bool hasRequestPayload;
  final DateTime? createdAt;

  CarResearchCurrentInvoice({
    required this.invoiceId,
    required this.status,
    required this.additional,
    required this.expiresAt,
    required this.paymentLinks,
    required this.hasRequestPayload,
    required this.createdAt,
  });

  factory CarResearchCurrentInvoice.fromJson(Map<String, dynamic> json) {
    final linksRaw = json['payment_links'] as Map<String, dynamic>? ?? {};
    final expiresRaw = json['expires_at'] as String?;
    final createdRaw = json['created_at'] as String?;
    return CarResearchCurrentInvoice(
      invoiceId: json['invoice_id'] as String,
      status: json['status'] as String? ?? '',
      additional: json['additional'] as String?,
      expiresAt: expiresRaw == null ? null : DateTime.tryParse(expiresRaw),
      paymentLinks: linksRaw.map((k, v) => MapEntry(k, v as String)),
      hasRequestPayload: json['has_request_payload'] as bool? ?? false,
      createdAt: createdRaw == null ? null : DateTime.tryParse(createdRaw),
    );
  }
}

/// Whether a car research invoice status counts as paid/finalized per the
/// ShopinBit 1.0.4 rules: Processing, Settled, or Expired with PaidLate. The
/// extra lowercase values keep older concierge-style statuses working.
bool carResearchIsFinalized(String? status, String? additional) {
  final s = (status ?? '').toLowerCase().trim();
  final a = (additional ?? '').toLowerCase().trim();
  if (s == 'processing' || s == 'settled') return true;
  if (s == 'expired' && a == 'paidlate') return true;
  return const {
    'paid',
    'paid_over',
    'paid_late',
    'payment_processing',
    'confirmed',
    'complete',
    'completed',
    'finalized',
  }.contains(s);
}

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
      expiresAt:
          DateTime.tryParse(json['expires_at']?.toString() ?? '') ??
          DateTime.now(),
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
      ticketId: int.tryParse(json['ticket_id'].toString()) ?? 0,
      ticketNumber: json['ticket_number'] as String,
      externalCustomerKey: json['external_customer_key'] as String,
    );
  }
}
