import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';

class DiceIcon extends StatelessWidget {
  const DiceIcon({
    Key? key,
    this.width = 17,
    this.height = 17,
    this.color = CFColors.neutral50,
  }) : super(key: key);

  final double width;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      Assets.svg.dice,
      width: width,
      height: height,
      color: color,
    );
  }
}
