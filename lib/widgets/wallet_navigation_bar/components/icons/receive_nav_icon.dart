import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackduo/utilities/assets.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';

class ReceiveNavIcon extends StatelessWidget {
  const ReceiveNavIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context)
            .extension<StackColors>()!
            .accentColorDark
            .withOpacity(0.4),
        borderRadius: BorderRadius.circular(
          24,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: SvgPicture.asset(
          Assets.svg.arrowDownLeft,
          width: 12,
          height: 12,
          color: Theme.of(context).extension<StackColors>()!.accentColorDark,
        ),
      ),
    );
  }
}
