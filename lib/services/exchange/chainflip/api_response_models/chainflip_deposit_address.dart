/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2026 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 *
 */

class ChainflipDepositAddress {
  final int? id;
  final String address;
  final int issuedBlock;
  final String network;
  final int channelId;
  final int sourceExpiryBlock;
  final String explorerUrl;
  final String channelOpeningFeeNative;
  final String destinationAddress;

  ChainflipDepositAddress({
    required this.id,
    required this.address,
    required this.issuedBlock,
    required this.network,
    required this.channelId,
    required this.sourceExpiryBlock,
    required this.explorerUrl,
    required this.channelOpeningFeeNative,
    required this.destinationAddress,
  });

  factory ChainflipDepositAddress.fromJson(Map<String, dynamic> json) {
    return ChainflipDepositAddress(
      id: (json["id"] as num?)?.toInt(),
      address: json["address"] as String? ?? "",
      issuedBlock: (json["issuedBlock"] as num?)?.toInt() ?? 0,
      network: json["network"] as String? ?? "",
      channelId: (json["channelId"] as num?)?.toInt() ?? 0,
      sourceExpiryBlock: (json["sourceExpiryBlock"] as num?)?.toInt() ?? 0,
      explorerUrl: json["explorerUrl"] as String? ?? "",
      channelOpeningFeeNative:
          json["channelOpeningFeeNative"] as String? ?? "0",
      destinationAddress: json["destinationAddress"] as String? ?? "",
    );
  }
}
