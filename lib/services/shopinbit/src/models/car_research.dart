/// Optional request payload cached with a car research fee invoice. When
/// provided, the backend creates the real car research ticket itself after the
/// fee is paid (the BTCPay webhook failsafe), so the client does not have to.
class CarResearchRequest {
  final String customerPseudonym;
  final String comment;
  final String deliveryCountry;
  final String? deliveryState;

  CarResearchRequest({
    required this.customerPseudonym,
    required this.comment,
    required this.deliveryCountry,
    required this.deliveryState,
  });

  Map<String, dynamic> toJson() => {
    'customer_pseudonym': customerPseudonym,
    'comment': comment,
    'delivery_country': deliveryCountry,
    if (deliveryState != null) 'delivery_state': deliveryState,
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
    final expiresRaw = json['expires_at'] as String;
    final createdRaw = json['created_at'] as String;
    return CarResearchCurrentInvoice(
      invoiceId: json['invoice_id'] as String,
      status: json['status'] as String,
      additional: json['additional'] as String?,
      expiresAt: DateTime.parse(expiresRaw),
      paymentLinks: linksRaw.map((k, v) => MapEntry(k, v as String)),
      hasRequestPayload: json['has_request_payload'] as bool,
      createdAt: DateTime.parse(createdRaw),
    );
  }
}

/// Whether a car research invoice status counts as paid/finalized.
///
/// Prefer the `finalized` boolean from the status endpoint (see
/// [CarResearchInvoiceStatus.finalized]). This is the fallback for the raw
/// status/additional strings: Processing, Settled, or Expired with PaidLate,
/// plus lowercase values for older concierge-style statuses.
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
      expiresAt: DateTime.parse(json['expires_at'] as String),
      paymentLinks: linksRaw.map((k, v) => MapEntry(k, v as String)),
    );
  }
}

/// Result of GET /car-research/invoice/{invoice_id}/status.
///
/// Read-only: it never confirms payment, so poll until [finalized] is true.
/// Once finalized it carries the created ticket references:
///
/// * [realTicketId] / [realTicketNumber]: the customer-facing car research
///   chat. Open this for the customer after payment.
/// * [receiptTicketId] / [receiptTicketNumber]: the paid-fee receipt only;
///   do NOT use it as the active customer chat.
///
/// The sandbox populates only the receipt references and leaves the real ticket
/// fields null, so [realTicketId] is nullable.
class CarResearchInvoiceStatus {
  final String status;
  final String? additional;
  final bool finalized;
  final int? receiptTicketId;
  final String? receiptTicketNumber;
  final int? realTicketId;
  final String? realTicketNumber;
  final String externalCustomerKey;

  CarResearchInvoiceStatus({
    required this.status,
    this.additional,
    required this.finalized,
    this.receiptTicketId,
    this.receiptTicketNumber,
    this.realTicketId,
    this.realTicketNumber,
    required this.externalCustomerKey,
  });

  factory CarResearchInvoiceStatus.fromJson(Map<String, dynamic> json) {
    return CarResearchInvoiceStatus(
      status: json['status'] as String,
      additional: json['additional']?.toString(),
      finalized: json['finalized'] as bool,
      receiptTicketId: json['receipt_ticket_id'] as int?,
      receiptTicketNumber: json['receipt_ticket_number'] as String?,
      realTicketId: json['real_ticket_id'] as int?,
      realTicketNumber: json['real_ticket_number'] as String?,
      externalCustomerKey: json['external_customer_key'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "status": status,
      "additional": additional,
      "finalized": finalized,
      "receipt_ticket_id": receiptTicketId,
      "receipt_ticket_number": receiptTicketNumber,
      "real_ticket_id": realTicketId,
      "real_ticket_number": realTicketNumber,
      "external_customer_key": externalCustomerKey,
    };
  }

  @override
  String toString() => toMap().toString();
}
