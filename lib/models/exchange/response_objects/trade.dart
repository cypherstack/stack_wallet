import 'package:hive/hive.dart';

@HiveType(typeId: Trade.typeId)
class Trade {
  static const typeId = 22;

  @HiveField(0)
  final String uuid;

  @HiveField(1)
  final String tradeId;

  @HiveField(2)
  final String rateType;

  @HiveField(3)
  final String direction;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final DateTime updatedAt;

  @HiveField(6)
  final String payInCurrency;

  @HiveField(7)
  final String payInAmount;

  @HiveField(8)
  final String payInAddress;

  @HiveField(9)
  final String payInNetwork;

  @HiveField(10)
  final String payInExtraId;

  @HiveField(11)
  final String payInTxid;

  @HiveField(12)
  final String payOutCurrency;

  @HiveField(13)
  final String payOutAmount;

  @HiveField(14)
  final String payOutAddress;

  @HiveField(15)
  final String payOutNetwork;

  @HiveField(16)
  final String payOutExtraId;

  @HiveField(17)
  final String payOutTxid;

  @HiveField(18)
  final String refundAddress;

  @HiveField(19)
  final String refundExtraId;

  @HiveField(20)
  final String status;

  const Trade({
    required this.uuid,
    required this.tradeId,
    required this.rateType,
    required this.direction,
    required this.timestamp,
    required this.updatedAt,
    required this.payInCurrency,
    required this.payInAmount,
    required this.payInAddress,
    required this.payInNetwork,
    required this.payInExtraId,
    required this.payInTxid,
    required this.payOutCurrency,
    required this.payOutAmount,
    required this.payOutAddress,
    required this.payOutNetwork,
    required this.payOutExtraId,
    required this.payOutTxid,
    required this.refundAddress,
    required this.refundExtraId,
    required this.status,
  });

  Trade copyWith({
    String? tradeId,
    String? rateType,
    String? direction,
    DateTime? timestamp,
    DateTime? updatedAt,
    String? payInCurrency,
    String? payInAmount,
    String? payInAddress,
    String? payInNetwork,
    String? payInExtraId,
    String? payInTxid,
    String? payOutCurrency,
    String? payOutAmount,
    String? payOutAddress,
    String? payOutNetwork,
    String? payOutExtraId,
    String? payOutTxid,
    String? refundAddress,
    String? refundExtraId,
    String? status,
  }) {
    return Trade(
      uuid: uuid,
      tradeId: tradeId ?? this.tradeId,
      rateType: rateType ?? this.rateType,
      direction: direction ?? this.direction,
      timestamp: timestamp ?? this.timestamp,
      updatedAt: updatedAt ?? this.updatedAt,
      payInCurrency: payInCurrency ?? this.payInCurrency,
      payInAmount: payInAmount ?? this.payInAmount,
      payInAddress: payInAddress ?? this.payInAddress,
      payInNetwork: payInNetwork ?? this.payInNetwork,
      payInExtraId: payInExtraId ?? this.payInExtraId,
      payInTxid: payInTxid ?? this.payInTxid,
      payOutCurrency: payOutCurrency ?? this.payOutCurrency,
      payOutAmount: payOutAmount ?? this.payOutAmount,
      payOutAddress: payOutAddress ?? this.payOutAddress,
      payOutNetwork: payOutNetwork ?? this.payOutNetwork,
      payOutExtraId: payOutExtraId ?? this.payOutExtraId,
      payOutTxid: payOutTxid ?? this.payOutTxid,
      refundAddress: refundAddress ?? this.refundAddress,
      refundExtraId: refundExtraId ?? this.refundExtraId,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "uuid": uuid,
      "tradeId": tradeId,
      "rateType": rateType,
      "direction": direction,
      "timestamp": timestamp,
      "updatedAt": updatedAt,
      "payInCurrency": payInCurrency,
      "payInAmount": payInAmount,
      "payInAddress": payInAddress,
      "payInNetwork": payInNetwork,
      "payInExtraId": payInExtraId,
      "payInTxid": payInTxid,
      "payOutCurrency": payOutCurrency,
      "payOutAmount": payOutAmount,
      "payOutAddress": payOutAddress,
      "payOutNetwork": payOutNetwork,
      "payOutExtraId": payOutExtraId,
      "payOutTxid": payOutTxid,
      "refundAddress": refundAddress,
      "refundExtraId": refundExtraId,
      "status": status,
    };
  }

  @override
  String toString() {
    return toMap().toString();
  }
}
