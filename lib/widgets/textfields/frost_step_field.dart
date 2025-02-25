import 'dart:io';

import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../themes/stack_colors.dart';
import '../../utilities/constants.dart';
import '../../utilities/logger.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../conditional_parent.dart';
import '../desktop/qr_code_scanner_dialog.dart';
import '../icon_widgets/clipboard_icon.dart';
import '../icon_widgets/qrcode_icon.dart';
import '../icon_widgets/x_icon.dart';
import '../textfield_icon_button.dart';

class FrostStepField extends StatefulWidget {
  const FrostStepField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.label,
    this.hint,
    required this.onChanged,
    required this.showQrScanOption,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? label;
  final String? hint;
  final void Function(String) onChanged;
  final bool showQrScanOption;

  @override
  State<FrostStepField> createState() => _FrostStepFieldState();
}

class _FrostStepFieldState extends State<FrostStepField> {
  final _xKey = UniqueKey();
  final _pasteKey = UniqueKey();
  late final Key? _qrKey;

  bool _isEmpty = true;

  final _inputBorder = OutlineInputBorder(
    borderSide: const BorderSide(
      width: 0,
      color: Colors.transparent,
    ),
    borderRadius: BorderRadius.circular(
      Constants.size.circularBorderRadius,
    ),
  );

  late final void Function(String) _changed;

  @override
  void initState() {
    _qrKey = widget.showQrScanOption ? UniqueKey() : null;
    _isEmpty = widget.controller.text.isEmpty;

    _changed = (value) {
      if (context.mounted) {
        widget.onChanged.call(value);
        setState(() {
          _isEmpty = widget.controller.text.isEmpty;
        });
      }
    };

    super.initState();
  }

  Future<void> scanQr() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        if (FocusScope.of(context).hasFocus) {
          FocusScope.of(context).unfocus();
          await Future<void>.delayed(
            const Duration(milliseconds: 75),
          );
        }

        final qrResult = await BarcodeScanner.scan();

        widget.controller.text = qrResult.rawContent;

        _changed(widget.controller.text);
      } else {
        // Platform.isLinux, Platform.isWindows, or Platform.isMacOS.
        final qrResult = await showDialog<String>(
          context: context,
          builder: (context) => const QrCodeScannerDialog(),
        );

        if (qrResult == null) {
          Logging.instance.d("Qr scanning cancelled");
        } else {
          // TODO [prio=low]: Validate QR code data.
          widget.controller.text = qrResult;

          _changed(widget.controller.text);
        }
      }
    } on PlatformException catch (e, s) {
      Logging.instance.w(
        "Failed to get camera permissions while trying to scan qr code: ",
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConditionalParent(
      condition: widget.label != null,
      builder: (child) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.label!,
            style: STextStyles.w500_14(context),
          ),
          const SizedBox(
            height: 4,
          ),
          child,
        ],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        readOnly: false,
        autocorrect: false,
        enableSuggestions: false,
        style: STextStyles.field(context),
        onChanged: _changed,
        decoration: InputDecoration(
          hintText: widget.hint,
          fillColor: widget.focusNode.hasFocus
              ? Theme.of(context).extension<StackColors>()!.textFieldActiveBG
              : Theme.of(context).extension<StackColors>()!.textFieldDefaultBG,
          hintStyle: Util.isDesktop
              ? STextStyles.desktopTextFieldLabel(context)
              : STextStyles.fieldLabel(context),
          enabledBorder: _inputBorder,
          focusedBorder: _inputBorder,
          errorBorder: _inputBorder,
          disabledBorder: _inputBorder,
          focusedErrorBorder: _inputBorder,
          suffixIcon: Padding(
            padding: _isEmpty
                ? const EdgeInsets.only(right: 8)
                : const EdgeInsets.only(right: 0),
            child: UnconstrainedBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  !_isEmpty
                      ? TextFieldIconButton(
                          semanticsLabel:
                              "Clear Button. Clears The Frost Step Field Input.",
                          key: _xKey,
                          onTap: () {
                            widget.controller.text = "";

                            _changed(widget.controller.text);
                          },
                          child: const XIcon(),
                        )
                      : TextFieldIconButton(
                          semanticsLabel:
                              "Paste Button. Pastes From Clipboard To Frost Step Field Input.",
                          key: _pasteKey,
                          onTap: () async {
                            final ClipboardData? data =
                                await Clipboard.getData(Clipboard.kTextPlain);
                            if (data?.text != null && data!.text!.isNotEmpty) {
                              widget.controller.text = data.text!.trim();
                            }

                            _changed(widget.controller.text);
                          },
                          child:
                              _isEmpty ? const ClipboardIcon() : const XIcon(),
                        ),
                  if (_isEmpty && widget.showQrScanOption)
                    TextFieldIconButton(
                      semanticsLabel:
                          "Scan QR Button. Opens Camera For Scanning QR Code.",
                      key: _qrKey,
                      onTap: scanQr,
                      child: const QrCodeIcon(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
