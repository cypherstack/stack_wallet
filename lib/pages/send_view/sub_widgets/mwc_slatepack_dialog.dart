import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../models/mwc_slatepack_models.dart';
import '../../../notifications/show_flush_bar.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/assets.dart';
import '../../../utilities/clipboard_interface.dart';
import '../../../utilities/text_styles.dart';
import '../../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../../widgets/rounded_white_container.dart';

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with title and close button.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Text(
                "Send Slatepack",
                style: STextStyles.pageTitleH2(context),
              ),
            ),
            const DesktopDialogCloseButton(),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Instructions.
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
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

              // Encryption status.
              // we don't encrypt so ignore for now
              // if (widget.slatepackResult.wasEncrypted == true)
              //   Container(
              //     padding: const EdgeInsets.symmetric(
              //       horizontal: 12,
              //       vertical: 8,
              //     ),
              //     decoration: BoxDecoration(
              //       color: Theme.of(
              //         context,
              //       ).extension<StackColors>()!.infoItemIcons.withOpacity(0.1),
              //       borderRadius: BorderRadius.circular(8),
              //     ),
              //     child: Row(
              //       mainAxisSize: MainAxisSize.min,
              //       children: [
              //         Icon(
              //           Icons.lock,
              //           size: 16,
              //           color:
              //               Theme.of(
              //                 context,
              //               ).extension<StackColors>()!.infoItemIcons,
              //         ),
              //         const SizedBox(width: 8),
              //         Text(
              //           "Encrypted for recipient",
              //           style: STextStyles.label(context).copyWith(
              //             color:
              //                 Theme.of(
              //                   context,
              //                 ).extension<StackColors>()!.infoItemIcons,
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              const SizedBox(height: 24),

              // QR Code view.
              RoundedWhiteContainer(
                child: Column(
                  children: [
                    Text(
                      "Slatepack QR Code",
                      style: STextStyles.itemSubtitle(context),
                    ),
                    const SizedBox(height: 8),
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

              const SizedBox(height: 12),

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
            ],
          ),
        ),
      ],
    );
  }
}
