import "dart:async";

import "package:flutter/material.dart";

import "../../../db/isar/main_db.dart";
import "../../../models/shopinbit/shopinbit_order_model.dart";
import "../../../notifications/show_flush_bar.dart";
import "../../../services/shopinbit/shopinbit_service.dart";
import "../../../utilities/util.dart";
import "../shopinbit_order_created.dart";

/// Submits a ShopinBit request to the API and navigates to the order-created
/// view on success.
///
/// Used by the concierge, travel and generic flows. The car flow has its own
/// pre-payment branching (fee view) and does not call this helper.
Future<void> submitShopInBitRequest(
  BuildContext context,
  ShopInBitOrderModel model,
  ShopInBitService service,
) async {
  try {
    final String customerKey = await service.ensureCustomerKey();

    assert(
      model.category != null,
      "Step 4 reached with null category: Step 2 must set category before"
      " reaching Step 4",
    );

    // API service_type: travel requests use "concierge" because the
    // ShopinBit API routes both through the same concierge pipeline.
    // Travel-specific details are captured in the structured comment field.
    final String categoryStr = switch (model.category) {
      ShopInBitCategory.concierge => "concierge",
      ShopInBitCategory.travel => "concierge",
      ShopInBitCategory.car => "car",
      null => throw StateError("category must be non-null at Step 4 submit"),
    };

    final resp = await service.client.createRequest(
      customerPseudonym: model.displayName,
      externalCustomerKey: customerKey,
      serviceType: categoryStr,
      comment: model.requestDescription,
      deliveryCountry: model.deliveryCountry,
    );

    if (resp.hasError) {
      if (context.mounted) {
        unawaited(
          showFloatingFlushBar(
            type: FlushBarType.warning,
            message: resp.exception?.message ?? "Failed to create request",
            context: context,
          ),
        );
      }
      return;
    }

    final ref = resp.value!;
    model
      ..apiTicketId = ref.id
      ..ticketId = ref.number
      ..status = ShopInBitOrderStatus.pending;
    await MainDB.instance.putShopInBitTicket(model.toIsarTicket());

    if (!context.mounted) return;
    if (Util.isDesktop) {
      Navigator.of(context, rootNavigator: true).pop();
      unawaited(
        showDialog<void>(
          context: context,
          builder: (_) => ShopInBitOrderCreated(model: model),
        ),
      );
    } else {
      unawaited(
        Navigator.of(
          context,
        ).pushNamed(ShopInBitOrderCreated.routeName, arguments: model),
      );
    }
  } catch (e) {
    if (context.mounted) {
      unawaited(
        showFloatingFlushBar(
          type: FlushBarType.warning,
          message: "Failed to create request: $e",
          context: context,
        ),
      );
    }
  }
}
