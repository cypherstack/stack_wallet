/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2026 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 *
 */

class ChainflipSwapStatus {
  final int? id;
  final bool pending;
  final String state;
  final String? swapId;
  final String sourceAsset;
  final String destinationAsset;
  final String destinationAddress;
  final ChainflipDepositChannel? depositChannel;
  final ChainflipFillOrKillParams? fillOrKillParams;
  final ChainflipDeposit? deposit;
  final ChainflipSwap? swap;
  final ChainflipEgress? swapEgress;
  final ChainflipEgress? refundEgress;
  final ChainflipEgress? fallbackEgress;
  final Map<String, dynamic> raw;

  ChainflipSwapStatus({
    required this.id,
    required this.pending,
    required this.state,
    required this.swapId,
    required this.sourceAsset,
    required this.destinationAsset,
    required this.destinationAddress,
    required this.depositChannel,
    required this.fillOrKillParams,
    required this.deposit,
    required this.swap,
    required this.swapEgress,
    required this.refundEgress,
    required this.fallbackEgress,
    required this.raw,
  });

  factory ChainflipSwapStatus.pending(int? id) {
    return ChainflipSwapStatus(
      id: id,
      pending: true,
      state: "waiting",
      swapId: null,
      sourceAsset: "",
      destinationAsset: "",
      destinationAddress: "",
      depositChannel: null,
      fillOrKillParams: null,
      deposit: null,
      swap: null,
      swapEgress: null,
      refundEgress: null,
      fallbackEgress: null,
      raw: const <String, dynamic>{},
    );
  }

  factory ChainflipSwapStatus.fromJson(Map<String, dynamic> json) {
    final statusJson = _asMap(json["status"]) ?? json;
    final depositChannelJson = _asMap(statusJson["depositChannel"]);
    final fillOrKillJson = _asMap(statusJson["fillOrKillParams"]);
    final depositJson = _asMap(statusJson["deposit"]);
    final swapJson = _asMap(statusJson["swap"]);
    final swapEgressJson = _asMap(statusJson["swapEgress"]);
    final refundEgressJson = _asMap(statusJson["refundEgress"]);
    final fallbackEgressJson = _asMap(statusJson["fallbackEgress"]);
    return ChainflipSwapStatus(
      id: (json["id"] as num?)?.toInt(),
      pending: false,
      state: statusJson["state"] as String? ?? "waiting",
      swapId: statusJson["swapId"] as String?,
      sourceAsset: statusJson["sourceAsset"] as String? ?? "",
      destinationAsset: statusJson["destinationAsset"] as String? ?? "",
      destinationAddress: statusJson["destinationAddress"] as String? ?? "",
      depositChannel: depositChannelJson == null
          ? null
          : ChainflipDepositChannel.fromJson(depositChannelJson),
      fillOrKillParams: fillOrKillJson == null
          ? null
          : ChainflipFillOrKillParams.fromJson(fillOrKillJson),
      deposit: depositJson == null
          ? null
          : ChainflipDeposit.fromJson(depositJson),
      swap: swapJson == null ? null : ChainflipSwap.fromJson(swapJson),
      swapEgress: swapEgressJson == null
          ? null
          : ChainflipEgress.fromJson(swapEgressJson),
      refundEgress: refundEgressJson == null
          ? null
          : ChainflipEgress.fromJson(refundEgressJson),
      fallbackEgress: fallbackEgressJson == null
          ? null
          : ChainflipEgress.fromJson(fallbackEgressJson),
      raw: statusJson,
    );
  }

  static Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<dynamic, dynamic>) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }
}

class ChainflipDepositChannel {
  final String? id;
  final String? depositAddress;
  final int? createdAt;
  final String? sourceChainExpiryBlock;

  ChainflipDepositChannel({
    required this.id,
    required this.depositAddress,
    required this.createdAt,
    required this.sourceChainExpiryBlock,
  });

  factory ChainflipDepositChannel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ChainflipDepositChannel(
        id: null,
        depositAddress: null,
        createdAt: null,
        sourceChainExpiryBlock: null,
      );
    }
    return ChainflipDepositChannel(
      id: json["id"] as String?,
      depositAddress: json["depositAddress"] as String?,
      createdAt: (json["createdAt"] as num?)?.toInt(),
      sourceChainExpiryBlock: json["sourceChainExpiryBlock"]?.toString(),
    );
  }
}

class ChainflipFillOrKillParams {
  final String? refundAddress;

  ChainflipFillOrKillParams({required this.refundAddress});

  factory ChainflipFillOrKillParams.fromJson(Map<String, dynamic>? json) {
    return ChainflipFillOrKillParams(
      refundAddress: json?["refundAddress"] as String?,
    );
  }
}

class ChainflipDeposit {
  final String? amountNative;
  final num? amount;
  final String? transactionReference;
  final Map<String, dynamic>? failure;

  ChainflipDeposit({
    required this.amountNative,
    required this.amount,
    required this.transactionReference,
    required this.failure,
  });

  factory ChainflipDeposit.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ChainflipDeposit(
        amountNative: null,
        amount: null,
        transactionReference: null,
        failure: null,
      );
    }
    return ChainflipDeposit(
      amountNative: json["amountNative"] as String?,
      amount: json["amount"] as num?,
      transactionReference: json["transactionReference"] as String?,
      failure: _asMap(json["failure"]),
    );
  }

  static Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<dynamic, dynamic>) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }
}

class ChainflipSwap {
  final String? originalInputAmountNative;
  final String? swappedInputAmountNative;
  final String? swappedOutputAmountNative;

  ChainflipSwap({
    required this.originalInputAmountNative,
    required this.swappedInputAmountNative,
    required this.swappedOutputAmountNative,
  });

  factory ChainflipSwap.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ChainflipSwap(
        originalInputAmountNative: null,
        swappedInputAmountNative: null,
        swappedOutputAmountNative: null,
      );
    }
    return ChainflipSwap(
      originalInputAmountNative: json["originalInputAmountNative"] as String?,
      swappedInputAmountNative: json["swappedInputAmountNative"] as String?,
      swappedOutputAmountNative: json["swappedOutputAmountNative"] as String?,
    );
  }
}

class ChainflipEgress {
  final String? amountNative;
  final num? amount;
  final String? transactionReference;
  final Map<String, dynamic>? failure;

  ChainflipEgress({
    required this.amountNative,
    required this.amount,
    required this.transactionReference,
    required this.failure,
  });

  factory ChainflipEgress.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ChainflipEgress(
        amountNative: null,
        amount: null,
        transactionReference: null,
        failure: null,
      );
    }
    return ChainflipEgress(
      amountNative: json["amountNative"] as String?,
      amount: json["amount"] as num?,
      transactionReference: json["transactionReference"] as String?,
      failure: _asMap(json["failure"]),
    );
  }

  static Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<dynamic, dynamic>) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }
}
