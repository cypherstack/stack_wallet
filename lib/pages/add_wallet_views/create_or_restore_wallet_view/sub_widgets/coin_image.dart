import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/themes/coin_image_provider.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/util.dart';

class CoinImage extends ConsumerWidget {
  const CoinImage({
    Key? key,
    required this.coin,
    this.width,
    this.height,
  }) : super(key: key);

  final Coin coin;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetPath = ref.watch(coinImageProvider(coin));

    final isDesktop = Util.isDesktop;

    if (!assetPath.endsWith(".svg")) {
      return SizedBox(
        width: isDesktop ? width : MediaQuery.of(context).size.width,
        height: isDesktop ? height : MediaQuery.of(context).size.width,
        child: Image.file(
          File(assetPath),
        ),
      );
    } else {
      return SvgPicture.file(
        File(assetPath),
        width: width,
        height: height,
      );
    }
  }
}
