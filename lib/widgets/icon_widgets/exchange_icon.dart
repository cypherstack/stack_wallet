import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../services/exchange/exchange.dart';
import '../../utilities/assets.dart';
import '../../utilities/util.dart';

class ExchangeIcon extends StatelessWidget {
  const ExchangeIcon({super.key, required this.exchange});

  final Exchange exchange;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;
    final asset = Assets.exchange
        .getIconFor(exchangeName: exchange.name)
        .toLowerCase();

    if (asset.endsWith(".svg")) {
      return SvgPicture.asset(
        asset,
        width: isDesktop ? 32 : 24,
        height: isDesktop ? 32 : 24,
      );
    } else {
      return Image.asset(
        asset,
        width: isDesktop ? 32 : 24,
        height: isDesktop ? 32 : 24,
      );
    }
  }
}
