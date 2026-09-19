import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../services/exchange/exchange.dart';
import '../../services/exchange/rosen/rosen_exchange.dart';
import '../../utilities/assets.dart';
import '../../utilities/util.dart';

class ExchangeIcon extends StatelessWidget {
  const ExchangeIcon({super.key, required this.exchange});

  final Exchange exchange;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;
    if (exchange.name == RosenExchange.exchangeName) {
      return Icon(Icons.swap_horiz, size: isDesktop ? 32 : 24);
    }
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
