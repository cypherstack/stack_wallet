import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/text_styles.dart';

InputDecoration standardInputDecoration(
    String? labelText, FocusNode textFieldFocusNode) {
  return InputDecoration(
    labelText: labelText,
    fillColor: textFieldFocusNode.hasFocus
        ? CFColors.textFieldActive
        : CFColors.textFieldInactive,
    labelStyle: STextStyles.fieldLabel,
    hintStyle: STextStyles.fieldLabel,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
  );
}
