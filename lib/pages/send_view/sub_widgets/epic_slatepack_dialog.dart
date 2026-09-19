import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../models/epic_slatepack_models.dart';
import '../../../notifications/show_flush_bar.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/assets.dart';
import '../../../utilities/clipboard_interface.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../../widgets/conditional_parent.dart';
import '../../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/qr.dart';
import '../../../widgets/rounded_container.dart';
import '../../../widgets/rounded_white_container.dart';

class EpicSlatepackDialog extends ConsumerStatefulWidget {
  const EpicSlatepackDialog({
    super.key,
    required this.slatepackResult,
    this.clipboard = const ClipboardWrapper(),
  });

  final EpicSlatepackResult slatepackResult;
  final ClipboardInterface clipboard;

  @override
  ConsumerState<EpicSlatepackDialog> createState() => _EpicSlatepackDialogState();
}

class _EpicSlatepackDialogState extends ConsumerState<EpicSlatepackDialog> {
  void _copySlatepack() {
    widget.clipboard.setData(
      ClipboardData(text: widget.slatepackResult.slatepack!),
    );
    showFloatingFlushBar(
      type: FlushBarType.info,
      message: "Slate copied to clipboard",
      iconAsset: Assets.svg.copy,
      context: context,
    );
  }

  void _shareSlatepack() {
    // TODO: Implement file sharing for desktop platforms.
    showFloatingFlushBar(
      type: FlushBarType.info,
      message: "Share functionality coming soon",
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConditionalParent(
      condition: Util.isDesktop,
      builder:
          (child) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with title and close button.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Text(
                      "Send Slate",
                      style: STextStyles.pageTitleH2(context),
                    ),
                  ),
                  const DesktopDialogCloseButton(),
                ],
              ),
              Padding(padding: const EdgeInsets.all(32), child: child),
            ],
          ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Instructions.
          RoundedContainer(
            color:
                Theme.of(context).extension<StackColors>()!.textFieldDefaultBG,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Next Steps:",
                  style: STextStyles.label(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  "1. Share this slate with the recipient\n"
                  "2. Wait for them to return the response slate\n"
                  "3. Import their response to finalize the transaction",
                  style: STextStyles.w400_14(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // QR Code view.
          Center(
            child: QR(
              data: widget.slatepackResult.slatepack!,
              size: 220,
            ),
          ),

          const SizedBox(height: 12),

          // Slatepack text view.
          RoundedWhiteContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text("Slate", style: STextStyles.itemSubtitle(context)),
                    const Spacer(),
                    GestureDetector(
                      onTap: _copySlatepack,
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            Assets.svg.copy,
                            width: 10,
                            height: 10,
                            color:
                                Theme.of(
                                  context,
                                ).extension<StackColors>()!.infoItemIcons,
                          ),
                          const SizedBox(width: 4),
                          Text("Copy", style: STextStyles.link2(context)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(
                    maxHeight: 200,
                    minHeight: 100,
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      widget.slatepackResult.slatepack!,
                      style: STextStyles.w400_14(
                        context,
                      ).copyWith(fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (!Util.isDesktop)
            PrimaryButton(label: "Done", onPressed: Navigator.of(context).pop),
        ],
      ),
    );
  }
}
