import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

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
    return SvgPicture.asset(
      Assets.svg.imageFor(coin: coin, context: context),
      width: isDesktop ? 324 : MediaQuery.of(context).size.width,
    );
  }
}
