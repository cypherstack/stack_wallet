import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/providers/ui/color_theme_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/theme/color_theme.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';

class Background extends ConsumerWidget {
  const Background({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorTheme = ref.watch(colorThemeProvider.state).state;

    Color? color;

    switch (colorTheme.themeType) {
      case ThemeType.light:
      case ThemeType.dark:
        color = Theme.of(context).extension<StackColors>()!.background;
        break;
      case ThemeType.oceanBreeze:
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
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * (1 / 8),
                  bottom: MediaQuery.of(context).size.height * (1 / 12),
                ),
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
