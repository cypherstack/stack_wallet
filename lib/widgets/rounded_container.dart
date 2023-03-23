import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';

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
    this.onPressed,
  }) : super(key: key);

  final Widget? child;
  final Color color;
  final EdgeInsets padding;
  final double radiusMultiplier;
  final double? width;
  final double? height;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ConditionalParent(
      condition: onPressed != null,
      builder: (child) => RawMaterialButton(
        padding: const EdgeInsets.all(0),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius * radiusMultiplier,
          ),
        ),
        onPressed: onPressed,
        child: child,
      ),
      child: Container(
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
      ),
    );
  }
}
