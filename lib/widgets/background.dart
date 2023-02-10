import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/theme/color_theme.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';

class Background extends StatelessWidget {
  const Background({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    Color? color;

    bool shouldPad = false;

    switch (Theme.of(context).extension<StackColors>()!.themeType) {
      case ThemeType.light:
      case ThemeType.dark:
      case ThemeType.oledBlack:
      case ThemeType.forest:
        color = Theme.of(context).extension<StackColors>()!.background;
        break;
      case ThemeType.oceanBreeze:
        shouldPad = true;
        color = null;
        break;
      case ThemeType.fruitSorbet:
        color = null;
        break;
    }

    final bgAsset = Assets.svg.background(context);

    return Container(
      decoration: BoxDecoration(
        color: color,
        gradient:
            Theme.of(context).extension<StackColors>()!.gradientBackground,
      ),
      child: ConditionalParent(
        condition: bgAsset != null,
        builder: (child) => Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: shouldPad
                    ? EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * (1 / 8),
                        bottom: MediaQuery.of(context).size.height * (1 / 12),
                      )
                    : const EdgeInsets.all(0),
                child: SvgPicture.asset(
                  bgAsset!,
                  fit: BoxFit.fill,
                ),
              ),
            ),
            Positioned.fill(
              child: child,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
