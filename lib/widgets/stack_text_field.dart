import 'package:flutter/material.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/utilities/util.dart';

InputDecoration standardInputDecoration(
  String? labelText,
  FocusNode textFieldFocusNode,
  BuildContext context, {
  bool desktopMed = false,
}) {
  final isDesktop = Util.isDesktop;

  return InputDecoration(
    labelText: labelText,
    fillColor: textFieldFocusNode.hasFocus
        ? Theme.of(context).extension<StackColors>()!.textFieldActiveBG
        : Theme.of(context).extension<StackColors>()!.textFieldDefaultBG,
    labelStyle: isDesktop
        ? desktopMed
            ? STextStyles.desktopTextExtraSmall(context).copyWith(
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .textFieldDefaultText)
            : STextStyles.desktopTextFieldLabel(context)
        : STextStyles.fieldLabel(context),
    hintStyle: isDesktop
        ? desktopMed
            ? STextStyles.desktopTextExtraSmall(context).copyWith(
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .textFieldDefaultText)
            : STextStyles.desktopTextFieldLabel(context)
        : STextStyles.fieldLabel(context),
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
  );
}
