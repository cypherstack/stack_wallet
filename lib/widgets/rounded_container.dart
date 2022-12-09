import 'package:epicpay/utilities/constants.dart';
import 'package:flutter/cupertino.dart';

class RoundedContainer extends StatelessWidget {
  const RoundedContainer({
    Key? key,
    this.child,
    required this.color,
    this.padding = const EdgeInsets.all(16),
    this.radiusMultiplier = 1.0,
    this.width,
    this.height,
    this.borderColor,
  }) : super(key: key);

  final Widget? child;
  final Color color;
  final EdgeInsets padding;
  final double radiusMultiplier;
  final double? width;
  final double? height;
  final Color? borderColor;

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
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
