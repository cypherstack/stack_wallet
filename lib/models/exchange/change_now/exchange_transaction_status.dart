import 'package:hive/hive.dart';
import 'package:epicmobile/utilities/logger.dart';

part '../../type_adaptors/exchange_transaction_status.g.dart';

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
      "String value does not match any known ChangeNowTransactionStatus");
}

@HiveType(typeId: 16)
class ExchangeTransactionStatus {
  /// Transaction status
  @HiveField(0)
  final ChangeNowTransactionStatus status;

  /// We generate it when creating a transaction
  @HiveField(1)
  final String payinAddress;

  /// The wallet address that will receive the exchanged funds
  @HiveField(2)
  final String payoutAddress;

  /// Ticker of the currency you want to exchange
  @HiveField(3)
  final String fromCurrency;

  /// Ticker of the currency you want to receive
  @HiveField(4)
  final String toCurrency;

  /// Trade/Transaction ID
  @HiveField(5)
  final String id;

  /// Date and time of the last transaction update (e.g. status update)
  @HiveField(6)
  final String updatedAt;

  /// The amount you want to send
  @HiveField(7)
  final String expectedSendAmountDecimal;

  /// Estimate based on the field expectedSendAmount.
  @HiveField(8)
  final String expectedReceiveAmountDecimal;

  /// Transaction creation date and time
  @HiveField(9)
  final String createdAt;

  /// Deposit receiving date and time
  @HiveField(10)
  final String depositReceivedAt;

  /// Field name currency Extra ID (e.g. Memo, Extra ID)
  @HiveField(11)
  final String payinExtraIdName;

  /// Field name currency Extra ID (e.g. Memo, Extra ID)
  @HiveField(12)
  final String payoutExtraIdName;

  /// Transaction hash in the blockchain of the currency which you specified in
  /// the fromCurrency field that you send when creating the transaction
  @HiveField(13)
  final String payinHash;

  /// Transaction hash in the blockchain of the currency which you specified in
  /// the toCurrency field. We generate it when creating a transaction
  @HiveField(14)
  final String payoutHash;

  /// change now generates it when creating a transaction
  @HiveField(15)
  final String payinExtraId;

  /// Extra ID that you send when creating a transaction
  @HiveField(16)
  final String payoutExtraId;

  /// Amount you send
  @HiveField(17)
  final String amountSendDecimal;

  /// Amount you receive
  @HiveField(18)
  final String amountReceiveDecimal;

  /// Wallet address to receive NOW tokens upon exchange
  @HiveField(19)
  final String tokensDestination;

  /// Refund address (if you specified it)
  @HiveField(20)
  final String refundAddress;

  /// ExtraId for refund (if you specified it)
  @HiveField(21)
  final String refundExtraId;

  /// Date and time of transaction validity
  @HiveField(22)
  final String validUntil;

  /// Indicates if a transaction has been sent for verification
  @HiveField(23)
  final bool verificationSent;

  /// Partner user ID that was sent when the transaction was created
  @HiveField(24)
  final String userId;

  /// Object that may have been sent when the transaction was created (can
  /// contain up to 5 arbitrary fields up to 64 characters long)
  @HiveField(25)
  final Object? payload;

  /// Indicates if transactions are affiliate
  @HiveField(26)
  final bool isPartner;

  ExchangeTransactionStatus({
    required this.status,
    required this.payinAddress,
    required this.payoutAddress,
    required this.fromCurrency,
    required this.toCurrency,
    required this.id,
    required this.updatedAt,
    required this.expectedSendAmountDecimal,
    required this.expectedReceiveAmountDecimal,
    required this.createdAt,
    required this.isPartner,
    required this.depositReceivedAt,
    required this.payinExtraIdName,
    required this.payoutExtraIdName,
    required this.payinHash,
    required this.payoutHash,
    required this.payinExtraId,
    required this.payoutExtraId,
    required this.amountSendDecimal,
    required this.amountReceiveDecimal,
    required this.tokensDestination,
    required this.refundAddress,
    required this.refundExtraId,
    required this.validUntil,
    required this.verificationSent,
    required this.userId,
    required this.payload,
  });

  factory ExchangeTransactionStatus.fromJson(Map<String, dynamic> json) {
    Logging.instance.log(json, printFullLength: true, level: LogLevel.Info);
    try {
      return ExchangeTransactionStatus(
        status: changeNowTransactionStatusFromStringIgnoreCase(
            json["status"] as String),
        payinAddress: json["payinAddress"] as String? ?? "",
        payoutAddress: json["payoutAddress"] as String? ?? "",
        fromCurrency: json["fromCurrency"] as String? ?? "",
        toCurrency: json["toCurrency"] as String? ?? "",
        id: json["id"] as String,
        updatedAt: json["updatedAt"] as String? ?? "",
        expectedSendAmountDecimal: json["expectedSendAmount"] == null
            ? ""
            : json["expectedSendAmount"].toString(),
        expectedReceiveAmountDecimal: json["expectedReceiveAmount"] == null
            ? ""
            : json["expectedReceiveAmount"].toString(),
        createdAt: json["createdAt"] as String? ?? "",
        isPartner: json["isPartner"] as bool,
        depositReceivedAt: json["depositReceivedAt"] as String? ?? "",
        payinExtraIdName: json["payinExtraIdName"] as String? ?? "",
        payoutExtraIdName: json["payoutExtraIdName"] as String? ?? "",
        payinHash: json["payinHash"] as String? ?? "",
        payoutHash: json["payoutHash"] as String? ?? "",
        payinExtraId: json["payinExtraId"] as String? ?? "",
        payoutExtraId: json["payoutExtraId"] as String? ?? "",
        amountSendDecimal:
            json["amountSend"] == null ? "" : json["amountSend"].toString(),
        amountReceiveDecimal: json["amountReceive"] == null
            ? ""
            : json["amountReceive"].toString(),
        tokensDestination: json["tokensDestination"] as String? ?? "",
        refundAddress: json["refundAddress"] as String? ?? "",
        refundExtraId: json["refundExtraId"] as String? ?? "",
        validUntil: json["validUntil"] as String? ?? "",
        verificationSent: json["verificationSent"] as bool? ?? false,
        userId: json["userId"] as String? ?? "",
        payload: json["payload"] as Object?,
      );
    } catch (e, s) {
      Logging.instance.log("$e\n$s", level: LogLevel.Fatal);
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    final map = {
      "status": status.name,
      "payinAddress": payinAddress,
      "payoutAddress": payoutAddress,
      "fromCurrency": fromCurrency,
      "toCurrency": toCurrency,
      "id": id,
      "updatedAt": updatedAt,
      "expectedSendAmount": expectedSendAmountDecimal,
      "expectedReceiveAmount": expectedReceiveAmountDecimal,
      "createdAt": createdAt,
      "isPartner": isPartner,
      "depositReceivedAt": depositReceivedAt,
      "payinExtraIdName": payinExtraIdName,
      "payoutExtraIdName": payoutExtraIdName,
      "payinHash": payinHash,
      "payoutHash": payoutHash,
      "payinExtraId": payinExtraId,
      "payoutExtraId": payoutExtraId,
      "amountSend": amountSendDecimal,
      "amountReceive": amountReceiveDecimal,
      "tokensDestination": tokensDestination,
      "refundAddress": refundAddress,
      "refundExtraId": refundExtraId,
      "validUntil": validUntil,
      "verificationSent": verificationSent,
      "userId": userId,
      "payload": payload,
    };

    return map;
  }

  ExchangeTransactionStatus copyWith({
    ChangeNowTransactionStatus? status,
    String? payinAddress,
    String? payoutAddress,
    String? fromCurrency,
    String? toCurrency,
    String? updatedAt,
    String? expectedSendAmountDecimal,
    String? expectedReceiveAmountDecimal,
    String? createdAt,
    bool? isPartner,
    String? depositReceivedAt,
    String? payinExtraIdName,
    String? payoutExtraIdName,
    String? payinHash,
    String? payoutHash,
    String? payinExtraId,
    String? payoutExtraId,
    String? amountSendDecimal,
    String? amountReceiveDecimal,
    String? tokensDestination,
    String? refundAddress,
    String? refundExtraId,
    String? validUntil,
    bool? verificationSent,
    String? userId,
    Object? payload,
  }) {
    return ExchangeTransactionStatus(
      status: status ?? this.status,
      payinAddress: payinAddress ?? this.payinAddress,
      payoutAddress: payoutAddress ?? this.payoutAddress,
      fromCurrency: fromCurrency ?? this.fromCurrency,
      toCurrency: toCurrency ?? this.toCurrency,
      id: id,
      updatedAt: updatedAt ?? this.updatedAt,
      expectedSendAmountDecimal:
          expectedSendAmountDecimal ?? this.expectedSendAmountDecimal,
      expectedReceiveAmountDecimal:
          expectedReceiveAmountDecimal ?? this.expectedReceiveAmountDecimal,
      createdAt: createdAt ?? this.createdAt,
      isPartner: isPartner ?? this.isPartner,
      depositReceivedAt: depositReceivedAt ?? this.depositReceivedAt,
      payinExtraIdName: payinExtraIdName ?? this.payinExtraIdName,
      payoutExtraIdName: payoutExtraIdName ?? this.payoutExtraIdName,
      payinHash: payinHash ?? this.payinHash,
      payoutHash: payoutHash ?? this.payoutHash,
      payinExtraId: payinExtraId ?? this.payinExtraId,
      payoutExtraId: payoutExtraId ?? this.payoutExtraId,
      amountSendDecimal: amountSendDecimal ?? this.amountSendDecimal,
      amountReceiveDecimal: amountReceiveDecimal ?? this.amountReceiveDecimal,
      tokensDestination: tokensDestination ?? this.tokensDestination,
      refundAddress: refundAddress ?? this.refundAddress,
      refundExtraId: refundExtraId ?? this.refundExtraId,
      validUntil: validUntil ?? this.validUntil,
      verificationSent: verificationSent ?? this.verificationSent,
      userId: userId ?? this.userId,
      payload: payload ?? this.payload,
    );
  }

  @override
  String toString() {
    return "ExchangeTransactionStatus: ${toJson()}";
  }
}
