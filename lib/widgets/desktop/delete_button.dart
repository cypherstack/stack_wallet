import 'package:epicpay/utilities/assets.dart';
import 'package:epicpay/utilities/text_styles.dart';
import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:epicpay/utilities/util.dart';
import 'package:epicpay/widgets/desktop/custom_text_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class DeleteButton extends StatelessWidget {
  const DeleteButton({
    Key? key,
    this.width,
    this.height,
    this.label,
    this.onPressed,
    this.enabled = true,
    this.desktopMed = false,
  }) : super(key: key);

  final double? width;
  final double? height;
  final String? label;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool desktopMed;

  TextStyle getStyle(bool isDesktop, BuildContext context) {
    if (isDesktop) {
      if (desktopMed) {
        return STextStyles.desktopTextExtraSmall(context).copyWith(
          color: enabled
              ? Theme.of(context).extension<StackColors>()!.accentColorRed
              : Theme.of(context)
                  .extension<StackColors>()!
                  .buttonTextSecondaryDisabled,
        );
      } else {
        return enabled
            ? STextStyles.desktopButtonSecondaryEnabled(context).copyWith(
                color:
                    Theme.of(context).extension<StackColors>()!.accentColorRed)
            : STextStyles.desktopButtonSecondaryDisabled(context);
      }
    } else {
      return STextStyles.buttonText(context).copyWith(
        color: enabled
            ? Theme.of(context).extension<StackColors>()!.accentColorRed
            : Theme.of(context)
                .extension<StackColors>()!
                .buttonTextSecondaryDisabled,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;

    return CustomTextButtonBase(
      height: desktopMed ? 56 : height,
      width: width,
      textButton: TextButton(
        onPressed: enabled ? onPressed : null,
        style: enabled
            ? Theme.of(context)
                .extension<StackColors>()!
                .getDeleteEnabledButtonColor(context)
            : Theme.of(context)
                .extension<StackColors>()!
                .getDeleteDisabledButtonColor(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              Assets.svg.trash,
              width: 20,
              height: 20,
              color: enabled
                  ? Theme.of(context).extension<StackColors>()!.accentColorRed
                  : Theme.of(context)
                      .extension<StackColors>()!
                      .buttonTextSecondaryDisabled,
            ),
            if (label != null)
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
