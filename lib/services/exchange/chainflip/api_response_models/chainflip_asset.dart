/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2026 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 *
 */

class ChainflipAsset {
  final String id;
  final String ticker;
  final String name;
  final String network;
  final String? contractAddress;
  final String assetLogo;
  final String networkLogo;
  final int decimals;
  final bool enabled;
  final String direction;
  final String minimalAmountNative;
  final num? usdPrice;

  ChainflipAsset({
    required this.id,
    required this.ticker,
    required this.name,
    required this.network,
    required this.contractAddress,
    required this.assetLogo,
    required this.networkLogo,
    required this.decimals,
    required this.enabled,
    required this.direction,
    required this.minimalAmountNative,
    required this.usdPrice,
  });

  factory ChainflipAsset.fromJson(Map<String, dynamic> json) {
    return ChainflipAsset(
      id: json["id"] as String,
      ticker: json["ticker"] as String,
      name: json["name"] as String,
      network: json["network"] as String,
      contractAddress: json["contractAddress"] as String?,
      assetLogo: json["assetLogo"] as String? ?? "",
      networkLogo: json["networkLogo"] as String? ?? "",
      decimals: (json["decimals"] as num).toInt(),
      enabled: json["enabled"] as bool? ?? true,
      direction: json["direction"] as String? ?? "both",
      minimalAmountNative: json["minimalAmountNative"] as String? ?? "0",
      usdPrice: json["usdPrice"] as num?,
    );
  }
}
