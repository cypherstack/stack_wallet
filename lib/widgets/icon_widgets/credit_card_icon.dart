import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';

class CreditCardIcon extends StatelessWidget {
  const CreditCardIcon({
    super.key,
    this.width = 32,
    this.height = 32,
    this.color,
  });

  final double width;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      Assets.svg.creditCard,
      width: width,
      height: height,
      colorFilter: ColorFilter.mode(
        color ?? Theme.of(context).extension<StackColors>()!.textDark3,
        BlendMode.srcIn,
      ),
    );
  }
}
