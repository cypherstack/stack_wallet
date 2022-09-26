import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/desktop/custom_text_button.dart';

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    Key? key,
    this.width,
    this.height,
    this.label,
    this.icon,
    this.onPressed,
    this.enabled = true,
  }) : super(key: key);

  final double? width;
  final double? height;
  final String? label;
  final VoidCallback? onPressed;
  final bool enabled;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;

    return CustomTextButtonBase(
      height: height,
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
                style: isDesktop
                    ? enabled
                        ? STextStyles.desktopButtonSecondaryEnabled(context)
                        : STextStyles.desktopButtonSecondaryDisabled(context)
                    : STextStyles.button(context).copyWith(
                        color: enabled
                            ? Theme.of(context)
                                .extension<StackColors>()!
                                .buttonTextSecondary
                            : Theme.of(context)
                                .extension<StackColors>()!
                                .buttonTextSecondaryDisabled,
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
