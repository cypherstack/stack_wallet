import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utilities/constants.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../icon_widgets/clipboard_icon.dart';
import '../icon_widgets/x_icon.dart';
import '../stack_text_field.dart';
import '../textfield_icon_button.dart';

class AdaptiveTextField extends StatefulWidget {
  const AdaptiveTextField({
    super.key,
    this.labelText,
    this.hintText,
    this.controller,
    this.focusNode,
    this.autocorrect,
    this.readOnly = false,
    this.enabled = true,
    this.enableSuggestions = true,
    this.onChanged,
    this.onChangedComprehensive,
    this.onSubmitted,
    this.onTap,
    this.suffixIcons,
    this.suffixText,
    this.errorText,
    this.contentPadding,
    this.minLines,
    this.maxLines,
    this.inputFormatters,
    this.showPasteClearButton = false,
    this.keyboardType,
  });

  final String? labelText;
  final String? hintText;

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool? autocorrect;
  final EdgeInsets? contentPadding;
  final int? minLines;
  final int? maxLines;

  final bool readOnly;
  final bool enabled;
  final bool enableSuggestions;

  final void Function(String)? onChanged;
  final void Function(String)? onChangedComprehensive;
  final void Function(String)? onSubmitted;
  final VoidCallback? onTap;

  /// This will be ignored if [suffixIcons] is not null!
  final bool showPasteClearButton;

  /// If this is not null, [showPasteClearButton] will be ignored.
  final List<Widget>? suffixIcons;

  /// Optional trailing text rendered in the decoration's suffixText slot.
  /// Ignored when [suffixIcons] is non-empty or [showPasteClearButton] is
  /// true, since those occupy the same visual space.
  final String? suffixText;

  final String? errorText;

  final List<TextInputFormatter>? inputFormatters;

  final TextInputType? keyboardType;

  @override
  State<AdaptiveTextField> createState() => _AdaptiveTextFieldState();
}

class _AdaptiveTextFieldState extends State<AdaptiveTextField> {
  late final FocusNode _focusNode;
  late final bool _focusFlag;

  TextEditingController? _controller;
  TextEditingController get controller => widget.controller ?? _controller!;

  String _cache = "";

  @override
  void initState() {
    super.initState();

    if (widget.controller == null) {
      _controller = TextEditingController();
    } else if (widget.onChangedComprehensive != null) {
      widget.controller!.addListener(() {
        if (widget.controller!.text != _cache) {
          _cache = widget.controller!.text;
          widget.onChangedComprehensive!.call(_cache);
        }
      });
    }

    if (widget.focusNode == null) {
      _focusFlag = true;
      _focusNode = FocusNode();
    } else {
      _focusFlag = false;
      _focusNode = widget.focusNode!;
    }
  }

  @override
  void dispose() {
    if (_focusFlag) _focusNode.dispose();
    _controller?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
          child: TextField(
            minLines: widget.minLines,
            maxLines: widget.maxLines,
            style: Util.isDesktop
                ? STextStyles.field(context).copyWith(fontSize: 16)
                : STextStyles.field(context),
            controller: controller,
            focusNode: _focusNode,
            onChanged: widget.onChanged,
            onTap: widget.onTap,
            readOnly: widget.readOnly,
            enabled: widget.enabled,
            autocorrect: widget.autocorrect,
            enableSuggestions: widget.enableSuggestions,
            onSubmitted: widget.onSubmitted,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            decoration:
                standardInputDecoration(
                  widget.labelText,
                  _focusNode,
                  context,
                ).copyWith(
                  hintText: widget.hintText,
                  suffixText:
                      (widget.suffixIcons?.isNotEmpty != true &&
                          !widget.showPasteClearButton)
                      ? widget.suffixText
                      : null,
                  contentPadding:
                      widget.contentPadding ??
                      (Util.isDesktop
                          ? const EdgeInsets.only(
                              left: 12,
                              top: 11,
                              bottom: 12,
                              right: 5,
                            )
                          : const EdgeInsets.only(
                              left: 10,
                              top: 12,
                              bottom: 8,
                              right: 5,
                            )),
                  suffixIcon: widget.suffixIcons?.isNotEmpty == true
                      ? Padding(
                          padding: controller.text.isEmpty
                              ? const EdgeInsets.only(right: 8)
                              : const EdgeInsets.only(right: 0),
                          child: UnconstrainedBox(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: widget.suffixIcons!,
                            ),
                          ),
                        )
                      : widget.showPasteClearButton
                      ? TextFieldIconButton(
                          onTap: () async {
                            if (controller.text.isEmpty) {
                              final ClipboardData? data =
                                  await Clipboard.getData(Clipboard.kTextPlain);
                              if (data?.text != null &&
                                  data!.text!.isNotEmpty) {
                                final content = data.text!.trim();
                                controller.text = content;
                              }
                            } else {
                              controller.text = "";
                            }

                            if (mounted) setState(() {});
                          },
                          child: controller.text.isNotEmpty
                              ? const XIcon()
                              : const ClipboardIcon(),
                        )
                      : null,
                ),
          ),
        ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              widget.errorText!,
              style: STextStyles.errorSmall(context),
            ),
          ),
      ],
    );
  }
}
