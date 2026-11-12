import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/slatepack_models.dart';
import '../../notifications/show_flush_bar.dart';
import '../../route_generator.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/amount/amount.dart';
import '../../utilities/logger.dart';
import '../../utilities/util.dart';
import '../../wallets/wallet/wallet_mixin_interfaces/slatepack_interface.dart';
import '../../widgets/custom_loading_overlay.dart';
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

  static final _armored = RegExp(
    r"BEGINSLATE(PACK|_BIN)\.[\s\S]*?ENDSLATE\1\.?",
  );

  /// The slatepack in [text] without what came along with it. A pasted or
  /// scanned message often has a greeting, a quote or blank lines around the
  /// armored slatepack, so only the part from its begin marker to its end
  /// marker is kept. Text without such a frame, like a JSON slate, is only
  /// trimmed.
  static String normalize(String text) {
    final trimmed = text.trim();
    if (trimmed.startsWith("{")) return trimmed;
    return _armored.firstMatch(trimmed)?.group(0) ?? trimmed;
  }

  /// Returns true once the slatepack has been acted on, so the caller can
  /// clear its input.
  static Future<bool> run({
    required BuildContext context,
    required SlatepackInterface wallet,
    required String text,
  }) async {
    final terms = wallet.slatepackTerms;
    final slatepack = normalize(text);

    final read = await withLoading(
      context,
      "Reading ${terms.noun}...",
      () async {
        final inspection = await wallet.inspectSlatepack(slatepack);
        final route = routeFor(
          inspection.state,
          supportsInvoices: wallet.supportsInvoices,
        );
        return (
          inspection: inspection,
          route: route,
          // Only the wallet that started a send or issued an invoice can
          // finalize it.
          local:
              route == SlatepackRoute.finalizeSend ||
                  route == SlatepackRoute.finalizeInvoice
              ? await wallet.localTxForSlate(inspection.slateId)
              : null,
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
        if (local == null || !local.isSend) {
          await showMessage(
            context,
            "Cannot finalize this ${terms.noun}",
            local == null
                ? "This wallet did not start the transaction this "
                      "${terms.noun} belongs to. Only the wallet that "
                      "started a send can finalize it. If the send was made "
                      "here moments ago, let the wallet finish syncing and "
                      "try again."
                : "This ${terms.noun} belongs to a transaction this wallet "
                      "received, not one it started. Only the wallet that "
                      "started a send can finalize it.",
          );
          return false;
        }
        return _finalize(
          context,
          wallet,
          slatepack,
          inspection,
          amount: local.amount,
          fee: local.fee,
        );

      case SlatepackRoute.payInvoice:
        return _payInvoice(context, wallet, slatepack, inspection);

      case SlatepackRoute.finalizeInvoice:
        final local = read.local;
        if (local == null || local.isSend) {
          await showMessage(
            context,
            "Cannot finalize this invoice",
            local == null
                ? "This wallet did not issue the invoice this ${terms.noun} "
                      "pays. Only the wallet that issued an invoice can "
                      "finalize it. If the invoice was made here moments "
                      "ago, let the wallet finish syncing and try again."
                : "This ${terms.noun} is this wallet's own payment of an "
                      "invoice. Give it to the wallet that issued the "
                      "invoice, which is the one that finalizes it.",
          );
          return false;
        }
        return _finalize(
          context,
          wallet,
          slatepack,
          inspection,
          amount: local.amount,
          // The payer pays the fee of an invoice.
          fee: null,
          invoice: true,
        );

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

    // Looked up before the wallet is asked, so the response can still be
    // shown if the screen that started the import is gone by then.
    final root = Navigator.of(context, rootNavigator: true);

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

  /// Finalizes our send (S2) or our invoice (I2).
  static Future<bool> _finalize(
    BuildContext context,
    SlatepackInterface wallet,
    String text,
    SlateInspection inspection, {
    required Amount amount,
    required Amount? fee,
    bool invoice = false,
  }) async {
    final terms = wallet.slatepackTerms;

    // An S2 or I2 may carry amount 0, so the summary shows [amount] and
    // [fee] from our own record of the send or the issued invoice.
    final confirmed = await showSlatepackPopup<bool>(
      context: context,
      child: SlatepackSummaryDialog(
        title: invoice ? "Finalize invoice" : "Finalize ${terms.noun}",
        coin: wallet.cryptoCurrency,
        actionLabel: "Finalize",
        amount: amount,
        fee: fee,
        details: [
          if (invoice && inspection.senderAddress != null)
            ("From", inspection.senderAddress!),
          if (inspection.slateId.isNotEmpty) ("Slate ID", inspection.slateId),
          ("Encrypted", inspection.isEncrypted ? "Yes" : "No"),
        ],
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
        width: Util.isDesktop ? 500 : null,
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
        builder: (_) =>
            DesktopDialog(maxWidth: 700, maxHeight: null, child: view),
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
      // Let the overlay paint before the wallet is asked.
      await Future<void>.delayed(const Duration(milliseconds: 300));
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
      final text =
          error?.toString().replaceFirst("Exception: ", "") ??
          "Unexpected result without an error";
      if (context.mounted) {
        await showMessage(context, errorTitle, text);
      } else if (root.mounted) {
        await showMessage(root.context, errorTitle, text);
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
