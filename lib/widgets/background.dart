import 'package:epicpay/providers/ui/color_theme_provider.dart';
import 'package:epicpay/utilities/assets.dart';
import 'package:epicpay/utilities/theme/color_theme.dart';
import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:epicpay/widgets/conditional_parent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

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
