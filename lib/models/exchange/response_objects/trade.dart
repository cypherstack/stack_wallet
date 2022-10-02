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
  final String from;

  @HiveField(7)
  final String fromAmount;

  @HiveField(8)
  final String fromAddress;

  @HiveField(9)
  final String fromNetwork;

  @HiveField(10)
  final String fromExtraId;

  @HiveField(11)
  final String fromTxid;

  @HiveField(12)
  final String to;

  @HiveField(13)
  final String toAmount;

  @HiveField(14)
  final String toAddress;

  @HiveField(15)
  final String toNetwork;

  @HiveField(16)
  final String toExtraId;

  @HiveField(17)
  final String toTxid;

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
    required this.from,
    required this.fromAmount,
    required this.fromAddress,
    required this.fromNetwork,
    required this.fromExtraId,
    required this.fromTxid,
    required this.to,
    required this.toAmount,
    required this.toAddress,
    required this.toNetwork,
    required this.toExtraId,
    required this.toTxid,
    required this.refundAddress,
    required this.refundExtraId,
    required this.status,
  });

  Trade copyWith({
    String? uuid,
    String? tradeId,
    String? rateType,
    String? direction,
    DateTime? timestamp,
    DateTime? updatedAt,
    String? from,
    String? fromAmount,
    String? fromAddress,
    String? fromNetwork,
    String? fromExtraId,
    String? fromTxid,
    String? to,
    String? toAmount,
    String? toAddress,
    String? toNetwork,
    String? toExtraId,
    String? toTxid,
    String? refundAddress,
    String? refundExtraId,
    String? status,
  }) {
    return Trade(
      uuid: uuid ?? this.uuid,
      tradeId: tradeId ?? this.tradeId,
      rateType: rateType ?? this.rateType,
      direction: direction ?? this.direction,
      timestamp: timestamp ?? this.timestamp,
      updatedAt: updatedAt ?? this.updatedAt,
      from: from ?? this.from,
      fromAmount: fromAmount ?? this.fromAmount,
      fromAddress: fromAddress ?? this.fromAddress,
      fromNetwork: fromNetwork ?? this.fromNetwork,
      fromExtraId: fromExtraId ?? this.fromExtraId,
      fromTxid: fromTxid ?? this.fromTxid,
      to: to ?? this.to,
      toAmount: toAmount ?? this.toAmount,
      toAddress: toAddress ?? this.toAddress,
      toNetwork: toNetwork ?? this.toNetwork,
      toExtraId: toExtraId ?? this.toExtraId,
      toTxid: toTxid ?? this.toTxid,
      refundAddress: refundAddress ?? this.refundAddress,
      refundExtraId: refundExtraId ?? this.refundExtraId,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "uuid,": uuid,
      "tradeId,": tradeId,
      "rateType,": rateType,
      "direction,": direction,
      "timestamp,": timestamp,
      "updatedAt,": updatedAt,
      "from,": from,
      "fromAmount,": fromAmount,
      "fromAddress,": fromAddress,
      "fromNetwork,": fromNetwork,
      "fromExtraId,": fromExtraId,
      "fromTxid,": fromTxid,
      "to,": to,
      "toAmount,": toAmount,
      "toAddress,": toAddress,
      "toNetwork,": toNetwork,
      "toExtraId,": toExtraId,
      "toTxid,": toTxid,
      "refundAddress,": refundAddress,
      "refundExtraId,": refundExtraId,
      "status,": status,
    };
  }

  @override
  String toString() {
    return toMap().toString();
  }
}
