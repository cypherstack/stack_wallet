import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';

class XPubNavIcon extends StatelessWidget {
  const XPubNavIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      Assets.svg.eye,
      height: 20,
      width: 20,
      color: Theme.of(context).extension<StackColors>()!.bottomNavIconIcon,
    );
  }
}
