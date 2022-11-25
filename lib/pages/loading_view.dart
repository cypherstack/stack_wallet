import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/background.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        body: Container(
          color: Theme.of(context).extension<StackColors>()!.background,
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
      ),
    );
  }
}
