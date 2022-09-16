import 'package:flutter/cupertino.dart';
import 'package:stackwallet/utilities/constants.dart';

class RoundedContainer extends StatelessWidget {
  const RoundedContainer({
    Key? key,
    this.child,
    required this.color,
    this.padding = const EdgeInsets.all(12),
    this.radiusMultiplier = 1.0,
  }) : super(key: key);

  final Widget? child;
  final Color color;
  final EdgeInsets padding;
  final double radiusMultiplier;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(
          Constants.size.circularBorderRadius * radiusMultiplier,
        ),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
