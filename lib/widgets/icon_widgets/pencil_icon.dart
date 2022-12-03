import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class PencilIcon extends StatelessWidget {
  const PencilIcon({
    Key? key,
    this.width = 18,
    this.height = 18,
    this.color,
  }) : super(key: key);

  final double width;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      Assets.svg.pencil,
      width: width,
      height: height,
      color: color ?? Theme.of(context).extension<StackColors>()!.textDark,
    );
  }
}
