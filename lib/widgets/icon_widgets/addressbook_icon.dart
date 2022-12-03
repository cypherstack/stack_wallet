import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AddressBookIcon extends StatelessWidget {
  const AddressBookIcon({
    Key? key,
    this.width = 16,
    this.height = 16,
    this.color,
  }) : super(key: key);

  final double width;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      Assets.svg.addressBook,
      width: width,
      height: height,
      color: color ?? Theme.of(context).extension<StackColors>()!.textDark,
    );
  }
}
