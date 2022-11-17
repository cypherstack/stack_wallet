import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/desktop/custom_text_button.dart';

export 'package:stackwallet/widgets/desktop/custom_text_button.dart';

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    Key? key,
    this.width,
    this.height,
    this.label,
    this.icon,
    this.onPressed,
    this.enabled = true,
    this.buttonHeight,
  }) : super(key: key);

  final double? width;
  final double? height;
  final String? label;
  final VoidCallback? onPressed;
  final bool enabled;
  final Widget? icon;
  final ButtonHeight? buttonHeight;

  TextStyle getStyle(bool isDesktop, BuildContext context) {
    if (isDesktop) {
      if (buttonHeight == null) {
        return enabled
            ? STextStyles.desktopButtonSecondaryEnabled(context)
            : STextStyles.desktopButtonSecondaryDisabled(context);
      }
      switch (buttonHeight!) {
        case ButtonHeight.xxs:
        case ButtonHeight.xs:
        case ButtonHeight.s:
          return STextStyles.desktopTextExtraExtraSmall(context).copyWith(
            color: enabled
                ? Theme.of(context)
                    .extension<StackColors>()!
                    .buttonTextSecondary
                : Theme.of(context)
                    .extension<StackColors>()!
                    .buttonTextSecondaryDisabled,
          );

        case ButtonHeight.m:
        case ButtonHeight.l:
          return STextStyles.desktopTextExtraSmall(context).copyWith(
            color: enabled
                ? Theme.of(context)
                    .extension<StackColors>()!
                    .buttonTextSecondary
                : Theme.of(context)
                    .extension<StackColors>()!
                    .buttonTextSecondaryDisabled,
          );

        case ButtonHeight.xl:
        case ButtonHeight.xxl:
          return enabled
              ? STextStyles.desktopButtonSecondaryEnabled(context)
              : STextStyles.desktopButtonSecondaryDisabled(context);
      }
    } else {
      return STextStyles.button(context).copyWith(
        color: enabled
            ? Theme.of(context).extension<StackColors>()!.buttonTextSecondary
            : Theme.of(context)
                .extension<StackColors>()!
                .buttonTextSecondaryDisabled,
      );
    }
  }

  double? _getHeight() {
    if (buttonHeight == null) {
      return height;
    }

    if (Util.isDesktop) {
      switch (buttonHeight!) {
        case ButtonHeight.xxs:
          return 28;
        case ButtonHeight.xs:
          return 32;
        case ButtonHeight.s:
          return 40;
        case ButtonHeight.m:
          return 48;
        case ButtonHeight.l:
          return 56;
        case ButtonHeight.xl:
          return 70;
        case ButtonHeight.xxl:
          return 96;
      }
    } else {
      switch (buttonHeight!) {
        case ButtonHeight.xxs:
        case ButtonHeight.xs:
        case ButtonHeight.s:
        case ButtonHeight.m:
          return 28;
        case ButtonHeight.l:
          return 30;
        case ButtonHeight.xl:
          return 46;
        case ButtonHeight.xxl:
          return 56;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;

    return CustomTextButtonBase(
      height: _getHeight(),
      width: width,
      textButton: TextButton(
        onPressed: enabled ? onPressed : null,
        style: enabled
            ? Theme.of(context)
                .extension<StackColors>()!
                .getSecondaryEnabledButtonColor(context)
            : Theme.of(context)
                .extension<StackColors>()!
                .getSecondaryDisabledButtonColor(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) icon!,
            if (icon != null && label != null)
              const SizedBox(
                width: 10,
              ),
            if (label != null)
              Text(
                label!,
                style: getStyle(isDesktop, context),
              ),
          ],
        ),
      ),
    );
  }
}
