import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "../../../themes/stack_colors.dart";
import "../../../utilities/constants.dart";
import "../../../utilities/text_styles.dart";
import "../../../utilities/util.dart";
import "../../../widgets/stack_text_field.dart";

class ShopInBitStep4TextField extends StatelessWidget {
  const ShopInBitStep4TextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    this.errorText,
    this.minLines,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.enabled = true,
    this.suffixText,
    this.suffixIcon,
    this.labelText,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final String? errorText;
  final int? minLines;
  final int? maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final String? suffixText;
  final Widget? suffixIcon;
  final String? labelText;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = Util.isDesktop
        ? STextStyles.desktopTextExtraSmall(context).copyWith(
            color: Theme.of(
              context,
            ).extension<StackColors>()!.textFieldActiveText,
            height: 1.8,
          )
        : STextStyles.field(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(Constants.size.circularBorderRadius),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autocorrect: false,
        enableSuggestions: false,
        enabled: enabled,
        readOnly: readOnly,
        onTap: onTap,
        minLines: minLines,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        style: style,
        decoration:
            standardInputDecoration(
              hintText,
              focusNode,
              context,
              desktopMed: Util.isDesktop,
            ).copyWith(
              filled: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              errorText: errorText,
              suffixText: suffixText,
              suffixIcon: suffixIcon,
              labelText: labelText,
            ),
      ),
    );
  }
}
