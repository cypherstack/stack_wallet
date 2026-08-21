import 'dart:ui';

import "../../services/shopinbit/src/models/ticket.dart";
import '../../themes/stack_colors.dart';

// Stable string identifiers — these names are persisted in the DB via
// `textEnum<E>()`. Renaming any value silently corrupts existing rows;
// add new values to the end instead.

enum ShopInBitCategory {
  concierge,
  travel,
  car;

  /// Value used for `service_type` in `POST /requests`. Matches the API
  /// spec strings exactly; equivalent to [name] for the current set.
  String get apiValue => name;

  String get label => switch (this) {
    .concierge => "Concierge",
    .travel => "Travel",
    .car => "Car",
  };
}

enum ShopInBitOrderStatus {
  pending,
  reviewing,
  offerAvailable,
  accepted,
  paymentPending,
  paid,
  shipping,
  delivered,
  closed,
  cancelled,
  refunded;

  String get label => switch (this) {
    .pending => "Pending",
    .reviewing => "Under review",
    .offerAvailable => "Offer available",
    .accepted => "Accepted",
    .paymentPending => "Awaiting payment",
    .paid => "Paid",
    .shipping => "Shipping",
    .delivered => "Delivered",
    .closed => "Closed",
    .cancelled => "Cancelled",
    .refunded => "Refunded",
  };

  /// Maps a raw API ticket state to a customer-facing status. Returns null
  /// for unrecognized states so the caller can decide whether to skip the
  /// row entirely or keep the previous value.
  static ShopInBitOrderStatus? fromTicketState(TicketState state) =>
      switch (state) {
        .newTicket => ShopInBitOrderStatus.pending,
        .checking ||
        .inProgress ||
        .replyNeeded => ShopInBitOrderStatus.reviewing,
        .offerAvailable => ShopInBitOrderStatus.offerAvailable,
        .clearing => ShopInBitOrderStatus.accepted,
        .pendingClose => ShopInBitOrderStatus.paymentPending,
        .shipped => ShopInBitOrderStatus.shipping,
        .fulfilled => ShopInBitOrderStatus.delivered,
        .closed || .merged => ShopInBitOrderStatus.closed,
        .closedCancelled => ShopInBitOrderStatus.cancelled,
        .refunded => ShopInBitOrderStatus.refunded,
        .unknown => null,
      };
}

extension ShopinbitStatusStyleExt on ShopInBitOrderStatus {
  Color getColor(StackColors colors) => switch (this) {
    .delivered => colors.accentColorGreen,
    .offerAvailable => colors.accentColorBlue,
    .pending || .reviewing => colors.accentColorYellow,
    .closed || .cancelled || .refunded => colors.textSubtitle1,
    _ => colors.accentColorDark,
  };
}
