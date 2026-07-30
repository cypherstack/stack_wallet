import 'package:decimal/decimal.dart';

import 'cg_parse_utils.dart';

class CgEstimateResult {
  final String exchange;
  final Decimal amount;
  final int kycScore;
  final bool? safeRouteOk;
  final Decimal? safeRouteScore;

  CgEstimateResult({
    required this.exchange,
    required this.amount,
    required this.kycScore,
    required this.safeRouteOk,
    required this.safeRouteScore,
  });

  factory CgEstimateResult.fromMap(Map<String, dynamic> map) {
    return CgEstimateResult(
      exchange: requireCgString(map, "Exchange"),
      amount: requireCgDecimal(map, "Amount"),
      kycScore: requireCgInt(map, "KYCScore"),
      safeRouteOk: map["SafeRouteOK"] as bool?,
      safeRouteScore: Decimal.tryParse(map["SafeRouteScore"].toString()),
    );
  }
}

class CgEstimatesResponse {
  final List<CgEstimateResult> results;
  final Decimal min;
  final Decimal tradeValueFiat;
  final Decimal tradeValueBtc;
  final int estimateId;

  CgEstimatesResponse({
    required this.results,
    required this.min,
    required this.tradeValueFiat,
    required this.tradeValueBtc,
    required this.estimateId,
  });

  factory CgEstimatesResponse.fromMap(Map<String, dynamic> map) {
    final resultsRaw = map["Results"];
    if (resultsRaw is! List) {
      throw CgResponseFormatException("Missing required field 'Results'");
    }
    return CgEstimatesResponse(
      results: resultsRaw
          .map(
            (e) =>
                CgEstimateResult.fromMap(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      min: requireCgDecimal(map, "Min"),
      tradeValueFiat: requireCgDecimal(map, "TradeValue_fiat"),
      tradeValueBtc: requireCgDecimal(map, "TradeValue_btc"),
      estimateId: requireCgInt(map, "EstimateId"),
    );
  }
}
