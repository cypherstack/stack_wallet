import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/themes/theme_providers.dart';
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
    Color? color;

    bool shouldPad = false;

    switch (Theme.of(context).extension<StackColors>()!.themeId) {
      case "ocean_breeze":
        shouldPad = true;
        color = null;
        break;
      case "fruit_sorbet":
        color = null;
        break;
      default:
        color = Theme.of(context).extension<StackColors>()!.background;
        break;
    }

    final bgAsset = ref.watch(
      themeProvider.select(
        (value) => value.assets.background,
      ),
    );

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
                child: SvgPicture.file(
                  File(
                    bgAsset!,
                  ),
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
