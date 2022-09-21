import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

class WalletInfoCoinIcon extends StatelessWidget {
  const WalletInfoCoinIcon({Key? key, required this.coin}) : super(key: key);

  final Coin coin;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CFColors.coin.forCoin(coin).withOpacity(0.5),
        borderRadius: BorderRadius.circular(
          Constants.size.circularBorderRadius,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SvgPicture.asset(
          Assets.svg.iconFor(coin: coin),
          width: 20,
          height: 20,
        ),
      ),
    );
  }
}
