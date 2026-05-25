import 'package:decimal/decimal.dart';

import '../helpers/enums.dart';
import '../helpers/parse_decimal.dart';
import 'exolix_base_dto.dart';
import 'exolix_coin_info.dart';
import 'exolix_hash.dart';

/// A full transaction object.
///
/// Coin amounts and the exchange rate are [Decimal] for precision.
class ExolixTransaction extends ExolixBaseDto {
  final String id;
  final Decimal amount;
  final Decimal amountTo;
  final ExolixCoinInfo coinFrom;
  final ExolixCoinInfo coinTo;
  final String? comment;
  final DateTime? createdAt;
  final String depositAddress;
  final String? depositExtraId;
  final String withdrawalAddress;
  final String? withdrawalExtraId;
  final ExolixHash hashIn;
  final ExolixHash hashOut;
  final Decimal rate;
  final ExolixRateType rateType;
  final String? refundAddress;
  final String? refundExtraId;
  final ExolixTransactionStatus status;

  /// "source" is documented for the listing endpoint but not for the single
  /// fetch. Nullable so it round-trips safely either way.
  final String? source;

  ExolixTransaction({
    required this.id,
    required this.amount,
    required this.amountTo,
    required this.coinFrom,
    required this.coinTo,
    required this.comment,
    required this.createdAt,
    required this.depositAddress,
    required this.depositExtraId,
    required this.withdrawalAddress,
    required this.withdrawalExtraId,
    required this.hashIn,
    required this.hashOut,
    required this.rate,
    required this.rateType,
    required this.refundAddress,
    required this.refundExtraId,
    required this.status,
    required this.source,
  });

  factory ExolixTransaction.fromJson(Map<String, dynamic> json) {
    final dynamic coinFromRaw = json["coinFrom"];
    final dynamic coinToRaw = json["coinTo"];
    final dynamic hashInRaw = json["hashIn"];
    final dynamic hashOutRaw = json["hashOut"];

    DateTime? parsedCreatedAt;
    final dynamic createdAtRaw = json["createdAt"];
    if (createdAtRaw is String && createdAtRaw.isNotEmpty) {
      parsedCreatedAt = DateTime.tryParse(createdAtRaw);
    }

    ExolixRateType parsedRateType;
    final dynamic rateTypeRaw = json["rateType"];
    if (rateTypeRaw == "float") {
      parsedRateType = ExolixRateType.float;
    } else {
      // Default per docs is fixed.
      parsedRateType = ExolixRateType.fixed;
    }

    return ExolixTransaction(
      id: json["id"] as String? ?? "",
      amount: parseDecimal(json["amount"]),
      amountTo: parseDecimal(json["amountTo"]),
      coinFrom: (coinFromRaw is Map)
          ? ExolixCoinInfo.fromJson(Map<String, dynamic>.from(coinFromRaw))
          : ExolixCoinInfo(
              coinCode: "",
              coinName: "",
              network: "",
              networkName: "",
              networkShortName: null,
              icon: null,
              memoName: null,
              contract: null,
            ),
      coinTo: (coinToRaw is Map)
          ? ExolixCoinInfo.fromJson(Map<String, dynamic>.from(coinToRaw))
          : ExolixCoinInfo(
              coinCode: "",
              coinName: "",
              network: "",
              networkName: "",
              networkShortName: null,
              icon: null,
              memoName: null,
              contract: null,
            ),
      comment: json["comment"] as String?,
      createdAt: parsedCreatedAt,
      depositAddress: json["depositAddress"] as String? ?? "",
      depositExtraId: json["depositExtraId"] as String?,
      withdrawalAddress: json["withdrawalAddress"] as String? ?? "",
      withdrawalExtraId: json["withdrawalExtraId"] as String?,
      hashIn: (hashInRaw is Map)
          ? ExolixHash.fromJson(Map<String, dynamic>.from(hashInRaw))
          : ExolixHash(hash: null, link: null),
      hashOut: (hashOutRaw is Map)
          ? ExolixHash.fromJson(Map<String, dynamic>.from(hashOutRaw))
          : ExolixHash(hash: null, link: null),
      rate: parseDecimal(json["rate"]),
      rateType: parsedRateType,
      refundAddress: json["refundAddress"] as String?,
      refundExtraId: json["refundExtraId"] as String?,
      status: ExolixTransactionStatus.fromString(json["status"] as String?),
      source: json["source"] as String?,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "amount": amount.toString(),
      "amountTo": amountTo.toString(),
      "coinFrom": coinFrom.toMap(),
      "coinTo": coinTo.toMap(),
      "comment": comment,
      "createdAt": createdAt?.toIso8601String(),
      "depositAddress": depositAddress,
      "depositExtraId": depositExtraId,
      "withdrawalAddress": withdrawalAddress,
      "withdrawalExtraId": withdrawalExtraId,
      "hashIn": hashIn.toMap(),
      "hashOut": hashOut.toMap(),
      "rate": rate.toString(),
      "rateType": rateType.apiValue,
      "refundAddress": refundAddress,
      "refundExtraId": refundExtraId,
      "status": status.name,
      "source": source,
    };
  }
}
