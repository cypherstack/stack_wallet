import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/theme/color_theme.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/rounded_container.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = min(size.width, size.height) * 0.5;

    final isChan = Theme.of(context).extension<StackColors>()!.themeType ==
            ThemeType.chan ||
        Theme.of(context).extension<StackColors>()!.themeType ==
            ThemeType.darkChans;

    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        body: Container(
          color: Theme.of(context).extension<StackColors>()!.background,
          child: Center(
            child: ConditionalParent(
              condition:
                  Theme.of(context).extension<StackColors>()!.themeType ==
                      ThemeType.oledBlack,
              builder: (child) => RoundedContainer(
                color: const Color(0xFFDEDEDE),
                radiusMultiplier: 100,
                width: width * 1.35,
                height: width * 1.35,
                child: child,
              ),
              child: SizedBox(
                width: width,
                child: isChan
                    ? Image(
                        image: AssetImage(
                          Assets.gif.stacyPlain,
                        ),
                      )
                    : Lottie.asset(
                        Assets.lottie.test2,
                        animate: true,
                        repeat: true,
                      ),
              ),
            ),
            // child: Image(
            //   image: AssetImage(
            //     Assets.png.splash,
            //   ),
            //   width: MediaQuery.of(context).size.width * 0.5,
            // ),
          ),
        ),
      ),
    );
  }
}
