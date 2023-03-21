import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackduo/utilities/assets.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';
import 'package:stackduo/widgets/custom_buttons/app_bar_icon_button.dart';

class DesktopDialogCloseButton extends StatelessWidget {
  const DesktopDialogCloseButton({
    Key? key,
    this.onPressedOverride,
  }) : super(key: key);

  final VoidCallback? onPressedOverride;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppBarIconButton(
            color:
                Theme.of(context).extension<StackColors>()!.textFieldDefaultBG,
            size: 40,
            icon: SvgPicture.asset(
              Assets.svg.x,
              color: Theme.of(context).extension<StackColors>()!.textDark,
              width: 22,
              height: 22,
            ),
            onPressed: () {
              if (onPressedOverride == null) {
                Navigator.of(context).pop();
              } else {
                onPressedOverride!.call();
              }
            },
          ),
        ],
      ),
    );
  }
}
