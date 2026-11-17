import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../notifications/show_flush_bar.dart';
import '../../providers/global/barcode_scanner_provider.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/barcode_scanner_interface.dart';
import '../../utilities/clipboard_interface.dart';
import '../../utilities/constants.dart';
import '../../utilities/logger.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/desktop/qr_code_scanner_dialog.dart';
import '../../widgets/icon_widgets/clipboard_icon.dart';
import '../../widgets/icon_widgets/qrcode_icon.dart';
import '../../widgets/icon_widgets/x_icon.dart';
import '../../widgets/stack_text_field.dart';
import '../../widgets/textfield_icon_button.dart';

/// Largest file accepted as a slatepack. Real ones are a few KB.
const kSlatepackFileMaxBytes = 256 * 1024;

/// Text field for a slatepack with paste, scan and open-file buttons.
class SlatepackInputField extends ConsumerStatefulWidget {
  const SlatepackInputField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.focusNode,
    this.clipboard = const ClipboardWrapper(),
  });

  final TextEditingController controller;
  final String hint;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;
  final ClipboardInterface clipboard;

  @override
  ConsumerState<SlatepackInputField> createState() =>
      _SlatepackInputFieldState();
}

class _SlatepackInputFieldState extends ConsumerState<SlatepackInputField> {
  late final FocusNode _focusNode;

  bool get _isEmpty => widget.controller.text.isEmpty;

  void _set(String text) {
    if (!mounted) return;
    widget.controller.text = text;
    widget.onChanged?.call(text);
    setState(() {});
  }

  Future<void> _paste() async {
    final ClipboardData? data = await widget.clipboard.getData(
      Clipboard.kTextPlain,
    );
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      _set(text);
    }
  }

  Future<void> _scan() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        if (_focusNode.hasFocus) {
          _focusNode.unfocus();
          await Future<void>.delayed(const Duration(milliseconds: 75));
        }
        if (!mounted) return;
        final result = await ref.read(pBarcodeScanner).scan(context: context);
        final text = result.rawContent?.trim();
        if (text != null && text.isNotEmpty) {
          _set(text);
        }
      } else {
        final text = await showDialog<String>(
          context: context,
          builder: (context) => const QrCodeScannerDialog(),
        );
        if (text != null && text.trim().isNotEmpty) {
          _set(text.trim());
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
        Logging.instance.w(
          "Camera permission error while scanning a slatepack",
          error: e,
          stackTrace: s,
        );
      }
    }
  }

  Future<void> _openFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: "Open slatepack file",
        lockParentWindow: true,
      );
      final picked = result?.files.singleOrNull;
      if (picked == null) return;

      if (picked.size > kSlatepackFileMaxBytes) {
        throw Exception(
          "File is too large (${picked.size} bytes). "
          "A slatepack file is at most $kSlatepackFileMaxBytes bytes.",
        );
      }

      final List<int> bytes =
          picked.bytes ?? await File(picked.path!).readAsBytes();
      if (bytes.length > kSlatepackFileMaxBytes) {
        throw Exception("File is too large to be a slatepack.");
      }

      final text = utf8.decode(bytes).trim();
      if (text.isEmpty) {
        throw Exception("The file is empty.");
      }
      _set(text);
    } on FormatException catch (_) {
      _showError("That file is not a text file.");
    } catch (e, s) {
      Logging.instance.w(
        "Opening slatepack file failed",
        error: e,
        stackTrace: s,
      );
      _showError(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    showFloatingFlushBar(
      type: FlushBarType.warning,
      message: message,
      context: context,
    );
  }

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<StackColors>()!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(Constants.size.circularBorderRadius),
      child: TextField(
        key: const Key("slatepackInputField"),
        minLines: 1,
        maxLines: 5,
        controller: widget.controller,
        focusNode: _focusNode,
        autocorrect: false,
        enableSuggestions: false,
        onChanged: (value) {
          widget.onChanged?.call(value);
          setState(() {});
        },
        style: Util.isDesktop
            ? STextStyles.desktopTextExtraSmall(context)
                  .copyWith(color: colors.textFieldActiveText, height: 1.8)
            : STextStyles.field(context),
        decoration:
            standardInputDecoration(
              widget.hint,
              _focusNode,
              context,
              desktopMed: true,
            ).copyWith(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              suffixIcon: Padding(
                padding: _isEmpty
                    ? const EdgeInsets.only(right: 8)
                    : EdgeInsets.zero,
                child: UnconstrainedBox(
                  child: Row(
                    children: _isEmpty
                        ? [
                            TextFieldIconButton(
                              key: const Key("slatepackPasteButton"),
                              semanticsLabel: "Paste",
                              onTap: _paste,
                              child: const ClipboardIcon(),
                            ),
                            TextFieldIconButton(
                              key: const Key("slatepackScanButton"),
                              semanticsLabel: "Scan QR code",
                              onTap: _scan,
                              child: const QrCodeIcon(),
                            ),
                            TextFieldIconButton(
                              key: const Key("slatepackFileButton"),
                              semanticsLabel: "Open file",
                              onTap: _openFile,
                              child: SvgPicture.asset(
                                Assets.svg.file,
                                width: 17,
                                height: 17,
                                colorFilter: ColorFilter.mode(
                                  colors.textDark3,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ]
                        : [
                            TextFieldIconButton(
                              key: const Key("slatepackClearButton"),
                              semanticsLabel: "Clear",
                              onTap: () => _set(""),
                              child: const XIcon(),
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
