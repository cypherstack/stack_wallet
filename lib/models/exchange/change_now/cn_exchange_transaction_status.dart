import 'package:decimal/decimal.dart';

enum ChangeNowTransactionStatus {
  New,
  Waiting,
  Confirming,
  Exchanging,
  Sending,
  Finished,
  Failed,
  Refunded,
  Verifying,
}

extension ChangeNowTransactionStatusExt on ChangeNowTransactionStatus {
  String get lowerCaseName => name.toLowerCase();
}

ChangeNowTransactionStatus changeNowTransactionStatusFromStringIgnoreCase(
  String string,
) {
  for (final value in ChangeNowTransactionStatus.values) {
    if (value.lowerCaseName == string.toLowerCase()) {
      return value;
    }
  }
  throw ArgumentError(
    "String value does not match any known ChangeNowTransactionStatus",
  );
}

class CNExchangeTransactionStatus {
  final String id;
  final ChangeNowTransactionStatus status;
  final bool actionsAvailable;
  final String fromCurrency;
  final String fromNetwork;
  final String toCurrency;
  final String toNetwork;
  final String? expectedAmountFrom;
  final String? expectedAmountTo;
  final String? amountFrom;
  final String? amountTo;
  final String payinAddress;
  final String payoutAddress;
  final String? payinExtraId;
  final String? payoutExtraId;
  final String? refundAddress;
  final String? refundExtraId;
  final String createdAt;
  final String updatedAt;
  final String? depositReceivedAt;
  final String? payinHash;
  final String? payoutHash;
  final String fromLegacyTicker;
  final String toLegacyTicker;
  final String? refundHash;
  final String? refundAmount;
  final int? userId;
  final String? validUntil;

  const CNExchangeTransactionStatus({
    required this.id,
    required this.status,
    required this.actionsAvailable,
    required this.fromCurrency,
    required this.fromNetwork,
    required this.toCurrency,
    required this.toNetwork,
    this.expectedAmountFrom,
    this.expectedAmountTo,
    this.amountFrom,
    this.amountTo,
    required this.payinAddress,
    required this.payoutAddress,
    this.payinExtraId,
    this.payoutExtraId,
    this.refundAddress,
    this.refundExtraId,
    required this.createdAt,
    required this.updatedAt,
    this.depositReceivedAt,
    this.payinHash,
    this.payoutHash,
    required this.fromLegacyTicker,
    required this.toLegacyTicker,
    this.refundHash,
    this.refundAmount,
    this.userId,
    this.validUntil,
  });

  factory CNExchangeTransactionStatus.fromMap(Map<String, dynamic> map) {
    return CNExchangeTransactionStatus(
      id: map["id"] as String,
      status: changeNowTransactionStatusFromStringIgnoreCase(
        map["status"] as String,
      ),
      actionsAvailable: map["actionsAvailable"] as bool,
      fromCurrency: map["fromCurrency"] as String? ?? "",
      fromNetwork: map["fromNetwork"] as String? ?? "",
      toCurrency: map["toCurrency"] as String? ?? "",
      toNetwork: map["toNetwork"] as String? ?? "",
      expectedAmountFrom: _get(map["expectedAmountFrom"]),
      expectedAmountTo: _get(map["expectedAmountTo"]),
      amountFrom: _get(map["amountFrom"]),
      amountTo: _get(map["amountTo"]),
      payinAddress: map["payinAddress"] as String? ?? "",
      payoutAddress: map["payoutAddress"] as String? ?? "",
      payinExtraId: map["payinExtraId"] as String?,
      payoutExtraId: map["payoutExtraId"] as String?,
      refundAddress: map["refundAddress"] as String?,
      refundExtraId: map["refundExtraId"] as String?,
      createdAt: map["createdAt"] as String? ?? "",
      updatedAt: map["updatedAt"] as String? ?? "",
      depositReceivedAt: map["depositReceivedAt"] as String?,
      payinHash: map["payinHash"] as String?,
      payoutHash: map["payoutHash"] as String?,
      fromLegacyTicker: map["fromLegacyTicker"] as String? ?? "",
      toLegacyTicker: map["toLegacyTicker"] as String? ?? "",
      refundHash: map["refundHash"] as String?,
      refundAmount: _get(map["refundAmount"]),
      userId:
          map["userId"] is int
              ? map["userId"] as int
              : int.tryParse(map["userId"].toString()),
      validUntil: map["validUntil"] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "status": status,
      "actionsAvailable": actionsAvailable,
      "fromCurrency": fromCurrency,
      "fromNetwork": fromNetwork,
      "toCurrency": toCurrency,
      "toNetwork": toNetwork,
      "expectedAmountFrom": expectedAmountFrom,
      "expectedAmountTo": expectedAmountTo,
      "amountFrom": amountFrom,
      "amountTo": amountTo,
      "payinAddress": payinAddress,
      "payoutAddress": payoutAddress,
      "payinExtraId": payinExtraId,
      "payoutExtraId": payoutExtraId,
      "refundAddress": refundAddress,
      "refundExtraId": refundExtraId,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
      "depositReceivedAt": depositReceivedAt,
      "payinHash": payinHash,
      "payoutHash": payoutHash,
      "fromLegacyTicker": fromLegacyTicker,
      "toLegacyTicker": toLegacyTicker,
      "refundHash": refundHash,
      "refundAmount": refundAmount,
      "userId": userId,
      "validUntil": validUntil,
    };
  }

  static String? _get(dynamic value) {
    if (value is String) return value;
    if (value is num) return Decimal.tryParse(value.toString())?.toString();
    return null;
  }

  @override
  String toString() => "CNExchangeTransactionStatus: ${toMap()}";
}
