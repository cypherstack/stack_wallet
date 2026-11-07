import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/slatepack_models.dart';
import '../../notifications/show_flush_bar.dart';
import '../../route_generator.dart';
import '../../utilities/show_loading.dart';
import '../../utilities/util.dart';
import '../../wallets/wallet/wallet_mixin_interfaces/slatepack_interface.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/stack_dialog.dart';
import 'pay_invoice_confirm_view.dart';
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

    final inspection = await withLoading(
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
        return _payInvoice(context, wallet, text, inspection);

      case SlatepackRoute.finalizeInvoice:
        return _finalize(context, wallet, text, inspection, invoice: true);

      case SlatepackRoute.invoicesUnsupported:
        await showMessage(
          context,
          "Invoices not supported",
          "This ${terms.noun} is part of an invoice. "
              "${wallet.cryptoCurrency.prettyName} wallets do not support "
              "invoices.",
        );
        return false;

      case SlatepackRoute.alreadyFinalized:
        if (wallet.supportsRepost &&
            await wallet.canRepost(inspection.slateId)) {
          if (!context.mounted) return false;
          return offerRepost(
            context,
            wallet,
            inspection.slateId,
            title: "Already finalized",
            message:
                "This ${terms.noun} is already finalized, but the "
                "transaction is not confirmed yet. You can post it to the "
                "node again.",
          );
        }
        if (!context.mounted) return false;
        await showMessage(
          context,
          "Already finalized",
          "This ${terms.noun} is already finalized. There is nothing left "
              "to do with it.",
        );
        return false;

      case SlatepackRoute.unsupported:
        await showMessage(
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

    final result = await withLoading(
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

  /// Finalizes our send (S2) or our invoice (I2).
  static Future<bool> _finalize(
    BuildContext context,
    SlatepackInterface wallet,
    String text,
    SlateInspection inspection, {
    bool invoice = false,
  }) async {
    final terms = wallet.slatepackTerms;

    // An S2 or I2 may carry amount 0, so the summary comes from our own
    // record of the send or the issued invoice when there is one.
    final local = await wallet.localTxForSlate(inspection.slateId);
    if (!context.mounted) return false;

    final confirmed = await showSlatepackPopup<bool>(
      context: context,
      child: SlatepackSummaryDialog(
        title: invoice ? "Finalize invoice" : "Finalize ${terms.noun}",
        coin: wallet.cryptoCurrency,
        actionLabel: "Finalize",
        amount: local?.amount ?? inspection.amount,
        // The payer pays the fee of an invoice.
        fee: invoice ? null : local?.fee ?? inspection.fee,
        details: [
          if (invoice && inspection.senderAddress != null)
            ("From", inspection.senderAddress!),
          if (inspection.slateId.isNotEmpty) ("Slate ID", inspection.slateId),
          ("Encrypted", inspection.isEncrypted ? "Yes" : "No"),
        ],
        note: local != null
            ? null
            : invoice
            ? "No matching invoice was found in this wallet's history. "
                  "Finalizing only works for an invoice this wallet issued."
            : "No matching send was found in this wallet's history. "
                  "Finalizing only works for a send this wallet started.",
      ),
    );
    if (confirmed != true || !context.mounted) return false;

    final result = await withLoading(
      context,
      "Finalizing ${invoice ? "invoice" : terms.noun}...",
      () async {
        final r = invoice
            ? await wallet.finalizeInvoice(text)
            : await wallet.finalizeSlatepack(text);
        if (!r.success) {
          throw Exception(r.error ?? "Finalize failed");
        }
        return r;
      },
      errorTitle: invoice
          ? "Invoice finalize error"
          : "${terms.title} finalize error",
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
      await notPosted(context, wallet, result.slateId ?? inspection.slateId);
    }
    return true;
  }

  /// A finalized transaction the node did not take. Offers repost where
  /// the wallet can do it.
  static Future<void> notPosted(
    BuildContext context,
    SlatepackInterface wallet,
    String slateId,
  ) async {
    const message =
        "The transaction is finalized but the node did not accept it yet.";
    if (wallet.supportsRepost && slateId.isNotEmpty) {
      await offerRepost(
        context,
        wallet,
        slateId,
        title: "Finalized, not broadcast",
        message:
            "$message You can post it again now, or later from the "
            "transaction details.",
      );
    } else {
      await showMessage(
        context,
        "Finalized, not broadcast",
        "$message Try again from the transaction details.",
      );
    }
  }

  /// Asks whether to post [slateId] again and does it. Returns true when
  /// it was posted.
  static Future<bool> offerRepost(
    BuildContext context,
    SlatepackInterface wallet,
    String slateId, {
    required String title,
    required String message,
  }) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => StackDialog(
        title: title,
        message: message,
        leftButton: SecondaryButton(
          label: "Later",
          buttonHeight: Util.isDesktop ? ButtonHeight.l : null,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        rightButton: PrimaryButton(
          label: "Repost",
          buttonHeight: Util.isDesktop ? ButtonHeight.l : null,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ),
    );
    if (go != true || !context.mounted) return false;

    final done = await withLoading(context, "Posting transaction...", () async {
      await wallet.repost(slateId);
      return true;
    }, errorTitle: "Repost failed");
    if (done != true || !context.mounted) return false;
    unawaited(
      showFloatingFlushBar(
        type: FlushBarType.success,
        message: "Transaction posted to the node",
        context: context,
      ),
    );
    return true;
  }

  static Future<bool> _payInvoice(
    BuildContext context,
    SlatepackInterface wallet,
    String text,
    SlateInspection inspection,
  ) async {
    if (inspection.amount == null || inspection.amount!.raw <= BigInt.zero) {
      await showMessage(
        context,
        "Invoice",
        "This invoice does not say how much to pay.",
      );
      return false;
    }

    final view = PayInvoiceConfirmView(
      walletId: wallet.walletId,
      invoice: text,
      inspection: inspection,
    );
    final bool? paid;
    if (Util.isDesktop) {
      paid = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => DesktopDialog(
          maxWidth: 700,
          maxHeight: double.infinity,
          child: view,
        ),
      );
    } else {
      paid = await Navigator.of(context).push<bool>(
        RouteGenerator.getRoute<bool>(
          shouldUseMaterialRoute: RouteGenerator.useMaterialPageRoute,
          builder: (_) => view,
          settings: const RouteSettings(name: PayInvoiceConfirmView.routeName),
        ),
      );
    }
    return paid == true;
  }

  /// Runs [action] under a loading overlay. Shows the error and returns null
  /// when it throws.
  static Future<T?> withLoading<T>(
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
        await showMessage(
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

  static Future<void> showMessage(
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
