class NTrade {
  final String id;
  final String from;
  final String to;
  final num expectedAmountFrom;
  final num expectedAmountTo;
  final String payinAddress;
  final String payoutAddress;

  final String? payinExtraId;
  final String? fullLink;
  final String? status;
  final String? payinHash;
  final String? payoutHash;
  final num? fromAmount;
  final num? toAmount;
  final String? fromNetwork;
  final String? toNetwork;

  NTrade({
    required this.id,
    required this.from,
    required this.to,
    required this.expectedAmountFrom,
    required this.expectedAmountTo,
    required this.payinAddress,
    required this.payoutAddress,
    this.payinExtraId,
    this.fullLink,
    this.status,
    this.payinHash,
    this.payoutHash,
    this.fromAmount,
    this.toAmount,
    this.fromNetwork,
    this.toNetwork,
  });

  factory NTrade.fromJson(Map<String, dynamic> json) {
    return NTrade(
      id: json['id'] as String,
      from: json['from'] as String,
      to: json['to'] as String,
      expectedAmountFrom: num.parse(json['expectedAmountFrom'].toString()),
      expectedAmountTo: json['expectedAmountTo'] as num,
      payinAddress: json['payinAddress'] as String,
      payoutAddress: json['payoutAddress'] as String,
      fullLink: json['fullLink'] as String?,
      payinExtraId: json['payinExtraId'] as String?,
      status: json['status'] as String?,
      payinHash: json['payinHash'] as String?,
      payoutHash: json['payoutHash'] as String?,
      fromAmount: json['fromAmount'] as num?,
      toAmount: json['toAmount'] as num?,
      fromNetwork: json['fromNetwork'] as String?,
      toNetwork: json['toNetwork'] as String?,
    );
  }

  @override
  String toString() {
    return 'NTrade {'
        '  id: $id, '
        '  from: $from, '
        '  to: $to, '
        '  expectedAmountFrom: $expectedAmountFrom, '
        '  expectedAmountTo: $expectedAmountTo, '
        '  payinAddress: $payinAddress, '
        '  payoutAddress: $payoutAddress, '
        '  fullLink: $fullLink, '
        '  payinExtraId: $payinExtraId, '
        '  status: $status, '
        '  payinHash: $payinHash, '
        '  payoutHash: $payoutHash '
        '  fromAmount: $fromAmount, '
        '  toAmount: $toAmount, '
        '  fromNetwork: $fromNetwork, '
        '  toNetwork: $toNetwork, '
        '}';
  }
}
