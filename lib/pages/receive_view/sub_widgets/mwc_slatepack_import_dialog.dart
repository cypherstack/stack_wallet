import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../models/mwc_slatepack_models.dart';
import '../../../notifications/show_flush_bar.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/assets.dart';
import '../../../utilities/clipboard_interface.dart';
import '../../../utilities/constants.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../../wallets/crypto_currency/coins/mimblewimblecoin.dart';
import '../../../wallets/wallet/impl/mimblewimblecoin_wallet.dart';
import '../../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../../widgets/custom_buttons/simple_paste_button.dart';
import '../../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/desktop/secondary_button.dart';
import '../../../widgets/rounded_white_container.dart';
import '../../../widgets/stack_dialog.dart';

class MwcSlatepackImportDialog extends ConsumerStatefulWidget {
  const MwcSlatepackImportDialog({
    super.key,
    required this.wallet,
    this.clipboard = const ClipboardWrapper(),
  });

  final MimblewimblecoinWallet wallet;
  final ClipboardInterface clipboard;

  @override
  ConsumerState<MwcSlatepackImportDialog> createState() =>
      _MwcSlatepackImportDialogState();
}

class _MwcSlatepackImportDialogState
    extends ConsumerState<MwcSlatepackImportDialog> {
  late final TextEditingController slatepackController;
  late final FocusNode slatepackFocusNode;

  bool _isProcessing = false;
  String? _validationError;
  SlatepackDecodeResult? _decodedSlatepack;
  String? _slatepackType;

  @override
  void initState() {
    super.initState();
    slatepackController = TextEditingController();
    slatepackFocusNode = FocusNode();
  }

  @override
  void dispose() {
    slatepackController.dispose();
    slatepackFocusNode.dispose();
    super.dispose();
  }

  void _pasteFromClipboard(String? content) async {
    try {
      if (content != null) {
        slatepackController.text = content;
        _validateSlatepack();
      }
    } catch (e) {
      showFloatingFlushBar(
        type: FlushBarType.warning,
        message: "Failed to paste from clipboard",
        context: context,
      );
    }
  }

  void _validateSlatepack() async {
    final text = slatepackController.text.trim();

    if (text.isEmpty) {
      setState(() {
        _validationError = null;
        _decodedSlatepack = null;
        _slatepackType = null;
      });
      return;
    }

    // Basic format validation.
    final coin = widget.wallet.cryptoCurrency as Mimblewimblecoin;
    if (!coin.isSlatepack(text)) {
      setState(() {
        _validationError = "Invalid slatepack format";
        _decodedSlatepack = null;
        _slatepackType = null;
      });
      return;
    }

    try {
      // Attempt to decode.
      final decoded = await widget.wallet.decodeSlatepack(text);

      if (decoded.success) {
        final analysis = await widget.wallet.analyzeSlatepack(text);

        final String slatepackType = switch (analysis.status) {
          'S1' => "S1 (Initial Send)",
          'S2' => "S2 (Response)",
          'S3' => "S3 (Finalized)",
          _ => _determineSlatepackType(decoded), // Fallback.
        };

        setState(() {
          _validationError = null;
          _decodedSlatepack = decoded;
          _slatepackType = slatepackType;
        });
      } else {
        setState(() {
          _validationError = decoded.error ?? "Failed to decode slatepack";
          _decodedSlatepack = null;
          _slatepackType = null;
        });
      }
    } catch (e) {
      setState(() {
        _validationError = "Error decoding slatepack: $e";
        _decodedSlatepack = null;
        _slatepackType = null;
      });
    }
  }

  String _determineSlatepackType(SlatepackDecodeResult decoded) {
    // Fallback analysis based on sender/recipient addresses.
    if (decoded.senderAddress != null && decoded.recipientAddress != null) {
      return "S2 (Response)";
    } else if (decoded.senderAddress != null) {
      return "S1 (Initial)";
    } else {
      return "Unknown";
    }
  }

  void _processSlatepack() async {
    if (_decodedSlatepack == null || slatepackController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final slatepackText = slatepackController.text.trim();

      // Determine action based on slatepack type.
      if (_slatepackType?.contains("S1") == true) {
        // This is an initial slatepack - receive it and create response.
        final result = await widget.wallet.receiveSlatepack(slatepackText);

        if (result.success && result.responseSlatepack != null) {
          // Show response slatepack.
          if (mounted) {
            Navigator.of(context).pop(); // Close this dialog.

            await showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder:
                  (context) => _SlatepackResponseDialog(
                    responseSlatepack: result.responseSlatepack!,
                    wasEncrypted: result.wasEncrypted ?? false,
                    clipboard: widget.clipboard,
                  ),
            );
          }
        } else {
          throw Exception(result.error ?? 'Failed to process slatepack');
        }
      } else if (_slatepackType?.contains("S2") == true) {
        // This is a response slatepack - finalize it.
        final result = await widget.wallet.finalizeSlatepack(slatepackText);

        if (result.success) {
          if (mounted) {
            Navigator.of(context).pop(); // Close this dialog.

            showFloatingFlushBar(
              type: FlushBarType.success,
              message: "Transaction finalized and broadcast successfully!",
              context: context,
            );
          }
        } else {
          throw Exception(result.error ?? 'Failed to finalize slatepack');
        }
      } else {
        throw Exception('Unsupported slatepack type: $_slatepackType');
      }
    } catch (e) {
      if (mounted) {
        showFloatingFlushBar(
          type: FlushBarType.warning,
          message: "Failed to process slatepack: $e",
          context: context,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;
    final canProcess = _decodedSlatepack != null && !_isProcessing;

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
                "Import Slatepack",
                style: STextStyles.pageTitleH2(context),
              ),
            ),
            DesktopDialogCloseButton(
              onPressedOverride: () async {
                if (!_isProcessing) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Enter a slatepack to process the transaction.",
                    style: STextStyles.subtitle(context),
                    textAlign: TextAlign.center,
                  ),
                  SimplePasteButton(
                    onPaste: _pasteFromClipboard,
                    clipboard: widget.clipboard,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Slatepack input field.
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  Constants.size.circularBorderRadius,
                ),
                child: TextField(
                  controller: slatepackController,
                  focusNode: slatepackFocusNode,
                  maxLines: 8,
                  onChanged: (_) => _validateSlatepack(),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.all(16),
                    hintStyle: STextStyles.fieldLabel(context),
                    hintText: "BEGINSLATEPACK...",
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),

              // Validation status.
              if (_validationError != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color:
                          Theme.of(context).extension<StackColors>()!.textError,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _validationError!,
                        style: STextStyles.w400_14(context).copyWith(
                          color:
                              Theme.of(
                                context,
                              ).extension<StackColors>()!.textError,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (_decodedSlatepack != null) ...[
                const SizedBox(height: 8),
                RoundedWhiteContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 16,
                            color:
                                Theme.of(
                                  context,
                                ).extension<StackColors>()!.accentColorGreen,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Valid Slatepack",
                            style: STextStyles.label(context).copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).extension<StackColors>()!.accentColorGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Type: $_slatepackType",
                        style: STextStyles.w400_14(context),
                      ),
                      if (_decodedSlatepack!.wasEncrypted == true)
                        Text(
                          "Encrypted: Yes",
                          style: STextStyles.w400_14(context),
                        ),
                      if (_decodedSlatepack!.senderAddress != null)
                        Text(
                          "From: ${_decodedSlatepack!.senderAddress}",
                          style: STextStyles.w400_14(context),
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
                        label: "Cancel",
                        onPressed:
                            _isProcessing
                                ? null
                                : () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        label: _isProcessing ? "Processing..." : "Process",
                        onPressed: canProcess ? _processSlatepack : null,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                PrimaryButton(
                  label: _isProcessing ? "Processing..." : "Process Slatepack",
                  onPressed: canProcess ? _processSlatepack : null,
                ),
                const SizedBox(height: 12),
                SecondaryButton(
                  label: "Cancel",
                  onPressed:
                      _isProcessing ? null : () => Navigator.of(context).pop(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _SlatepackResponseDialog extends StatelessWidget {
  const _SlatepackResponseDialog({
    required this.responseSlatepack,
    required this.wasEncrypted,
    required this.clipboard,
  });

  final String responseSlatepack;
  final bool wasEncrypted;
  final ClipboardInterface clipboard;

  void _copySlatepack(BuildContext context) {
    clipboard.setData(ClipboardData(text: responseSlatepack));
    showFloatingFlushBar(
      type: FlushBarType.info,
      message: "Response slatepack copied to clipboard",
      iconAsset: Assets.svg.copy,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StackDialogBase(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with title and close button.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Response Slatepack",
                style: STextStyles.pageTitleH2(context),
              ),
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
                Text(
                  "Return this slatepack to the sender to complete the transaction.",
                  style: STextStyles.subtitle(context),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                if (wasEncrypted)
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
                          "Encrypted Response",
                          style: STextStyles.label(context),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                RoundedWhiteContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Response Slatepack",
                            style: STextStyles.itemSubtitle(context),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _copySlatepack(context),
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  Assets.svg.copy,
                                  width: 10,
                                  height: 10,
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
                            responseSlatepack,
                            style: STextStyles.w400_14(
                              context,
                            ).copyWith(fontFamily: 'monospace'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                PrimaryButton(
                  label: "Copy Response",
                  onPressed: () => _copySlatepack(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
