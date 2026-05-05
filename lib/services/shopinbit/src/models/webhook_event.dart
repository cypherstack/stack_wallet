enum WebhookEventType {
  ticketStateChanged('ticket.state_changed'),
  ticketMessageCreated('ticket.message_created');

  final String value;
  const WebhookEventType(this.value);

  static WebhookEventType fromString(String s) {
    return WebhookEventType.values.firstWhere(
      (e) => e.value == s,
      orElse: () => WebhookEventType.ticketStateChanged,
    );
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
