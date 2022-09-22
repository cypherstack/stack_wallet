import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';
import 'package:stackwallet/utilities/util.dart';

InputDecoration standardInputDecoration(
    String? labelText, FocusNode textFieldFocusNode, BuildContext context) {
  final isDesktop = Util.isDesktop;

  return InputDecoration(
    labelText: labelText,
    fillColor: textFieldFocusNode.hasFocus
        ? StackTheme.instance.color.textFieldActiveBG
        : StackTheme.instance.color.textFieldDefaultBG,
    labelStyle: isDesktop
        ? STextStyles.desktopTextFieldLabel(context)
        : STextStyles.fieldLabel(context),
    hintStyle: isDesktop
        ? STextStyles.desktopTextFieldLabel(context)
        : STextStyles.fieldLabel(context),
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
  );
}
