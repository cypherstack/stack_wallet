import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    Key? key,
    this.width,
    this.height,
  }) : super(key: key);

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CircularProgressIndicator(
        backgroundColor: Colors.transparent,
        color: Theme.of(context).extension<StackColors>()!.textGold,
      ),
    );
  }
}
