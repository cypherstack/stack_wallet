enum TicketState {
  newTicket('NEW'),
  checking('CHECKING'),
  inProgress('IN PROGRESS'),
  offerAvailable('OFFER AVAILABLE'),
  clearing('CLEARING'),
  shipped('SHIPPED'),
  refunded('REFUNDED'),
  fulfilled('FULFILLED'),
  pendingClose('PENDING CLOSE'),
  replyNeeded('REPLY NEEDED'),
  closed('CLOSED'),
  closedCancelled('CLOSED/CANCELLED'),
  merged('MERGED');

  final String value;
  const TicketState(this.value);

  static TicketState fromString(String value) {
    return TicketState.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw Exception("Unknown TicketState string found: $value"),
    );
  }
}

class TicketRef {
  final int id;
  final String number;

  TicketRef({required this.id, required this.number});

  factory TicketRef.fromJson(Map<String, dynamic> json) {
    return TicketRef(id: _toInt(json['id']), number: json['number'].toString());
  }

  Map<String, dynamic> toMap() {
    return {"id": id, "number": number};
  }

  @override
  String toString() => toMap().toString();
}

class TicketStatus {
  final int ticketId;
  final TicketState state;
  final DateTime updatedAt;
  final DateTime? lastAgentMessageAt;
  final String? paymentInvoiceStatus;
  final String? trackingLink;

  TicketStatus({
    required this.ticketId,
    required this.state,
    required this.updatedAt,
    this.lastAgentMessageAt,
    this.paymentInvoiceStatus,
    this.trackingLink,
  });

  factory TicketStatus.fromJson(Map<String, dynamic> json) {
    return TicketStatus(
      ticketId: _toInt(json['ticket_id']),
      state: TicketState.fromString(json['state'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastAgentMessageAt: json['last_agent_message_at'] != null
          ? DateTime.parse(json['last_agent_message_at'] as String)
          : null,
      paymentInvoiceStatus: json['payment_invoice_status'] as String?,
      trackingLink: json['tracking_link'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "ticket_id": ticketId,
      "state": state.toString(),
      "updated_at": updatedAt.toIso8601String(),
      "last_agent_message_at": lastAgentMessageAt?.toIso8601String(),
      "payment_invoice_status": paymentInvoiceStatus,
      "tracking_link": trackingLink,
    };
  }

  @override
  String toString() => toMap().toString();
}

class TicketFull {
  final int id;
  final String number;
  final String productName;
  final String customerPrice;
  final String partnerPrice;
  final String partnerCommission;
  final String netPurchasePrice;
  final String netShippingCosts;
  final int vatRate;

  TicketFull({
    required this.id,
    required this.number,
    required this.productName,
    required this.customerPrice,
    required this.partnerPrice,
    required this.partnerCommission,
    required this.netPurchasePrice,
    required this.netShippingCosts,
    required this.vatRate,
  });

  factory TicketFull.fromJson(Map<String, dynamic> json) {
    return TicketFull(
      id: _toInt(json['id']),
      number: json['number'].toString(),
      productName: (json['product_name'] ?? '').toString(),
      customerPrice: (json['customer_price'] ?? '').toString(),
      partnerPrice: (json['partner_price'] ?? '').toString(),
      partnerCommission: (json['partner_commission'] ?? '').toString(),
      netPurchasePrice: (json['net_purchase_price'] ?? '').toString(),
      netShippingCosts: (json['net_shipping_costs'] ?? '').toString(),
      vatRate: _toInt(json['vat_rate']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "number": number,
      "product_name": productName,
      "customer_price": customerPrice,
      "partner_price": partnerPrice,
      "partner_commission": partnerCommission,
      "net_purchase_price": netPurchasePrice,
      "net_shipping_costs": netShippingCosts,
      "vat_rate": vatRate,
    };
  }

  @override
  String toString() => toMap().toString();
}

int _toInt(dynamic value) {
  if (value is int) return value;
  return int.parse(value.toString());
}
