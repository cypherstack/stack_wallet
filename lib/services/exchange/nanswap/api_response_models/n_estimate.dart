class NEstimate {
  final String from;
  final String to;
  final num amountFrom;
  final num amountTo;

  NEstimate({
    required this.from,
    required this.to,
    required this.amountFrom,
    required this.amountTo,
  });

  factory NEstimate.fromJson(Map<String, dynamic> json) {
    return NEstimate(
      from: json['from'] as String,
      to: json['to'] as String,
      amountFrom: json['amountFrom'] as num,
      amountTo: json['amountTo'] as num,
    );
  }

  @override
  String toString() {
    return 'NEstimate {'
        'from: $from, '
        'to: $to, '
        'amountFrom: $amountFrom, '
        'amountTo: $amountTo '
        '}';
  }
}
