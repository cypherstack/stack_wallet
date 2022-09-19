import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';

InputDecoration standardInputDecoration(
    String? labelText, FocusNode textFieldFocusNode) {
  final isDesktop = Util.isDesktop;

  return InputDecoration(
    labelText: labelText,
    fillColor: textFieldFocusNode.hasFocus
        ? CFColors.textFieldActive
        : CFColors.textFieldInactive,
    labelStyle:
        isDesktop ? STextStyles.desktopTextFieldLabel : STextStyles.fieldLabel,
    hintStyle:
        isDesktop ? STextStyles.desktopTextFieldLabel : STextStyles.fieldLabel,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
  );
}
