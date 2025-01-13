import 'package:flutter/material.dart';

import '../utilities/assets.dart';

class MoneroChanDance extends StatelessWidget {
  const MoneroChanDance({super.key, this.height = 200});

  final double height;
  @override
  Widget build(BuildContext context) {
    return Image(
      height: height,
      image: AssetImage(
        Assets.gif.moneroChanDance,
      ),
    );
  }
}
