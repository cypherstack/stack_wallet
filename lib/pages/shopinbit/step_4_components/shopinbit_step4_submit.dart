import "dart:async";

import "package:flutter/material.dart";

import "../../../models/shopinbit/shopinbit_request_draft.dart";
import "../../../services/shopinbit/shopinbit_service.dart";
import "../../../services/shopinbit/src/models/ticket.dart";
import "../../../utilities/logger.dart";
import "../../../utilities/util.dart";
import "../../../widgets/stack_dialog.dart";
import "../shopinbit_order_created.dart";

/// Submits a ShopinBit request to the API and navigates to the order-created
/// view on success.
///
/// Used by the concierge, travel and generic flows. The car flow has its own
/// pre-payment branching (fee view) and does not call this helper.
///
/// All persistence lives in [ShopInBitService.createRequest], which inserts
/// the fully-provenanced ticket row and kicks off a background refresh, so the
/// UI only has to hand over the [draft] and route on the returned id.
Future<void> submitShopInBitRequest(
  BuildContext context,
  ShopinbitRequestDraft draft,
  ShopInBitService service,
) async {
  try {
    final TicketRef? ref = await service.createRequest(
      category: draft.category,
      comment: draft.requestDescription,
      deliveryCountry: draft.deliveryCountryCode,
      deliveryState: draft.deliveryState,
      voucherCode: draft.voucherCode,
    );

    if (ref == null) {
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          useRootNavigator: Util.isDesktop,
          builder: (context) => StackOkDialog(
            title: "Failed to create request",
            maxWidth: Util.isDesktop ? 500 : null,
            message: "Please try again in a moment.",
            desktopPopRootNavigator: Util.isDesktop,
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;

    unawaited(
      Navigator.of(
        context,
      ).pushNamed(ShopInBitOrderCreated.routeName, arguments: ref.id),
    );
  } catch (e, s) {
    Logging.instance.e(
      "Failed to create ShopInBit request",
      error: e,
      stackTrace: s,
    );
    if (context.mounted) {
      await showDialog<void>(
        context: context,
        useRootNavigator: Util.isDesktop,
        builder: (context) => StackOkDialog(
          title: "Failed to create request",
          maxWidth: Util.isDesktop ? 500 : null,
          message: e.toString(),
          desktopPopRootNavigator: Util.isDesktop,
        ),
      );
    }
  }
}
