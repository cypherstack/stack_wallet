import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:flutter/material.dart';

class RestoreOptionsNextButton extends StatelessWidget {
  const RestoreOptionsNextButton({
    Key? key,
    required this.isDesktop,
    this.onPressed,
  }) : super(key: key);

  final bool isDesktop;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: isDesktop ? 70 : 0,
      ),
      child: TextButton(
        onPressed: onPressed,
        style: onPressed != null
            ? Theme.of(context)
                .extension<StackColors>()!
                .getPrimaryEnabledButtonColor(context)
            : Theme.of(context)
                .extension<StackColors>()!
                .getPrimaryDisabledButtonColor(context),
        child: Text(
          "Next",
          style: STextStyles.buttonText(context),
        ),
      ),
    );
  }
}
