import 'package:flutter/material.dart';
import 'package:stackduo/pages_desktop_specific/desktop_home_view.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';

class ExitToMyStackButton extends StatelessWidget {
  const ExitToMyStackButton({
    Key? key,
    this.onPressed,
  }) : super(key: key);

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        right: 24,
      ),
      child: SizedBox(
        height: 56,
        child: TextButton(
          style: Theme.of(context)
              .extension<StackColors>()!
              .getSmallSecondaryEnabledButtonStyle(context),
          onPressed: onPressed ??
              () {
                Navigator.of(context).popUntil(
                  ModalRoute.withName(DesktopHomeView.routeName),
                );
              },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 30,
            ),
            child: Text(
              "Exit to My Stack",
              style: STextStyles.desktopButtonSmallSecondaryEnabled(context),
            ),
          ),
        ),
      ),
    );
  }
}
