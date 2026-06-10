class VoucherInfo {
  final bool valid;
  final String? voucherCode;
  final double? discountAmount;
  final String? voucherType;
  final int? priorityLevel;
  final int? usageCount;
  final int? maxUsage;
  final bool? isUnlimited;
  final int? remainingUses;
  final String? validFrom;
  final String? validUntil;
  final String? error;

  VoucherInfo({
    required this.valid,
    this.voucherCode,
    this.discountAmount,
    this.voucherType,
    this.priorityLevel,
    this.usageCount,
    this.maxUsage,
    this.isUnlimited,
    this.remainingUses,
    this.validFrom,
    this.validUntil,
    this.error,
  });

  factory VoucherInfo.fromJson(Map<String, dynamic> json) {
    return VoucherInfo(
      valid: json['valid'] as bool? ?? false,
      voucherCode: json['voucher_code'] as String?,
      discountAmount: (json['discount_amount'] as num?)?.toDouble(),
      voucherType: json['voucher_type'] as String?,
      priorityLevel: json['priority_level'] as int?,
      usageCount: json['usage_count'] as int?,
      maxUsage: json['max_usage'] as int?,
      isUnlimited: json['is_unlimited'] as bool?,
      remainingUses: json['remaining_uses'] as int?,
      validFrom: json['valid_from'] as String?,
      validUntil: json['valid_until'] as String?,
      error: json['error'] as String?,
    );
  }
}

class VipRedemptionResult {
  final int ticketId;
  final String ticketNumber;
  final String externalCustomerKey;
  final String voucherCode;

  VipRedemptionResult({
    required this.ticketId,
    required this.ticketNumber,
    required this.externalCustomerKey,
    required this.voucherCode,
  });

  factory VipRedemptionResult.fromJson(Map<String, dynamic> json) {
    return VipRedemptionResult(
      ticketId: json['ticket_id'] is int
          ? json['ticket_id'] as int
          : int.parse(json['ticket_id'].toString()),
      ticketNumber: json['ticket_number'] as String,
      externalCustomerKey: json['external_customer_key'] as String,
      voucherCode: json['voucher_code'] as String,
    );
  }
}
