import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/slatepack_models.dart';
import '../../notifications/show_flush_bar.dart';
import '../../utilities/amount/amount.dart';
import '../../utilities/exception_message.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/logger.dart';
import '../../utilities/route_presentation.dart';
import '../../utilities/slatepack_text.dart';
import '../../utilities/util.dart';
import '../../wallets/wallet/wallet_mixin_interfaces/slatepack_interface.dart';
import '../../widgets/custom_loading_overlay.dart';
import '../../widgets/stack_dialog.dart';
import 'slatepack_dialog.dart';
import 'slatepack_popup.dart';
import 'slatepack_summary_dialog.dart';

/// Where an imported slatepack goes.
enum SlatepackRoute {
  /// S1: answer it with an S2.
  receive,

  /// S2: finalize our send.
  finalizeSend,

  /// I1: pay someone's invoice.
  payInvoice,

  /// I2: finalize our invoice.
  finalizeInvoice,

  /// S3 or I3: nothing left to do.
  alreadyFinalized,

  /// I1 or I2 for a wallet without invoices.
  invoicesUnsupported,

  /// State could not be worked out.
  unsupported,
}

/// Takes any slatepack the user pastes, scans or opens, works out what it
/// is and sends it to the matching screen.
abstract final class SlatepackImportFlow {
  static const _historyLookupTimeout = Duration(seconds: 3);

  static SlatepackRoute routeFor(
    SlateState state, {
    required bool supportsInvoices,
  }) => switch (state) {
    SlateState.s1 => SlatepackRoute.receive,
    SlateState.s2 => SlatepackRoute.finalizeSend,
    SlateState.i1 =>
      supportsInvoices
          ? SlatepackRoute.payInvoice
          : SlatepackRoute.invoicesUnsupported,
    SlateState.i2 =>
      supportsInvoices
          ? SlatepackRoute.finalizeInvoice
          : SlatepackRoute.invoicesUnsupported,
    SlateState.s3 || SlateState.i3 => SlatepackRoute.alreadyFinalized,
    SlateState.unknown => SlatepackRoute.unsupported,
  };

  /// The slatepack in [text] without what came along with it. A pasted or
  /// scanned message often has a greeting, a quote or blank lines around the
  /// armored slatepack, so only the part from its begin marker to its end
  /// marker is kept. Text without such a frame, like a JSON slate, is only
  /// trimmed.
  static String normalize(String text) => SlatepackText.normalize(text);

  /// Returns true once the slatepack has been acted on, so the caller can
  /// clear its input.
  static Future<bool> run({
    required BuildContext context,
    required SlatepackInterface wallet,
    required String text,
  }) async {
    final terms = wallet.slatepackTerms;
    final slatepack = normalize(text);

    final read = await _withLoading(
      context,
      "Reading ${terms.noun}...",
      () async {
        final inspection = await wallet.inspectSlatepack(slatepack);
        final route = routeFor(
          inspection.state,
          supportsInvoices: wallet.supportsInvoices,
        );
        final local = route == SlatepackRoute.finalizeSend
            ? await wallet
                  .localTxForSlate(inspection.slateId)
                  .timeout(
                    _historyLookupTimeout,
                    onTimeout: () {
                      Logging.instance.w(
                        "Timed out looking up local transaction for slate "
                        "${inspection.slateId}",
                      );
                      return null;
                    },
                  )
            : null;
        return (
          inspection: inspection,
          route: route,
          // Only the wallet that started a send can finalize it.
          local: local,
        );
      },
      errorTitle: "Could not read ${terms.noun}",
    );
    if (read == null || !context.mounted) return false;

    final inspection = read.inspection;
    final route = read.route;

    switch (route) {
      case SlatepackRoute.receive:
        return _receive(context, wallet, slatepack, inspection);

      case SlatepackRoute.finalizeSend:
        final local = read.local;
        if (local != null && !local.isSend) {
          await _message(
            context,
            "Cannot finalize this ${terms.noun}",
            "This ${terms.noun} belongs to a transaction this wallet "
                "received, not one it started. Only the wallet that "
                "started a send can finalize it.",
          );
          return false;
        }
        if (local?.isCancelled == true) {
          await _message(
            context,
            "Cannot finalize this ${terms.noun}",
            "This transaction was cancelled. A cancelled send cannot be "
                "finalized.",
          );
          return false;
        }
        return _finalize(
          context,
          wallet,
          slatepack,
          inspection,
          amount: local?.amount ?? inspection.amount,
          fee: local?.fee ?? inspection.fee,
          historyWarning: local == null,
        );

      case SlatepackRoute.payInvoice:
        // TODO(S5): PayInvoiceConfirmView.
        await _message(
          context,
          "Invoice",
          "Paying invoices is not available in this version yet.",
        );
        return false;

      case SlatepackRoute.finalizeInvoice:
        // TODO(S5): finalize with the summary from the issued invoice.
        await _message(
          context,
          "Invoice payment",
          "Finalizing invoices is not available in this version yet.",
        );
        return false;

      case SlatepackRoute.invoicesUnsupported:
        await _message(
          context,
          "Invoices not supported",
          "This ${terms.noun} is part of an invoice. "
              "${wallet.cryptoCurrency.prettyName} wallets do not support "
              "invoices.",
        );
        return false;

      case SlatepackRoute.alreadyFinalized:
        await _message(
          context,
          "Already finalized",
          "This ${terms.noun} is already finalized. There is nothing left "
              "to do with it.",
        );
        return false;

      case SlatepackRoute.unsupported:
        await _message(
          context,
          "Unsupported ${terms.noun}",
          "Could not tell which step of a transaction this ${terms.noun} "
              "belongs to.",
        );
        return false;
    }
  }

  static Future<bool> _receive(
    BuildContext context,
    SlatepackInterface wallet,
    String text,
    SlateInspection inspection,
  ) async {
    final terms = wallet.slatepackTerms;

    final confirmed = await showSlatepackPopup<bool>(
      context: context,
      child: SlatepackSummaryDialog(
        title: "Receive ${terms.noun}",
        coin: wallet.cryptoCurrency,
        actionLabel: "Receive",
        amount: inspection.amount,
        details: [
          if (inspection.senderAddress != null)
            (
              RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(inspection.senderAddress!)
                  ? "Sender key"
                  : "From",
              inspection.senderAddress!,
            ),
          ("Encrypted", inspection.isEncrypted ? "Yes" : "No"),
          if (inspection.ttlCutoffHeight != null)
            ("Expires at block", inspection.ttlCutoffHeight.toString()),
          if (inspection.slateId.isNotEmpty) ("Slate ID", inspection.slateId),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return false;

    // Looked up before the wallet is asked, so the response can still be
    // shown if the screen that started the import is gone by then.
    final root = Navigator.of(context, rootNavigator: true);

    final result = await _withLoading(
      context,
      "Processing ${terms.noun}...",
      () async {
        final r = await wallet.receiveSlatepack(text, inspection: inspection);
        if (!r.success || r.slatepack == null) {
          throw Exception(r.error ?? "Failed to receive ${terms.noun}");
        }
        return r;
      },
      errorTitle: "${terms.title} receive error",
    );
    if (result == null) return false;

    unawaited(wallet.refresh());

    // The transaction is received now and the sender cannot finalize it
    // without the response, so the response is shown wherever it still can
    // be.
    if (context.mounted) {
      await showSlatepackDialog(context: context, terms: terms, result: result);
    } else if (root.mounted) {
      Logging.instance.w(
        "Received ${terms.noun} ${result.slateId} after the screen that "
        "imported it had closed. Showing the response from the root "
        "navigator.",
      );
      await showSlatepackDialog(
        context: root.context,
        terms: terms,
        result: result,
      );
    } else {
      Logging.instance.e(
        "Received ${terms.noun} ${result.slateId} but there was nowhere left "
        "to show the response.",
      );
    }
    return true;
  }

  static Future<bool> _finalize(
    BuildContext context,
    SlatepackInterface wallet,
    String text,
    SlateInspection inspection, {
    required Amount? amount,
    required Amount? fee,
    required bool historyWarning,
  }) async {
    final terms = wallet.slatepackTerms;

    // An S2 may carry amount 0, so the summary shows [amount] and [fee] from
    // our own record of the send.
    final confirmed = await showSlatepackPopup<bool>(
      context: context,
      child: SlatepackSummaryDialog(
        title: "Finalize ${terms.noun}",
        coin: wallet.cryptoCurrency,
        actionLabel: "Finalize",
        amount: amount,
        fee: fee,
        warning: historyWarning
            ? amount == null && fee == null
                  ? "No matching send was found in this wallet's history. The "
                        "amount and fee are unavailable. Verify this "
                        "${terms.noun} with the sender before finalizing."
                  : "No matching send was found in this wallet's history. "
                        "Values shown below come from the imported "
                        "${terms.noun}; values not shown are unavailable. "
                        "Review them carefully before finalizing."
            : null,
        details: [
          if (inspection.slateId.isNotEmpty) ("Slate ID", inspection.slateId),
          ("Encrypted", inspection.isEncrypted ? "Yes" : "No"),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return false;

    final result = await _withLoading(
      context,
      "Finalizing ${terms.noun}...",
      () async {
        final r = await wallet.finalizeSlatepack(text, inspection: inspection);
        if (!r.success) {
          throw Exception(r.error ?? "Finalize failed");
        }
        return r;
      },
      errorTitle: "${terms.title} finalize error",
    );
    if (result == null) return false;

    unawaited(wallet.refresh());

    if (!context.mounted) {
      Logging.instance.w(
        "Finalized ${terms.noun} ${inspection.slateId} after the screen that "
        "imported it had closed. Broadcast: ${result.posted}.",
      );
      return true;
    }

    if (result.posted) {
      unawaited(
        showFloatingFlushBar(
          type: FlushBarType.success,
          message: "Transaction finalized and broadcast",
          context: context,
        ),
      );
    } else {
      await _message(
        context,
        "Finalized, not broadcast",
        "The transaction is finalized but the node did not accept it yet. "
            "Try again from the transaction details.",
      );
    }
    return true;
  }

  /// Runs [action] under a loading overlay. Shows the error and returns null
  /// when it throws.
  static Future<T?> _withLoading<T>(
    BuildContext context,
    String message,
    Future<T> Function() action, {
    required String errorTitle,
  }) async {
    // The overlay is this flow's own route on the root navigator, so it can
    // be taken down again even if the screen that started the import is gone
    // by the time the wallet answers.
    final root = Navigator.of(context, rootNavigator: true);
    final overlayColor = Theme.of(context)
        .extension<StackColors>()!
        .overlay
        .withValues(alpha: 0.6);
    final overlay = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      themes: InheritedTheme.capture(from: context, to: root.context),
      builder: (_) => PopScope(
        canPop: false,
        child: Container(
          color: overlayColor,
          child: CustomLoadingOverlay(message: message, eventBus: null),
        ),
      ),
    );
    unawaited(root.push(overlay));

    T? result;
    Object? error;
    try {
      // MWC's native calls can block synchronously, so wait until the route is
      // fully visible rather than merely built at zero transition opacity.
      await waitForRoutePresentation(overlay);
      result = await action();
    } catch (e, s) {
      Logging.instance.w(errorTitle, error: e, stackTrace: s);
      error = e;
    }

    if (root.mounted && overlay.isActive) {
      root.removeRoute(overlay);
    }

    if (error != null || result == null) {
      // An error is worth showing even after the importing screen closed.
      final text = error == null
          ? "Unexpected result without an error"
          : stripExceptionPrefixes(error);
      if (context.mounted) {
        await _message(context, errorTitle, text);
      } else if (root.mounted) {
        await _message(root.context, errorTitle, text);
      }
      return null;
    }
    return result;
  }

  static Future<void> _message(
    BuildContext context,
    String title,
    String message,
  ) {
    return showDialog<void>(
      context: context,
      builder: (_) => StackOkDialog(
        title: title,
        message: message,
        desktopPopRootNavigator: Util.isDesktop,
        maxWidth: Util.isDesktop ? 400 : null,
      ),
    );
  }
}
