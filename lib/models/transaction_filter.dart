class TransactionFilter {
  final bool sent;
  final bool received;
  final DateTime? from;
  final DateTime? to;
  final int? amount;
  final String keyword;

  TransactionFilter({
    required this.sent,
    required this.received,
    required this.from,
    required this.to,
    required this.amount,
    required this.keyword,
  });

  TransactionFilter copyWith({
    bool? sent,
    bool? received,
    DateTime? from,
    DateTime? to,
    int? amount,
    String? keyword,
  }) {
    return TransactionFilter(
      sent: sent ?? this.sent,
      received: received ?? this.received,
      from: from ?? this.from,
      to: to ?? this.to,
      amount: amount ?? this.amount,
      keyword: keyword ?? this.keyword,
    );
  }

  @override
  String toString() {
    return "TxFilter { sent: $sent, received: $received, from: $from, to: $to, amount: $amount, keyword: $keyword }";
  }
}
