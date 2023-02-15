import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

class CoinImage extends StatelessWidget {
  const CoinImage({
    Key? key,
    required this.coin,
    required this.isDesktop,
  }) : super(key: key);

  final Coin coin;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Image(
      image: AssetImage(
        Assets.png.imageFor(coin: coin, context: context),
      ),
      width: isDesktop ? 324 : MediaQuery.of(context).size.width / 3,
    );
  }
}
