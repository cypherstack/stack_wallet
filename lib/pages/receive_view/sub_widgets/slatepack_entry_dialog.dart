import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/global/barcode_scanner_provider.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/barcode_scanner_interface.dart';
import '../../../utilities/clipboard_interface.dart';
import '../../../utilities/constants.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/text_styles.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/desktop/secondary_button.dart';
import '../../../widgets/icon_widgets/clipboard_icon.dart';
import '../../../widgets/icon_widgets/qrcode_icon.dart';
import '../../../widgets/icon_widgets/x_icon.dart';
import '../../../widgets/stack_dialog.dart';
import '../../../widgets/stack_text_field.dart';
import '../../../widgets/textfield_icon_button.dart';

class SlatepackEntryDialog extends ConsumerStatefulWidget {
  const SlatepackEntryDialog({
    super.key,
    this.clipboard = const ClipboardWrapper(),
  });

  final ClipboardInterface clipboard;

  @override
  ConsumerState<SlatepackEntryDialog> createState() =>
      _SlatepackEntryDialogState();
}

class _SlatepackEntryDialogState extends ConsumerState<SlatepackEntryDialog> {
  final _receiveSlateController = TextEditingController();
  final _slateFocusNode = FocusNode();

  bool _slateToggleFlag = false;

  Future<void> _pasteSlatepack() async {
    final ClipboardData? data = await widget.clipboard.getData(
      Clipboard.kTextPlain,
    );
    if (data?.text != null && data!.text!.isNotEmpty) {
      _receiveSlateController.text = data.text!;
      setState(() {
        _slateToggleFlag = _receiveSlateController.text.isNotEmpty;
      });
    }
  }

  Future<void> _scanQr() async {
    try {
      if (_slateFocusNode.hasFocus) {
        _slateFocusNode.unfocus();
        await Future<void>.delayed(const Duration(milliseconds: 75));
      }

      if (mounted) {
        final qrResult = await ref.read(pBarcodeScanner).scan(context: context);
        if (qrResult.rawContent.isNotEmpty && qrResult.rawContent != "null") {
          _receiveSlateController.text = qrResult.rawContent;
          setState(() {
            _slateToggleFlag = _receiveSlateController.text.isNotEmpty;
          });
        }
      }
    } on PlatformException catch (e, s) {
      if (mounted) {
        try {
          await checkCamPermDeniedMobileAndOpenAppSettings(
            context,
            logging: Logging.instance,
          );
        } catch (e, s) {
          Logging.instance.e(
            "Failed to check cam permissions",
            error: e,
            stackTrace: s,
          );
        }
      } else {
        Logging.instance.e(
          "Failed to get camera permissions while trying to scan qr code in SendView: ",
          error: e,
          stackTrace: s,
        );
      }
    }
  }

  @override
  void dispose() {
    _receiveSlateController.dispose();
    _slateFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StackDialogBase(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Receive Slatepack",
            style: STextStyles.desktopTextExtraSmall(context).copyWith(
              color:
                  Theme.of(
                    context,
                  ).extension<StackColors>()!.textFieldActiveSearchIconRight,
            ),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(
              Constants.size.circularBorderRadius,
            ),
            child: TextField(
              minLines: 1,
              maxLines: 5,
              key: const Key("receiveViewSlatepackFieldKey"),
              controller: _receiveSlateController,
              readOnly: false,
              autocorrect: false,
              enableSuggestions: false,
              toolbarOptions: const ToolbarOptions(
                copy: false,
                cut: false,
                paste: true,
                selectAll: false,
              ),
              onChanged: (newValue) {
                setState(() {
                  _slateToggleFlag = newValue.isNotEmpty;
                });
              },
              focusNode: _slateFocusNode,
              style: STextStyles.desktopTextExtraSmall(context).copyWith(
                color:
                    Theme.of(
                      context,
                    ).extension<StackColors>()!.textFieldActiveText,
                height: 1.8,
              ),
              decoration: standardInputDecoration(
                "Enter Slatepack Message",
                _slateFocusNode,
                context,
                desktopMed: true,
              ).copyWith(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12, // Adjust vertical padding for better alignment
                ),
                suffixIcon: Padding(
                  padding:
                      _receiveSlateController.text.isEmpty
                          ? const EdgeInsets.only(right: 8)
                          : const EdgeInsets.only(right: 0),
                  child: UnconstrainedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _slateToggleFlag
                            ? TextFieldIconButton(
                              key: const Key(
                                "receiveViewClearSlatepackFieldButtonKey",
                              ),
                              onTap: () {
                                _receiveSlateController.text = "";
                                setState(() {
                                  _slateToggleFlag = false;
                                });
                              },
                              child: const XIcon(),
                            )
                            : TextFieldIconButton(
                              key: const Key(
                                "receiveViewPasteSlatepackFieldButtonKey",
                              ),
                              onTap: _pasteSlatepack,
                              child:
                                  _receiveSlateController.text.isEmpty
                                      ? const ClipboardIcon()
                                      : const XIcon(),
                            ),
                        if (_receiveSlateController.text.isEmpty)
                          TextFieldIconButton(
                            semanticsLabel:
                                "Scan QR Button. Opens Camera For Scanning QR Code.",
                            key: const Key("sendViewScanQrButtonKey"),
                            onTap: _scanQr,
                            child: const QrCodeIcon(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: "Import",
            enabled: _slateToggleFlag,
            onPressed:
                !_slateToggleFlag
                    ? null
                    : () =>
                        Navigator.of(context).pop(_receiveSlateController.text),
          ),
          const SizedBox(height: 16),
          SecondaryButton(
            label: "Cancel",
            onPressed: Navigator.of(context).pop,
          ),
        ],
      ),
    );
  }
}
