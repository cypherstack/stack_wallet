import 'package:flutter/material.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';

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
                .getPrimaryEnabledButtonStyle(context)
            : Theme.of(context)
                .extension<StackColors>()!
                .getPrimaryDisabledButtonStyle(context),
        child: Text(
          "Next",
          style: STextStyles.button(context),
        ),
      ),
    );
  }
}
