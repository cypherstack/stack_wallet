/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2026 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 *
 */

class ChainflipQuote {
  final String type;
  final String ingressAmountNative;
  final String egressAmountNative;
  final num? estimatedPrice;
  final num? recommendedSlippageTolerancePercent;
  final int? recommendedRetryDurationInBlocks;
  final num? recommendedLivePriceSlippageTolerancePercent;
  final bool lowLiquidityWarning;

  ChainflipQuote({
    required this.type,
    required this.ingressAmountNative,
    required this.egressAmountNative,
    required this.estimatedPrice,
    required this.recommendedSlippageTolerancePercent,
    required this.recommendedRetryDurationInBlocks,
    required this.recommendedLivePriceSlippageTolerancePercent,
    required this.lowLiquidityWarning,
  });

  factory ChainflipQuote.fromJson(Map<String, dynamic> json) {
    return ChainflipQuote(
      type: json["type"] as String? ?? "regular",
      ingressAmountNative: json["ingressAmountNative"] as String? ?? "0",
      egressAmountNative: json["egressAmountNative"] as String? ?? "0",
      estimatedPrice: json["estimatedPrice"] as num?,
      recommendedSlippageTolerancePercent:
          json["recommendedSlippageTolerancePercent"] as num?,
      recommendedRetryDurationInBlocks:
          (json["recommendedRetryDurationInBlocks"] as num?)?.toInt(),
      recommendedLivePriceSlippageTolerancePercent:
          json["recommendedLivePriceSlippageTolerancePercent"] as num?,
      lowLiquidityWarning: json["lowLiquidityWarning"] as bool? ?? false,
    );
  }
}
