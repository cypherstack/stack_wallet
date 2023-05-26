import 'package:stackwallet/utilities/amount/amount.dart';

class TransactionFilter {
  final bool sent;
  final bool received;
  final bool trade;
  final DateTime? from;
  final DateTime? to;
  final Amount? amount;
  final String keyword;

  TransactionFilter({
    required this.sent,
    required this.received,
    required this.trade,
    required this.from,
    required this.to,
    required this.amount,
    required this.keyword,
  });

  TransactionFilter copyWith({
    bool? sent,
    bool? received,
    bool? trade,
    DateTime? from,
    DateTime? to,
    Amount? amount,
    String? keyword,
  }) {
    return TransactionFilter(
      sent: sent ?? this.sent,
      received: received ?? this.received,
      trade: trade ?? this.trade,
      from: from ?? this.from,
      to: to ?? this.to,
      amount: amount ?? this.amount,
      keyword: keyword ?? this.keyword,
    );
  }

  @override
  String toString() {
    return "TxFilter { sent: $sent, received: $received, trade: $trade, from: $from, to: $to, amount: $amount, keyword: $keyword }";
  }
}
