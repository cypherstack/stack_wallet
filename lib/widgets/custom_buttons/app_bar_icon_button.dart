import 'package:epicpay/utilities/assets.dart';
import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AppBarIconButton extends StatelessWidget {
  const AppBarIconButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.color,
    // this.circularBorderRadius = 10.0,
    this.size = 36.0,
    this.shadows = const [],
  }) : super(key: key);

  final Widget icon;
  final VoidCallback? onPressed;
  final Color? color;
  // final double circularBorderRadius;
  final double size;
  final List<BoxShadow> shadows;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1000),
        color: color ?? Theme.of(context).extension<StackColors>()!.background,
        boxShadow: shadows,
      ),
      child: MaterialButton(
        splashColor: Theme.of(context).extension<StackColors>()!.highlight,
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(1000),
        ),
        onPressed: onPressed,
        child: icon,
      ),
    );
  }
}

class AppBarBackButton extends StatelessWidget {
  const AppBarBackButton({
    Key? key,
    this.onPressed,
    this.isCompact = false,
    this.size,
    this.iconSize,
    this.padding = const EdgeInsets.only(left: 14),
  }) : super(key: key);

  final VoidCallback? onPressed;
  final bool isCompact;
  final double? size;
  final double? iconSize;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Center(
        child: AppBarIconButton(
          size: size ?? 40,
          color: Theme.of(context).extension<StackColors>()!.popupBG,
          shadows: const [],
          icon: SvgPicture.asset(
            Assets.svg.arrowLeft,
            width: iconSize ?? (isCompact ? 18 : 21),
            height: iconSize ?? (isCompact ? 18 : 21),
            color:
                Theme.of(context).extension<StackColors>()!.topNavIconPrimary,
          ),
          onPressed: onPressed ?? Navigator.of(context).pop,
        ),
      ),
    );
  }
}
