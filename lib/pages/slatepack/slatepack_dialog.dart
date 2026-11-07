import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/slatepack_models.dart';
import '../../notifications/show_flush_bar.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/clipboard_interface.dart';
import '../../utilities/logger.dart';
import '../../utilities/slatepack_terms.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/rounded_container.dart';
import '../../widgets/rounded_white_container.dart';
import 'slatepack_popup.dart';
import 'slatepack_qr.dart';

/// Shows a slatepack the user has to pass to the other party.
Future<void> showSlatepackDialog({
  required BuildContext context,
  required SlatepackTerms terms,
  required SlatepackResult result,
}) {
  return showSlatepackPopup<void>(
    context: context,
    barrierDismissible: false,
    child: SlatepackDialog.fromResult(terms: terms, result: result),
  );
}

/// One dialog for every slatepack the wallet hands out (S1, S2, I1, I2):
/// copy, share, save to file, and a QR code when the text is short enough.
class SlatepackDialog extends StatelessWidget {
  const SlatepackDialog({
    super.key,
    required this.terms,
    required this.slatepack,
    required this.state,
    this.slateId,
    this.isEncrypted = false,
    this.clipboard = const ClipboardWrapper(),
  });

  factory SlatepackDialog.fromResult({
    Key? key,
    required SlatepackTerms terms,
    required SlatepackResult result,
    ClipboardInterface clipboard = const ClipboardWrapper(),
  }) => SlatepackDialog(
    key: key,
    terms: terms,
    slatepack: result.slatepack!,
    state: result.state,
    slateId: result.slateId,
    isEncrypted: result.wasEncrypted ?? false,
    clipboard: clipboard,
  );

  final SlatepackTerms terms;
  final String slatepack;
  final SlateState state;
  final String? slateId;
  final bool isEncrypted;
  final ClipboardInterface clipboard;

  String get title => switch (state) {
    SlateState.s1 => "Send ${terms.title}",
    SlateState.s2 => "Response ${terms.title}",
    SlateState.i1 => "Invoice ${terms.title}",
    SlateState.i2 => "Payment ${terms.title}",
    _ => terms.title,
  };

  String get instructions => switch (state) {
    SlateState.s1 =>
      "1. Share this ${terms.noun} with the recipient\n"
          "2. Wait for them to return the response ${terms.noun}\n"
          "3. Import their response on the Slatepack screen to finalize the "
          "transaction\n\n"
          "The funds stay locked until the transaction is finalized or "
          "cancelled.",
    SlateState.s2 =>
      "Return this ${terms.noun} to the sender. They finalize and broadcast "
          "the transaction.",
    SlateState.i1 =>
      "1. Share this invoice with the payer\n"
          "2. Wait for them to return the payment ${terms.noun}\n"
          "3. Import it on the Slatepack screen to finalize the payment",
    SlateState.i2 =>
      "Return this ${terms.noun} to the payee. They finalize and broadcast "
          "the payment. The funds stay locked until then.",
    _ => "Pass this ${terms.noun} to the other party.",
  };

  /// `<slateId>.<state>.slatepack`, e.g. `0436...a1.S1.slatepack`.
  String get fileName {
    final id = (slateId == null || slateId!.isEmpty) ? "slatepack" : slateId!;
    final suffix = state == SlateState.unknown ? "" : ".${state.code}";
    return "$id$suffix.slatepack";
  }

  Future<void> _copy(BuildContext context) async {
    await clipboard.setData(ClipboardData(text: slatepack));
    if (context.mounted) {
      await showFloatingFlushBar(
        type: FlushBarType.info,
        message: "${terms.title} copied to clipboard",
        iconAsset: Assets.svg.copy,
        context: context,
      );
    }
  }

  Future<void> _share() async {
    try {
      await SharePlus.instance.share(
        ShareParams(text: slatepack, subject: title),
      );
    } catch (e, s) {
      Logging.instance.e(
        "Sharing ${terms.noun} failed",
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> _save(BuildContext context) async {
    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: "Save ${terms.noun}",
        fileName: fileName,
        bytes: Uint8List.fromList(utf8.encode(slatepack)),
        lockParentWindow: true,
      );
      if (path != null && context.mounted) {
        await showFloatingFlushBar(
          type: FlushBarType.success,
          message: "Saved to $path",
          context: context,
        );
      }
    } catch (e, s) {
      Logging.instance.e(
        "Saving ${terms.noun} failed",
        error: e,
        stackTrace: s,
      );
      if (context.mounted) {
        await showFloatingFlushBar(
          type: FlushBarType.warning,
          message: "Could not save the ${terms.noun}: $e",
          context: context,
        );
      }
    }
  }

  Widget _icon(BuildContext context, String asset) => SvgPicture.asset(
    asset,
    width: 14,
    height: 14,
    colorFilter: ColorFilter.mode(
      Theme.of(context).extension<StackColors>()!.buttonTextSecondary,
      BlendMode.srcIn,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<StackColors>()!;
    final isDesktop = Util.isDesktop;

    return SlatepackPopupLayout(
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RoundedContainer(
            color: colors.textFieldDefaultBG,
            child: Text(instructions, style: STextStyles.w400_14(context)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SvgPicture.asset(
                isEncrypted ? Assets.svg.lock : Assets.svg.lockOpen,
                width: 14,
                height: 14,
                colorFilter: ColorFilter.mode(
                  colors.infoItemIcons,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  isEncrypted
                      ? "Encrypted to the other party's address"
                      : "Not encrypted",
                  style: STextStyles.label(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: SlatepackQr(data: slatepack, noun: terms.noun),
          ),
          const SizedBox(height: 12),
          RoundedWhiteContainer(
            borderColor: isDesktop ? colors.backgroundAppBar : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(terms.title, style: STextStyles.itemSubtitle(context)),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      slatepack,
                      style: STextStyles.w400_14(context)
                          .copyWith(fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: "Copy",
                  buttonHeight: isDesktop ? ButtonHeight.l : null,
                  icon: _icon(context, Assets.svg.copy),
                  onPressed: () => _copy(context),
                ),
              ),
              if (!isDesktop) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: SecondaryButton(
                    label: "Share",
                    icon: _icon(context, Assets.svg.share),
                    onPressed: _share,
                  ),
                ),
              ],
              const SizedBox(width: 12),
              Expanded(
                child: SecondaryButton(
                  label: "Save",
                  buttonHeight: isDesktop ? ButtonHeight.l : null,
                  icon: _icon(context, Assets.svg.downloadFolder),
                  onPressed: () => _save(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: "Done",
            buttonHeight: isDesktop ? ButtonHeight.l : null,
            onPressed: Navigator.of(context).pop,
          ),
        ],
      ),
    );
  }
}
