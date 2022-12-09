import 'dart:math';

import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:epicpay/widgets/background.dart';
import 'package:epicpay/widgets/loading_indicator.dart';
import 'package:flutter/material.dart';

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
              child: const LoadingIndicator(),
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
