import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../notifications/show_flush_bar.dart';
import '../../../models/mwc_slatepack_models.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/assets.dart';
import '../../../utilities/clipboard_interface.dart';
import '../../../utilities/text_styles.dart';
import '../../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/desktop/secondary_button.dart';
import '../../../widgets/rounded_white_container.dart';
import '../../../widgets/stack_dialog.dart';

class MwcSlatepackDialog extends ConsumerStatefulWidget {
  const MwcSlatepackDialog({
    super.key,
    required this.slatepackResult,
    this.clipboard = const ClipboardWrapper(),
  });

  final SlatepackResult slatepackResult;
  final ClipboardInterface clipboard;

  @override
  ConsumerState<MwcSlatepackDialog> createState() => _MwcSlatepackDialogState();
}

class _MwcSlatepackDialogState extends ConsumerState<MwcSlatepackDialog> {
  int _currentView = 0; // 0: Slatepack text, 1: QR Code.

  void _copySlatepack() {
    widget.clipboard.setData(
      ClipboardData(text: widget.slatepackResult.slatepack!),
    );
    showFloatingFlushBar(
      type: FlushBarType.info,
      message: "Slatepack copied to clipboard",
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
    final isDesktop =
        Platform.isLinux || Platform.isMacOS || Platform.isWindows;

    return StackDialogBase(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with title and close button.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Send Slatepack", style: STextStyles.pageTitleH2(context)),
              AppBarIconButton(
                size: 36,
                color: Theme.of(context).extension<StackColors>()!.background,
                shadows: const [],
                icon: SvgPicture.asset(
                  Assets.svg.x,
                  color:
                      Theme.of(
                        context,
                      ).extension<StackColors>()!.topNavIconPrimary,
                  width: 24,
                  height: 24,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Info text.
                Text(
                  "Share this slatepack with the recipient to complete the transaction.",
                  style: STextStyles.subtitle(context),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Encryption status.
                if (widget.slatepackResult.wasEncrypted == true)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .infoItemIcons
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock,
                          size: 16,
                          color:
                              Theme.of(
                                context,
                              ).extension<StackColors>()!.infoItemIcons,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Encrypted for recipient",
                          style: STextStyles.label(context).copyWith(
                            color:
                                Theme.of(
                                  context,
                                ).extension<StackColors>()!.infoItemIcons,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // View toggle buttons.
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: "Text",
                        buttonHeight: ButtonHeight.m,
                        onPressed:
                            _currentView == 0
                                ? null
                                : () => setState(() => _currentView = 0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SecondaryButton(
                        label: "QR Code",
                        buttonHeight: ButtonHeight.m,
                        onPressed:
                            _currentView == 1
                                ? null
                                : () => setState(() => _currentView = 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Content display.
                if (_currentView == 0) ...[
                  // Slatepack text view.
                  RoundedWhiteContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Slatepack",
                              style: STextStyles.itemSubtitle(context),
                            ),
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
                                        Theme.of(context)
                                            .extension<StackColors>()!
                                            .infoItemIcons,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Copy",
                                    style: STextStyles.link2(context),
                                  ),
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
                ] else ...[
                  // QR Code view.
                  RoundedWhiteContainer(
                    child: Column(
                      children: [
                        Text(
                          "Scan QR Code",
                          style: STextStyles.itemSubtitle(context),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: QrImageView(
                            data: widget.slatepackResult.slatepack!,
                            size: 200,
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            errorCorrectionLevel: QrErrorCorrectLevel.M,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Action buttons.
                if (isDesktop) ...[
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: "Share File",
                          onPressed: _shareSlatepack,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrimaryButton(
                          label: "Copy Text",
                          onPressed: _copySlatepack,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  PrimaryButton(
                    label: "Copy Slatepack",
                    onPressed: _copySlatepack,
                  ),
                  const SizedBox(height: 12),
                  SecondaryButton(label: "Share", onPressed: _shareSlatepack),
                ],

                const SizedBox(height: 16),

                // Instructions.
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).extension<StackColors>()!.infoItemIcons.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                        "1. Share this slatepack with the recipient\n"
                        "2. Wait for them to return the response slatepack\n"
                        "3. Import their response to finalize the transaction",
                        style: STextStyles.w400_14(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
