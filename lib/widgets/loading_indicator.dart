import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:stackwallet/utilities/assets.dart';

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
    return Container(
      color: Colors.transparent,
      child: Center(
        child: SizedBox(
          width: width,
          height: height,
          child: Lottie.asset(
            Assets.lottie.test2,
            animate: true,
            repeat: true,
          ),
        ),
      ),
    );
  }
}
