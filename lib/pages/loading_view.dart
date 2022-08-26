import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: CFColors.almostWhite,
      body: Container(
        color: CFColors.almostWhite,
        child: Center(
          child: SizedBox(
            width: min(size.width, size.height) * 0.5,
            child: Lottie.asset(
              Assets.lottie.test2,
              animate: true,
              repeat: true,
            ),
          ),
          // child: Image(
          //   image: AssetImage(
          //     Assets.png.splash,
          //   ),
          //   width: MediaQuery.of(context).size.width * 0.5,
          // ),
        ),
      ),
    );
  }
}
