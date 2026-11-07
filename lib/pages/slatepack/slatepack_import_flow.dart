import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/slatepack_models.dart';
import '../../notifications/show_flush_bar.dart';
import '../../utilities/show_loading.dart';
import '../../utilities/util.dart';
import '../../wallets/wallet/wallet_mixin_interfaces/slatepack_interface.dart';
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

  /// Returns true once the slatepack has been acted on, so the caller can
  /// clear its input.
  static Future<bool> run({
    required BuildContext context,
    required SlatepackInterface wallet,
    required String text,
  }) async {
    final terms = wallet.slatepackTerms;

    final inspection = await _withLoading(
      context,
      "Reading ${terms.noun}...",
      () => wallet.inspectSlatepack(text),
      errorTitle: "Could not read ${terms.noun}",
    );
    if (inspection == null || !context.mounted) return false;

    final route = routeFor(
      inspection.state,
      supportsInvoices: wallet.supportsInvoices,
    );

    switch (route) {
      case SlatepackRoute.receive:
        return _receive(context, wallet, text, inspection);

      case SlatepackRoute.finalizeSend:
        return _finalize(context, wallet, text, inspection);

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
            ("From", inspection.senderAddress!),
          ("Encrypted", inspection.isEncrypted ? "Yes" : "No"),
          if (inspection.ttlCutoffHeight != null)
            ("Expires at block", inspection.ttlCutoffHeight.toString()),
          if (inspection.slateId.isNotEmpty) ("Slate ID", inspection.slateId),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return false;

    final result = await _withLoading(
      context,
      "Processing ${terms.noun}...",
      () async {
        final r = await wallet.receiveSlatepack(text);
        if (!r.success || r.slatepack == null) {
          throw Exception(r.error ?? "Failed to receive ${terms.noun}");
        }
        return r;
      },
      errorTitle: "${terms.title} receive error",
    );
    if (result == null || !context.mounted) return false;

    unawaited(wallet.refresh());
    await showSlatepackDialog(context: context, terms: terms, result: result);
    return true;
  }

  static Future<bool> _finalize(
    BuildContext context,
    SlatepackInterface wallet,
    String text,
    SlateInspection inspection,
  ) async {
    final terms = wallet.slatepackTerms;

    // An S2 may carry amount 0, so the summary comes from our own record of
    // the send when there is one.
    final local = await wallet.localTxForSlate(inspection.slateId);
    if (!context.mounted) return false;

    final confirmed = await showSlatepackPopup<bool>(
      context: context,
      child: SlatepackSummaryDialog(
        title: "Finalize ${terms.noun}",
        coin: wallet.cryptoCurrency,
        actionLabel: "Finalize",
        amount: local?.amount ?? inspection.amount,
        fee: local?.fee ?? inspection.fee,
        details: [
          if (inspection.slateId.isNotEmpty) ("Slate ID", inspection.slateId),
          ("Encrypted", inspection.isEncrypted ? "Yes" : "No"),
        ],
        note: local == null
            ? "No matching send was found in this wallet's history. "
                  "Finalizing only works for a send this wallet started."
            : null,
      ),
    );
    if (confirmed != true || !context.mounted) return false;

    final result = await _withLoading(
      context,
      "Finalizing ${terms.noun}...",
      () async {
        final r = await wallet.finalizeSlatepack(text);
        if (!r.success) {
          throw Exception(r.error ?? "Finalize failed");
        }
        return r;
      },
      errorTitle: "${terms.title} finalize error",
    );
    if (result == null || !context.mounted) return false;

    unawaited(wallet.refresh());

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
    Exception? ex;
    final result = await showLoading<T>(
      // Let the overlay open before the work starts, so an early error
      // does not pop the wrong route.
      whileFuture: Future<void>.delayed(const Duration(milliseconds: 300))
          .then((_) => action()),
      context: context,
      message: message,
      rootNavigator: true,
      onException: (e) => ex = e,
    );

    if (ex != null || result == null) {
      if (context.mounted) {
        await _message(
          context,
          errorTitle,
          ex?.toString().replaceFirst("Exception: ", "") ??
              "Unexpected result without an error",
        );
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
