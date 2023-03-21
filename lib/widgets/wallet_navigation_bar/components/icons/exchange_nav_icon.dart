import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackduo/utilities/assets.dart';

class ExchangeNavIcon extends StatelessWidget {
  const ExchangeNavIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      Assets.svg.exchange(context),
      width: 24,
      height: 24,
    );
  }
}
