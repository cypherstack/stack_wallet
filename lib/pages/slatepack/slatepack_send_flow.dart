import 'dart:async';

import 'package:flutter/material.dart';

import '../../db/isar/main_db.dart';
import '../../models/isar/models/transaction_note.dart';
import '../../models/slatepack_models.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/amount/amount.dart';
import '../../utilities/exception_message.dart';
import '../../utilities/logger.dart';
import '../../utilities/route_presentation.dart';
import '../../wallets/wallet/wallet_mixin_interfaces/slatepack_interface.dart';
import '../../widgets/custom_loading_overlay.dart';
import '../../widgets/stack_dialog.dart';
import 'slatepack_dialog.dart';

/// Creates a manual Epic or MWC slate directly from either send screen.
///
/// A manual slate is the first step of an interactive transaction, not a
/// transaction ready to approve and broadcast. It therefore bypasses the
/// normal fee estimate, confirmation and PIN flow and shows the wallet's
/// actual amount and fee after creation.
abstract final class SlatepackSendFlow {
  static Future<bool> run({
    required BuildContext context,
    required SlatepackInterface wallet,
    required Amount amount,
    required String message,
    required String localNote,
    required MainDB db,
    required String Function(Amount) format,
  }) async {
    final terms = wallet.slatepackTerms;
    final root = Navigator.of(context, rootNavigator: true);
    final overlayColor = Theme.of(context)
        .extension<StackColors>()!
        .overlay
        .withValues(alpha: 0.6);
    final overlay = CurrentAwareDialogRoute<void>(
      context: context,
      barrierDismissible: false,
      themes: InheritedTheme.capture(from: context, to: root.context),
      builder: (_) => PopScope(
        canPop: false,
        child: Container(
          color: overlayColor,
          child: CustomLoadingOverlay(
            message: "Building ${terms.noun}...",
            eventBus: null,
          ),
        ),
      ),
    );

    unawaited(root.push(overlay));

    SlatepackResult? result;
    Object? error;
    var noteSaved = localNote.isEmpty;
    try {
      // Some native MWC calls block synchronously. Do not start one while the
      // keyboard or another route is still animating away.
      await waitForRoutePresentation(overlay);
      result = await wallet.createSlatepack(
        amount: amount,
        message: wallet.supportsOnChainNote && message.isNotEmpty
            ? message
            : null,
      );
      if (!result.success || (result.slatepack?.trim().isEmpty ?? true)) {
        throw Exception(
          stripExceptionPrefixes(
            result.error ?? "Failed to create ${terms.noun}",
          ),
        );
      }

      final slateId = result.slateId;
      final createdAmount = result.amount;
      final createdFee = result.fee;
      if (slateId == null ||
          slateId.isEmpty ||
          createdAmount == null ||
          createdFee == null) {
        final cancelError = slateId == null || slateId.isEmpty
            ? "it has no slate id"
            : await wallet.cancelPendingTransactionAndPost(slateId);
        final outcome = cancelError.isEmpty
            ? "The transaction was cancelled."
            : "The transaction could not be cancelled ($cancelError). "
                  "Cancel it from its details before trying again.";
        throw Exception(
          "The wallet did not return the ${terms.noun}'s complete amount, "
          "fee, and identifier. $outcome",
        );
      }

      if (createdAmount != amount) {
        final cancelError = await wallet.cancelPendingTransactionAndPost(
          slateId,
        );
        final outcome = cancelError.isEmpty
            ? "The transaction was cancelled."
            : "The transaction could not be cancelled ($cancelError). "
                  "Cancel it from its details before trying again.";
        throw Exception(
          "The ${terms.noun} was created for ${format(createdAmount)} instead "
          "of the requested ${format(amount)}. $outcome",
        );
      }

      if (!noteSaved) {
        try {
          await db.putTransactionNote(
            TransactionNote(
              walletId: wallet.walletId,
              txid: slateId,
              value: localNote,
            ),
          );
          noteSaved = true;
        } catch (e, s) {
          Logging.instance.w(
            "Could not save the local note for $slateId",
            error: e,
            stackTrace: s,
          );
        }
      }
    } catch (e, s) {
      error = e;
      Logging.instance.w(
        "Could not create the ${terms.noun}",
        error: e,
        stackTrace: s,
      );
    }

    if (root.mounted && overlay.isActive) {
      await overlay.waitUntilCurrent();
    }
    if (root.mounted && overlay.isActive) {
      if (overlay.isCurrent) {
        root.pop();
      } else {
        root.removeRoute(overlay);
      }
    }

    final resultContext = root.context;
    if (!resultContext.mounted) return false;

    if (error != null || result == null) {
      await showDialog<void>(
        context: resultContext,
        builder: (context) => StackOkDialog(
          title: "Could not create the ${terms.noun}",
          message: stripExceptionPrefixes(
            error ?? "Failed to create ${terms.noun}",
          ),
        ),
      );
      return false;
    }

    await showSlatepackDialog(
      context: resultContext,
      terms: terms,
      result: result,
      supportsEncryption: wallet.supportsSlatepackEncryption,
      formattedAmount: format(result.amount!),
      formattedFee: format(result.fee!),
    );
    if (!noteSaved && resultContext.mounted) {
      await showDialog<void>(
        context: resultContext,
        builder: (context) => const StackOkDialog(
          title: "Local note not saved",
          message:
              "The transaction was created successfully, but its local "
              "note could not be saved.",
        ),
      );
    }
    return true;
  }
}
