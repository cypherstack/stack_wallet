import 'package:decimal/decimal.dart';
import 'package:hive/hive.dart';
import 'package:epicmobile/models/exchange/change_now/exchange_transaction_status.dart';
import 'package:uuid/uuid.dart';

part '../../type_adaptors/exchange_transaction.g.dart';

@Deprecated(
    "Do not use. Migrated to Trade in db_version_migration to hive_data_version 2")
// @HiveType(typeId: 13)
class ExchangeTransaction {
  /// You can use it to get transaction status at the Transaction status API endpoint
  // @HiveField(0)
  final String id;

  /// We generate it when creating a transaction
  // @HiveField(1)
  final String payinAddress;

  /// The wallet address that will receive the exchanged funds
  // @HiveField(2)
  final String payoutAddress;

  /// We generate it when creating a transaction
  // @HiveField(3)
  final String payinExtraId;

  /// Extra ID that you send when creating a transaction
  // @HiveField(4)
  final String payoutExtraId;

  /// Ticker of the currency you want to exchange
  // @HiveField(5)
  final String fromCurrency;

  /// Ticker of the currency you want to receive
  // @HiveField(6)
  final String toCurrency;

  /// Amount of currency you want to receive
  // @HiveField(7)
  final String amount;

  /// Refund address (if you specified it)
  // @HiveField(8)
  final String refundAddress;

  /// Refund Extra ID (if you specified it)
  // @HiveField(9)
  final String refundExtraId;

  /// Field name currency Extra ID (e.g. Memo, Extra ID)
  // @HiveField(10)
  final String payoutExtraIdName;

  // @HiveField(11)
  final String uuid;

  // @HiveField(12)
  final DateTime date;

  // @HiveField(13)
  final String statusString;

  // @HiveField(14)
  final ExchangeTransactionStatus? statusObject;

  ExchangeTransaction({
    required this.id,
    required this.payinAddress,
    required this.payoutAddress,
    required this.payinExtraId,
    required this.payoutExtraId,
    required this.fromCurrency,
    required this.toCurrency,
    required this.amount,
    required this.refundAddress,
    required this.refundExtraId,
    required this.payoutExtraIdName,
    required this.uuid,
    required this.date,
    required this.statusString,
    required this.statusObject,
  });

  /// Important to pass a "date": DateTime in or it will default to 1970
  factory ExchangeTransaction.fromJson(Map<String, dynamic> json) {
    try {
      return ExchangeTransaction(
        id: json["id"] as String,
        payinAddress: json["payinAddress"] as String? ?? "",
        payoutAddress: json["payoutAddress"] as String? ?? "",
        payinExtraId: json["payinExtraId"] as String? ?? "",
        payoutExtraId: json["payoutExtraId"] as String? ?? "",
        fromCurrency: json["fromCurrency"] as String,
        toCurrency: json["toCurrency"] as String,
        amount: Decimal.parse(json["amount"].toString()).toStringAsFixed(12),
        refundAddress: json["refundAddress"] as String? ?? "",
        refundExtraId: json["refundExtraId"] as String? ?? "",
        payoutExtraIdName: json["payoutExtraIdName"] as String? ?? "",
        uuid: json["uuid"] as String? ?? const Uuid().v1(),
        date: DateTime.tryParse(json["date"] as String? ?? "") ??
            DateTime.fromMillisecondsSinceEpoch(0),
        statusString: json["statusString"] as String? ?? "",
        statusObject: json["statusObject"] is Map<String, dynamic>
            ? ExchangeTransactionStatus.fromJson(
                json["statusObject"] as Map<String, dynamic>)
            : null,
      );
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    final map = {
      "id": id,
      "payinAddress": payinAddress,
      "payoutAddress": payoutAddress,
      "payinExtraId": payinExtraId,
      "payoutExtraId": payoutExtraId,
      "fromCurrency": fromCurrency,
      "toCurrency": toCurrency,
      "amount": amount,
      "refundAddress": refundAddress,
      "refundExtraId": refundExtraId,
      "payoutExtraIdName": payoutExtraIdName,
      "uuid": uuid,
      "date": date.toString(),
      "statusString": statusString,
      "statusObject": statusObject?.toJson(),
    };

    return map;
  }

  ExchangeTransaction copyWith({
    String? payinAddress,
    String? payoutAddress,
    String? payinExtraId,
    String? payoutExtraId,
    String? fromCurrency,
    String? toCurrency,
    String? amount,
    String? refundAddress,
    String? refundExtraId,
    String? payoutExtraIdName,
    String? statusString,
    ExchangeTransactionStatus? statusObject,
  }) {
    return ExchangeTransaction(
      id: id,
      payinAddress: payinAddress ?? this.payinAddress,
      payoutAddress: payoutAddress ?? this.payoutAddress,
      payinExtraId: payinExtraId ?? this.payinExtraId,
      payoutExtraId: payoutExtraId ?? this.payoutExtraId,
      fromCurrency: fromCurrency ?? this.fromCurrency,
      toCurrency: toCurrency ?? this.toCurrency,
      amount: amount ?? this.amount,
      refundAddress: refundAddress ?? this.refundAddress,
      refundExtraId: refundExtraId ?? this.refundExtraId,
      payoutExtraIdName: payoutExtraIdName ?? this.payoutExtraIdName,
      uuid: uuid,
      date: date,
      statusString: statusString ?? this.statusString,
      statusObject: statusObject ?? this.statusObject,
    );
  }

  @override
  String toString() {
    return "ExchangeTransaction: ${toMap()}";
  }
}
