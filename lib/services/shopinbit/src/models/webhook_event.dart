import '../../../../utilities/logger.dart';

enum WebhookEventType {
  ticketStateChanged('ticket.state_changed'),
  ticketMessageCreated('ticket.message_created'),
  // Sentinel for any webhook event_type the API sends that this client does
  // not recognise. Callers MUST drop these events rather than dispatch them:
  // coercing an unknown event onto a known handler is worse than ignoring it.
  unknown('UNKNOWN');

  final String value;
  const WebhookEventType(this.value);

  static WebhookEventType fromString(String s) {
    for (final e in WebhookEventType.values) {
      if (e.value == s) return e;
    }
    Logging.instance.w(
      "ShopInBit: unrecognised WebhookEventType '$s' from API: "
      "mapping to WebhookEventType.unknown (event will be dropped)",
    );
    return WebhookEventType.unknown;
  }
}

class WebhookEvent {
  final WebhookEventType eventType;
  final Map<String, dynamic> data;

  WebhookEvent({required this.eventType, required this.data});

  factory WebhookEvent.fromJson(Map<String, dynamic> json) {
    return WebhookEvent(
      eventType: WebhookEventType.fromString(json['event_type'] as String),
      data: json['data'] as Map<String, dynamic>,
    );
  }
}
