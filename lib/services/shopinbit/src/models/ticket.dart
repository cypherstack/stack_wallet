import '../../../../utilities/logger.dart';

/// Splits a raw `tracking_link` value into individual tracking URLs.
///
/// Multiple links may be joined with any of `,`, `|`, or `;` (and a single
/// value may mix them). Returns an empty list for null/empty input. Each URL is
/// trimmed and empty segments are discarded.
List<String> splitTrackingLinks(String? raw) {
  if (raw == null) return const [];
  return raw
      .split(RegExp(r'[,|;]'))
      .map((s) {
        final url = s.trim();
        if (url.startsWith("http://") || url.startsWith("https://")) {
          return url;
        } else {
          return "https://$url";
        }
      })
      .where((s) => s.isNotEmpty)
      .toList();
}

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
  merged('MERGED'),
  unknown('UNKNOWN');

  final String value;
  const TicketState(this.value);

  static TicketState fromString(String s) {
    for (final e in TicketState.values) {
      if (e.value == s) return e;
    }
    Logging.instance.w(
      "ShopInBit: unrecognised TicketState '$s' from API: "
      "mapping to TicketState.unknown",
    );
    return TicketState.unknown;
  }

  bool get isTerminal => switch (this) {
    .closed ||
    .closedCancelled ||
    .merged ||
    .pendingClose ||
    .refunded => true,
    _ => false,
  };
}

class TicketRef {
  final int id;
  final String number;

  /// [kind] is nullable for backwards compat only
  final String? kind;

  /// True only when [kind] explicitly marks this as a receipt ticket.
  /// False does not rule it out, since legacy tickets have a null [kind].
  bool get isKnownReceipt => kind == "receipt";

  TicketRef({required this.id, required this.number, this.kind});

  factory TicketRef.fromJson(Map<String, dynamic> json) {
    return TicketRef(
      id: _toInt(json['id']),
      number: json['number'] as String,
      kind: json['ticket_kind'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {"id": id, "number": number, "kind": kind};
  }

  @override
  String toString() => toMap().toString();
}

class TicketStatus {
  final int ticketId;
  final TicketState state;
  final String stateRaw;
  final DateTime updatedAt;
  final DateTime? lastAgentMessageAt;
  final String? paymentInvoiceStatus;
  final String? trackingLink;

  TicketStatus({
    required this.ticketId,
    required this.state,
    required this.stateRaw,
    required this.updatedAt,
    this.lastAgentMessageAt,
    this.paymentInvoiceStatus,
    this.trackingLink,
  });

  /// The tracking link(s) split into individual URLs.
  ///
  /// A ticket may carry zero, one, or several tracking URLs. When there are
  /// several the API joins them into [trackingLink] using any of `,`, `|`, or
  /// `;` as the separator (mixed separators occur in practice), so we split on
  /// all three.
  List<String> get trackingLinks => splitTrackingLinks(trackingLink);

  factory TicketStatus.fromJson(Map<String, dynamic> json) {
    final rawState = json['state'] as String;
    return TicketStatus(
      ticketId: _toInt(json['ticket_id']),
      state: TicketState.fromString(rawState),
      stateRaw: rawState,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastAgentMessageAt: json['last_agent_message_at'] != null
          ? DateTime.parse(json['last_agent_message_at'] as String)
          : null,
      paymentInvoiceStatus: json['payment_invoice_status'] as String?,
      // Production returns "" (not null) when there is no tracking link yet;
      // normalize so callers can treat it like any other absent value.
      trackingLink: _emptyToNull(json['tracking_link']),
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
  final String? productName;
  final String? customerPrice;
  final String? partnerPrice;
  final String? partnerCommission;
  final String? netPurchasePrice;
  final String? netShippingCosts;
  final String deliveryCountry;
  final int? vatRate;

  TicketFull({
    required this.id,
    required this.number,
    required this.productName,
    required this.customerPrice,
    required this.partnerPrice,
    required this.partnerCommission,
    required this.netPurchasePrice,
    required this.netShippingCosts,
    required this.deliveryCountry,
    required this.vatRate,
  });

  factory TicketFull.fromJson(Map<String, dynamic> json) {
    return TicketFull(
      id: _toInt(json['id']),
      number: json['number'] as String,
      productName: json['product_name'] as String?,
      customerPrice: json['customer_price'] as String?,
      partnerPrice: json['partner_price'] as String?,
      partnerCommission: json['partner_commission'] as String?,
      netPurchasePrice: json['net_purchase_price'] as String?,
      netShippingCosts: json['net_shipping_costs'] as String?,
      deliveryCountry:
          (json['delivery_country'] ?? json['deliverycountry']) as String,
      vatRate: int.tryParse(json['vat_rate'].toString()),
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
      "delivery_country": deliveryCountry,
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

String? _emptyToNull(dynamic value) {
  final s = value?.toString().trim();
  if (s == null || s.isEmpty) return null;
  return s;
}
