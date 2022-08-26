import 'package:flutter/cupertino.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/widgets/rounded_container.dart';

class RoundedWhiteContainer extends StatelessWidget {
  const RoundedWhiteContainer({
    Key? key,
    this.child,
    this.padding = const EdgeInsets.all(12),
  }) : super(key: key);

  final Widget? child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return RoundedContainer(
      color: CFColors.white,
      padding: padding,
      child: child,
    );
  }
}
