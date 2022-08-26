import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';

class ClipboardIcon extends StatelessWidget {
  const ClipboardIcon({
    Key? key,
    this.width = 18,
    this.height = 18,
    this.color = CFColors.neutral50,
  }) : super(key: key);

  final double width;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      Assets.svg.clipboard,
      width: width,
      height: height,
      color: color,
    );
  }
}
