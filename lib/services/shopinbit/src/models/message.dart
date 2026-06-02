class TicketMessage {
  final DateTime timestamp;
  final bool fromAgent;
  final String content;

  TicketMessage({
    required this.timestamp,
    required this.fromAgent,
    required this.content,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      timestamp:
          DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      fromAgent: json['from_agent'] as bool? ?? false,
      content: json['content'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    "timestamp": timestamp.toIso8601String(),
    "from_agent": fromAgent,
    "content": content,
  };

  @override
  String toString() => toMap().toString();
}
