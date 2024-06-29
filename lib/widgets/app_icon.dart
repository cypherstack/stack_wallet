import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_config.dart';
import '../themes/theme_providers.dart';

enum _SvgType {
  file,
  asset;
}

final _pAppIcon = Provider.autoDispose<({_SvgType svgType, String svg})>((ref) {
  if (AppConfig.appIconAsset != null) {
    final brightness = ref.watch(
      themeProvider.select(
        (value) => value.brightness,
      ),
    );
    final String asset;

    switch (brightness) {
      case Brightness.dark:
        asset = AppConfig.appIconAsset!.dark;
        break;

      case Brightness.light:
        asset = AppConfig.appIconAsset!.light;
        break;
    }

    return (svgType: _SvgType.asset, svg: asset);
  } else {
    final file = ref.watch(
      themeAssetsProvider.select(
        (value) => value.stackIcon,
      ),
    );
    return (svgType: _SvgType.file, svg: file);
  }
});

class AppIcon extends ConsumerWidget {
  const AppIcon({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconInfo = ref.watch(_pAppIcon);
    switch (iconInfo.svgType) {
      case _SvgType.file:
        return SvgPicture.file(
          File(
            iconInfo.svg,
          ),
          width: width,
          height: height,
        );
      case _SvgType.asset:
        return SvgPicture.asset(
          iconInfo.svg,
          width: width,
          height: height,
        );
    }
  }
}
