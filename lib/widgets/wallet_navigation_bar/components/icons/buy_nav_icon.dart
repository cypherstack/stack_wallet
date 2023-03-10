import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/utilities/assets.dart';

class BuyNavIcon extends StatelessWidget {
  const BuyNavIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      Assets.svg.buy(context),
      width: 24,
      height: 24,
    );
  }
}
