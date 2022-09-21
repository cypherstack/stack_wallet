import 'package:flutter/cupertino.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';
import 'package:stackwallet/widgets/rounded_container.dart';

class RoundedWhiteContainer extends StatelessWidget {
  const RoundedWhiteContainer({
    Key? key,
    this.child,
    this.padding = const EdgeInsets.all(12),
    this.radiusMultiplier = 1.0,
    this.width,
    this.height,
  }) : super(key: key);

  final Widget? child;
  final EdgeInsets padding;
  final double radiusMultiplier;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return RoundedContainer(
      color: StackTheme.instance.color.popupBG,
      padding: padding,
      radiusMultiplier: radiusMultiplier,
      width: width,
      height: height,
      child: child,
    );
  }
}
