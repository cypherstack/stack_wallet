/// The rate type for an exchange.
enum ExolixRateType {
  fixed,
  float;

  String get apiValue => switch (this) {
    .fixed => "fixed",
    .float => "float",
  };
}

/// Transaction status returned by the API.
enum ExolixTransactionStatus {
  wait,
  confirmation,
  confirmed,
  exchanging,
  sending,
  success,
  overdue,
  refund,
  refunded,
  unknown;

  static ExolixTransactionStatus fromString(String? value) => switch (value) {
    "wait" => .wait,
    "confirmation" => .confirmation,
    "confirmed" => .confirmed,
    "exchanging" => .exchanging,
    "sending" => .sending,
    "success" => .success,
    "overdue" => .overdue,
    "refund" => .refund,
    "refunded" => .refunded,
    _ => .unknown,
  };
}
