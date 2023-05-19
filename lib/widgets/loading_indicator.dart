import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/assets.dart';

class LoadingIndicator extends ConsumerWidget {
  const LoadingIndicator({
    Key? key,
    this.width,
    this.height,
  }) : super(key: key);

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetPath = ref.watch(
      themeProvider.select((value) => value.assets.loadingGif),
    );

    return Container(
      color: Colors.transparent,
      child: Center(
        child: SizedBox(
          width: width,
          height: height,
          child: assetPath != null
              ? Image.file(
                  File(
                    assetPath,
                  ),
                )
              : Lottie.asset(
                  Assets.lottie.test2,
                  animate: true,
                  repeat: true,
                ),
        ),
      ),
    );
  }
}
