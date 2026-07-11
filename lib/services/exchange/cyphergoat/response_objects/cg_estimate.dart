class CgEstimateResult {
  final String exchange;
  final double amount;
  final int kycScore;
  final bool safeRouteOk;
  final double safeRouteScore;

  CgEstimateResult({
    required this.exchange,
    required this.amount,
    required this.kycScore,
    required this.safeRouteOk,
    required this.safeRouteScore,
  });

  factory CgEstimateResult.fromMap(Map<String, dynamic> map) {
    return CgEstimateResult(
      exchange: map["Exchange"] as String? ?? "",
      amount: (map["Amount"] as num?)?.toDouble() ?? 0.0,
      kycScore: (map["KYCScore"] as num?)?.toInt() ?? 0,
      safeRouteOk: map["SafeRouteOK"] as bool? ?? false,
      safeRouteScore: (map["SafeRouteScore"] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CgEstimatesResponse {
  final List<CgEstimateResult> results;
  final double min;
  final double tradeValueFiat;
  final double tradeValueBtc;
  final int estimateId;

  CgEstimatesResponse({
    required this.results,
    required this.min,
    required this.tradeValueFiat,
    required this.tradeValueBtc,
    required this.estimateId,
  });

  factory CgEstimatesResponse.fromMap(Map<String, dynamic> map) {
    final resultsRaw = map["Results"] as List<dynamic>? ?? [];
    return CgEstimatesResponse(
      results: resultsRaw
          .map((e) => CgEstimateResult.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      min: (map["Min"] as num?)?.toDouble() ?? 0.0,
      tradeValueFiat: (map["TradeValue_fiat"] as num?)?.toDouble() ?? 0.0,
      tradeValueBtc: (map["TradeValue_btc"] as num?)?.toDouble() ?? 0.0,
      estimateId: (map["EstimateId"] as num?)?.toInt() ?? 0,
    );
  }
}
