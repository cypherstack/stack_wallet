import 'dart:ui';

import '../../../../themes/stack_colors.dart';
import 'order_item.dart';

enum CakePayOrderStatus {
  new_('new'),
  expiredButStillPending('expired_but_still_pending'),
  expired('expired'),
  failed('failed'),
  paid('paid'),
  paidPartial('paid_partial'),
  pendingPurchase('pending_purchase'),
  purchaseProcessing('purchase_processing'),
  purchased('purchased'),
  pendingEmail('pending_email'),
  complete('complete'),
  pendingRefund('pending_refund'),
  refunded('refunded');

  final String value;
  const CakePayOrderStatus(this.value);

  static CakePayOrderStatus fromString(String s) {
    return CakePayOrderStatus.values.firstWhere(
      (e) => e.value == s,
      orElse: () => CakePayOrderStatus.new_,
    );
  }

  String get label => switch (this) {
    CakePayOrderStatus.new_ => "New",
    CakePayOrderStatus.expiredButStillPending => "Expired (pending)",
    CakePayOrderStatus.expired => "Expired",
    CakePayOrderStatus.failed => "Failed",
    CakePayOrderStatus.paid => "Paid",
    CakePayOrderStatus.paidPartial => "Partially paid",
    CakePayOrderStatus.pendingPurchase => "Pending purchase",
    CakePayOrderStatus.purchaseProcessing => "Processing",
    CakePayOrderStatus.purchased => "Purchased",
    CakePayOrderStatus.pendingEmail => "Pending email",
    CakePayOrderStatus.complete => "Complete",
    CakePayOrderStatus.pendingRefund => "Pending refund",
    CakePayOrderStatus.refunded => "Refunded",
  };

  Color color(StackColors themeColors) {
    return switch (this) {
      CakePayOrderStatus.complete ||
      CakePayOrderStatus.purchased => themeColors.accentColorGreen,
      CakePayOrderStatus.new_ ||
      CakePayOrderStatus.paid ||
      CakePayOrderStatus.paidPartial => themeColors.accentColorBlue,
      CakePayOrderStatus.pendingPurchase ||
      CakePayOrderStatus.purchaseProcessing ||
      CakePayOrderStatus.pendingEmail ||
      CakePayOrderStatus.expiredButStillPending =>
        themeColors.accentColorYellow,
      CakePayOrderStatus.expired ||
      CakePayOrderStatus.failed ||
      CakePayOrderStatus.pendingRefund ||
      CakePayOrderStatus.refunded => themeColors.textSubtitle1,
    };
  }
}

/// A single crypto payment option within [CakePayOrder.paymentOptions].
///
/// The API returns `payment_data` as a map whose keys are crypto tickers
/// (e.g. `"BTC"`, `"XMR"`) each mapping to an object with `amount_from`
/// and `address`.
class CakePayPaymentOption {
  final String ticker;
  final double amountFrom;
  final String address;

  CakePayPaymentOption({
    required this.ticker,
    required this.amountFrom,
    required this.address,
  });

  @override
  String toString() => 'CakePayPaymentOption($ticker, $amountFrom, $address)';
}

class CakePayOrder {
  final String orderId;
  final CakePayOrderStatus status;
  final String? amountUsd;
  final List<CakePayOrderItem>? cards;

  /// Raw `payment_data` map preserved for backward compatibility.
  ///
  /// Prefer [paymentOptions] for structured access to crypto payment
  /// methods.
  final Map<String, dynamic>? paymentData;

  /// Structured crypto payment options parsed from `payment_data`.
  ///
  /// Keys are crypto tickers (e.g. `"BTC"`, `"XMR"`, `"BTC_LN"`).
  final Map<String, CakePayPaymentOption>? paymentOptions;

  /// Unix-millis timestamp when the payment window expires.
  final int? expirationTime;

  /// Unix-millis timestamp when the invoice was created.
  final int? invoiceTime;

  final String? commission;
  final double? markupPercent;
  final String? createdAt;
  final String? externalOrderId;

  CakePayOrder({
    required this.orderId,
    required this.status,
    this.amountUsd,
    this.cards,
    this.paymentData,
    this.paymentOptions,
    this.expirationTime,
    this.invoiceTime,
    this.commission,
    this.markupPercent,
    this.createdAt,
    this.externalOrderId,
  });

  factory CakePayOrder.fromJson(Map<String, dynamic> json) {
    final rawCards = json['cards'];
    List<CakePayOrderItem>? cards;
    if (rawCards is List) {
      cards = rawCards
          .whereType<Map<String, dynamic>>()
          .map(CakePayOrderItem.fromJson)
          .toList();
    }

    // ---- payment_data parsing ----
    final rawPayment = json['payment_data'];
    Map<String, dynamic>? paymentData;
    Map<String, CakePayPaymentOption>? paymentOptions;
    int? expirationTime;
    int? invoiceTime;

    if (rawPayment is Map<String, dynamic>) {
      paymentData = rawPayment;

      // Extract top-level timing fields.
      expirationTime = rawPayment['expiration_time'] as int?;
      invoiceTime = rawPayment['invoice_time'] as int?;

      // Each remaining key whose value is a Map is a crypto payment option.
      paymentOptions = {};
      for (final entry in rawPayment.entries) {
        final v = entry.value;
        if (v is Map<String, dynamic>) {
          final amountFrom = _toDouble(v['amount_from']);
          final address = v['address']?.toString();
          if (amountFrom != null && address != null) {
            paymentOptions[entry.key] = CakePayPaymentOption(
              ticker: entry.key,
              amountFrom: amountFrom,
              address: address,
            );
          }
        }
      }
      if (paymentOptions.isEmpty) {
        paymentOptions = null;
      }
    }

    return CakePayOrder(
      orderId: (json['order_id'] ?? json['id'])?.toString() ?? '',
      status: CakePayOrderStatus.fromString(
        (json['status'] ?? 'new') as String,
      ),
      amountUsd: json['amount_usd']?.toString(),
      cards: cards,
      paymentData: paymentData,
      paymentOptions: paymentOptions,
      expirationTime: expirationTime,
      invoiceTime: invoiceTime,
      commission: json['commission']?.toString(),
      markupPercent: _toDouble(json['markup_percent']),
      createdAt: json['created_at'] as String?,
      externalOrderId: json['external_order_id'] as String?,
    );
  }

  CakePayOrder copyWith({CakePayOrderStatus? status}) {
    return CakePayOrder(
      orderId: orderId,
      status: status ?? this.status,
      amountUsd: amountUsd,
      cards: cards,
      paymentData: paymentData,
      paymentOptions: paymentOptions,
      expirationTime: expirationTime,
      invoiceTime: invoiceTime,
      commission: commission,
      markupPercent: markupPercent,
      createdAt: createdAt,
      externalOrderId: externalOrderId,
    );
  }

  @override
  String toString() => 'CakePayOrder($orderId, ${status.value})';
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}
