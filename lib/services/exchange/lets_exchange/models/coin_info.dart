import "package:decimal/decimal.dart";

class CoinInfo {
  CoinInfo({
    required this.minAmount,
    required this.maxAmount,
    required this.amount,
    required this.rate,
    required this.profit,
    required this.withdrawalFee,
    required this.rateId,
    required this.rateIdExpiredAt,
  });

  final Decimal minAmount;
  final Decimal maxAmount;
  final Decimal amount;

  final Decimal rate;

  final Decimal? profit;
  final Decimal withdrawalFee;

  final String? rateId;

  final DateTime? rateIdExpiredAt;

  factory CoinInfo.fromJson(Map<String, dynamic> json) {
    final rawProfit = json["profit"] as String?;
    final rawExpiredAt = json["rate_id_expired_at"] as int?;
    return CoinInfo(
      minAmount: Decimal.parse(json["min_amount"] as String),
      maxAmount: Decimal.parse(json["max_amount"] as String),
      amount: Decimal.parse(json["amount"] as String),
      rate: Decimal.parse(json["rate"] as String),
      profit: rawProfit == null ? null : Decimal.tryParse(rawProfit),
      withdrawalFee: Decimal.parse(json["withdrawal_fee"] as String),
      rateId: json["rate_id"] as String?,
      rateIdExpiredAt: rawExpiredAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(rawExpiredAt),
    );
  }

  Map<String, dynamic> toMap() => {
    "min_amount": minAmount.toString(),
    "max_amount": maxAmount.toString(),
    "amount": amount.toString(),
    "rate": rate.toString(),
    "profit": profit?.toString(),
    "withdrawal_fee": withdrawalFee.toString(),
    "rate_id": rateId,
    "rate_id_expired_at": rateIdExpiredAt?.millisecondsSinceEpoch.toString(),
  };

  @override
  String toString() => toMap().toString();
}
