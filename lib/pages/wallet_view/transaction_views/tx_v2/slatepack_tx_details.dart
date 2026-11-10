import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../../models/slatepack_models.dart';
import '../../../../notifications/show_flush_bar.dart';
import '../../../../themes/stack_colors.dart';
import '../../../../utilities/assets.dart';
import '../../../../utilities/logger.dart';
import '../../../../utilities/text_styles.dart';
import '../../../../utilities/util.dart';
import '../../../../wallets/wallet/wallet_mixin_interfaces/slatepack_interface.dart';
import '../../../../widgets/desktop/primary_button.dart';
import '../../../../widgets/desktop/secondary_button.dart';
import '../../../../widgets/rounded_white_container.dart';
import '../../../slatepack/slatepack_dialog.dart';
import '../../../slatepack/slatepack_import_flow.dart';
import '../../../slatepack/slatepack_popup.dart';

/// Slatepack rows and actions on the transaction details screen: kernel
/// excess, counterparty, expiry, and show again, repost and proof export.
class SlatepackTxDetails extends StatelessWidget {
  const SlatepackTxDetails({
    super.key,
    required this.wallet,
    required this.transaction,
    required this.info,
  });

  final SlatepackInterface wallet;
  final TransactionV2 transaction;
  final SlatepackTxInfo info;

  Future<void> _showAgain(BuildContext context) async {
    final slatepack = await SlatepackImportFlow.withLoading(
      context,
      "Loading ${wallet.slatepackTerms.noun}...",
      () async {
        final text = await wallet.pendingSlatepackFor(transaction.txid);
        if (text == null) {
          throw Exception(
            "This wallet no longer has the ${wallet.slatepackTerms.noun}.",
          );
        }
        return text;
      },
      errorTitle: "Not available",
    );
    if (slatepack == null || !context.mounted) return;
    await showSlatepackDialog(
      context: context,
      terms: wallet.slatepackTerms,
      result: SlatepackResult(
        success: true,
        slatepack: slatepack,
        state: info.state,
        slateId: info.slateId,
      ),
    );
  }

  Future<void> _repost(BuildContext context) async {
    await SlatepackImportFlow.offerRepost(
      context,
      wallet,
      transaction.txid,
      title: "Repost transaction",
      message:
          "Post the finalized transaction to the node again. Do this when "
          "it does not confirm.",
    );
  }

  Future<void> _exportProof(BuildContext context) async {
    final proof = await SlatepackImportFlow.withLoading(
      context,
      "Loading payment proof...",
      () => wallet.exportPaymentProof(transaction.txid),
      errorTitle: "Payment proof",
    );
    if (proof == null || !context.mounted) return;
    await showSlatepackPopup<void>(
      context: context,
      child: PaymentProofExportDialog(
        proof: proof,
        fileName: "${info.slateId ?? transaction.txid}.proof.json",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;
    final colors = Theme.of(context).extension<StackColors>()!;
    final labelStyle = isDesktop
        ? STextStyles.desktopTextExtraExtraSmall(context)
        : STextStyles.itemSubtitle(context);
    final detailStyle = isDesktop
        ? STextStyles.desktopTextExtraExtraSmall(context)
              .copyWith(color: colors.textDark)
        : STextStyles.itemSubtitle12(context);

    Widget row(String label, String value, {bool copy = false}) {
      return Padding(
        padding: EdgeInsets.only(top: isDesktop ? 16 : 12),
        child: RoundedWhiteContainer(
          padding: isDesktop
              ? const EdgeInsets.all(16)
              : const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: labelStyle),
                    const SizedBox(height: 4),
                    SelectableText(value, style: detailStyle),
                  ],
                ),
              ),
              if (copy)
                IconButton(
                  tooltip: "Copy",
                  icon: Icon(Icons.copy, size: 16, color: colors.infoItemIcons),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: value));
                    if (context.mounted) {
                      await showFloatingFlushBar(
                        type: FlushBarType.info,
                        message: "Copied to clipboard",
                        iconAsset: Assets.svg.copy,
                        context: context,
                      );
                    }
                  },
                ),
            ],
          ),
        ),
      );
    }

    final actions = <Widget>[
      if (info.canShowSlatepack)
        SecondaryButton(
          label: "Show ${wallet.slatepackTerms.title} again",
          buttonHeight: isDesktop ? ButtonHeight.m : null,
          onPressed: () => _showAgain(context),
        ),
      if (info.canRepost && wallet.supportsRepost)
        SecondaryButton(
          label: "Repost",
          buttonHeight: isDesktop ? ButtonHeight.m : null,
          onPressed: () => _repost(context),
        ),
      if (info.hasPaymentProof && wallet.supportsPaymentProofs)
        SecondaryButton(
          label: "Export payment proof",
          buttonHeight: isDesktop ? ButtonHeight.m : null,
          onPressed: () => _exportProof(context),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (info.finalizedAwaitingConfirmation)
          row("Status", "Finalized, awaiting confirmation"),
        if (info.kernelExcess != null)
          row("Kernel excess", info.kernelExcess!, copy: true),
        if (info.counterpartyAddress != null)
          row("Counterparty", info.counterpartyAddress!, copy: true),
        // The cutoff only matters until the transaction is mined.
        if (info.ttlCutoffHeight != null && (transaction.height ?? 0) <= 0)
          row("Expires at block", info.ttlCutoffHeight.toString()),
        for (final action in actions) ...[
          SizedBox(height: isDesktop ? 16 : 12),
          action,
        ],
      ],
    );
  }
}

/// A payment proof to copy, share or save.
class PaymentProofExportDialog extends StatelessWidget {
  const PaymentProofExportDialog({
    super.key,
    required this.proof,
    required this.fileName,
  });

  final String proof;
  final String fileName;

  String get _pretty {
    try {
      return const JsonEncoder.withIndent("  ").convert(jsonDecode(proof));
    } catch (_) {
      return proof;
    }
  }

  Future<void> _save(BuildContext context) async {
    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: "Save payment proof",
        fileName: fileName,
        bytes: Uint8List.fromList(utf8.encode(_pretty)),
      );
      if (path != null && context.mounted) {
        await showFloatingFlushBar(
          type: FlushBarType.success,
          message: "Payment proof saved",
          context: context,
        );
      }
    } catch (e, s) {
      Logging.instance.e(
        "Saving payment proof failed",
        error: e,
        stackTrace: s,
      );
      if (context.mounted) {
        await showFloatingFlushBar(
          type: FlushBarType.warning,
          message: "Could not save the payment proof",
          context: context,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;
    return SlatepackPopupLayout(
      title: "Payment proof",
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Anyone with this proof can check, through a Grin node, that the "
            "recipient's address signed for this amount and that the kernel "
            "is on the chain.",
            style: STextStyles.label(context),
          ),
          const SizedBox(height: 12),
          RoundedWhiteContainer(
            child: SelectableText(
              _pretty,
              style: STextStyles.label(context)
                  .copyWith(fontFamily: "monospace"),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: "Copy",
                  buttonHeight: isDesktop ? ButtonHeight.l : null,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: _pretty));
                    if (context.mounted) {
                      await showFloatingFlushBar(
                        type: FlushBarType.info,
                        message: "Payment proof copied",
                        iconAsset: Assets.svg.copy,
                        context: context,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SecondaryButton(
                  label: "Share",
                  buttonHeight: isDesktop ? ButtonHeight.l : null,
                  onPressed: () async {
                    try {
                      await SharePlus.instance.share(
                        ShareParams(text: _pretty, subject: "Payment proof"),
                      );
                    } catch (e, s) {
                      Logging.instance.e(
                        "Sharing payment proof failed",
                        error: e,
                        stackTrace: s,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: "Save",
                  buttonHeight: isDesktop ? ButtonHeight.l : null,
                  onPressed: () => _save(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
