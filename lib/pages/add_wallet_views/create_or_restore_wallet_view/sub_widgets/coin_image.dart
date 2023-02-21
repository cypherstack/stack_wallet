import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/providers/ui/color_theme_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/theme/color_theme.dart';

class CoinImage extends ConsumerWidget {
  const CoinImage({
    Key? key,
    required this.coin,
    required this.isDesktop,
  }) : super(key: key);

  final Coin coin;
  final bool isDesktop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isSorbet = ref.read(colorThemeProvider.state).state.themeType ==
        ThemeType.fruitSorbet;
    final bool isForest =
        ref.read(colorThemeProvider.state).state.themeType == ThemeType.forest;

    return ((isSorbet || isForest) &&
            coin != Coin.epicCash &&
            coin != Coin.monero &&
            coin != Coin.namecoin)
        ? ((isForest && coin != Coin.litecoin && coin != Coin.dogecoin)
            ? SvgPicture.asset(
                Assets.svg.imageFor(coin: coin, context: context),
                width: isDesktop ? 324 : MediaQuery.of(context).size.width,
              )
            : Image(
                image: AssetImage(
                Assets.png.imageFor(coin: coin, context: context),
              )))
        : Image(
            image: AssetImage(
              Assets.png.imageFor(coin: coin, context: context),
            ),
            width: isDesktop ? 324 : MediaQuery.of(context).size.width / 3,
          );
  }
}
