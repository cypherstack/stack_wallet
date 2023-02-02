import 'package:flutter/cupertino.dart';
import 'package:stackwallet/utilities/constants.dart';

class RoundedContainer extends StatelessWidget {
  const RoundedContainer({
    Key? key,
    this.child,
    required this.color,
    this.padding = const EdgeInsets.all(12),
    this.radiusMultiplier = 1.0,
    this.width,
    this.height,
    this.borderColor,
    this.boxShadow,
  }) : super(key: key);

  final Widget? child;
  final Color color;
  final EdgeInsets padding;
  final double radiusMultiplier;
  final double? width;
  final double? height;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(
          Constants.size.circularBorderRadius * radiusMultiplier,
        ),
        border: borderColor == null ? null : Border.all(color: borderColor!),
        boxShadow: boxShadow,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
