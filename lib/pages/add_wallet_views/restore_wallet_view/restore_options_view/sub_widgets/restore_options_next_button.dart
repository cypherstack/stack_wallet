import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/text_styles.dart';

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
            ? CFColors.getPrimaryEnabledButtonColor(context)
            : CFColors.getPrimaryDisabledButtonColor(context),
        child: Text(
          "Next",
          style: STextStyles.button,
        ),
      ),
    );
  }
}
