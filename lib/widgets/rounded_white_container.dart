import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/rounded_container.dart';

class RoundedWhiteContainer extends StatelessWidget {
  const RoundedWhiteContainer({
    Key? key,
    this.child,
    this.padding = const EdgeInsets.all(12),
    this.radiusMultiplier = 1.0,
    this.width,
    this.height,
    this.borderColor,
  }) : super(key: key);

  final Widget? child;
  final EdgeInsets padding;
  final double radiusMultiplier;
  final double? width;
  final double? height;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return RoundedContainer(
      color: Theme.of(context).extension<StackColors>()!.popupBG,
      padding: padding,
      radiusMultiplier: radiusMultiplier,
      width: width,
      height: height,
      child: child,
      borderColor: borderColor,
    );
  }
}
