import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../themes/stack_colors.dart';
import '../../../../utilities/assets.dart';

class ChurnNavIcon extends StatelessWidget {
  const ChurnNavIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      Assets.svg.churn,
      height: 20,
      width: 20,
      color: Theme.of(context).extension<StackColors>()!.bottomNavIconIcon,
    );
  }
}
