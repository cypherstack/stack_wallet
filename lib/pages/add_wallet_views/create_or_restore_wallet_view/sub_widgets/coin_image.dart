import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/theme/color_theme.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';

import '../../../../utilities/util.dart';

class CoinImage extends ConsumerWidget {
  const CoinImage({
    Key? key,
    required this.coin,
    this.width,
    this.height,
  }) : super(key: key);

  final Coin coin;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isChans = Theme.of(context).extension<StackColors>()!.themeType ==
            ThemeType.chan ||
        Theme.of(context).extension<StackColors>()!.themeType ==
            ThemeType.darkChans;

    final isDesktop = Util.isDesktop;

    if (isChans) {
      return SizedBox(
        width: isDesktop ? width : MediaQuery.of(context).size.width,
        height: isDesktop ? height : MediaQuery.of(context).size.width,
        child: Image(
          image: AssetImage(
            Assets.gif.plain(coin),
          ),
        ),
      );
    } else {
      return SvgPicture.asset(
        Assets.svg.imageFor(coin: coin, context: context),
        width: width,
        height: height,
      );
    }
  }
}
