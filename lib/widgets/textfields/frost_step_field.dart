import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/icon_widgets/clipboard_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/qrcode_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

class FrostStepField extends StatefulWidget {
  const FrostStepField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.label,
    this.hint,
    // this.onChanged,
    required this.showQrScanOption,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? label;
  final String? hint;
  // final void Function(String)? onChanged;
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

  @override
  void initState() {
    _qrKey = widget.showQrScanOption ? UniqueKey() : null;
    _isEmpty = widget.controller.text.isEmpty;
    super.initState();
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
        // onChanged: widget.onChanged,
        onChanged: (_) {
          setState(() {
            _isEmpty = widget.controller.text.isEmpty;
          });
        },
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

                            setState(() {
                              _isEmpty = true;
                            });
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

                            setState(() {
                              _isEmpty = widget.controller.text.isEmpty;
                            });
                          },
                          child:
                              _isEmpty ? const ClipboardIcon() : const XIcon(),
                        ),
                  if (_isEmpty && widget.showQrScanOption)
                    TextFieldIconButton(
                      semanticsLabel:
                          "Scan QR Button. Opens Camera For Scanning QR Code.",
                      key: _qrKey,
                      onTap: () async {
                        try {
                          if (FocusScope.of(context).hasFocus) {
                            FocusScope.of(context).unfocus();
                            await Future<void>.delayed(
                                const Duration(milliseconds: 75));
                          }

                          final qrResult = await BarcodeScanner.scan();

                          widget.controller.text = qrResult.rawContent;

                          setState(() {
                            _isEmpty = widget.controller.text.isEmpty;
                          });
                        } on PlatformException catch (e, s) {
                          Logging.instance.log(
                            "Failed to get camera permissions while trying to scan qr code: $e\n$s",
                            level: LogLevel.Warning,
                          );
                        }
                      },
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
