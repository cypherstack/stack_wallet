import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/theme/color_theme.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    Key? key,
    this.width,
    this.height,
  }) : super(key: key);

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final isChan = Theme.of(context).extension<StackColors>()!.themeType ==
            ThemeType.chan ||
        Theme.of(context).extension<StackColors>()!.themeType ==
            ThemeType.darkChans;

    return Container(
      color: Colors.transparent,
      child: Center(
        child: SizedBox(
          width: width,
          height: height,
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
    );
  }
}
