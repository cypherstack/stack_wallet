import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/themes/theme_providers.dart';

class BuyNavIcon extends ConsumerWidget {
  const BuyNavIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SvgPicture.file(
      File(
        ref.watch(
          themeProvider.select(
            (value) => value.assets.buy,
          ),
        ),
      ),
      width: 24,
      height: 24,
    );
  }
}
