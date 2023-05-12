import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/widgets/exchange/trocador/trocador_rating_type_enum.dart';

class TrocadorKYCIcon extends StatelessWidget {
  const TrocadorKYCIcon({
    Key? key,
    required this.kycType,
    this.width = 18,
    this.height = 18,
  }) : super(key: key);

  final TrocadorKYCType kycType;
  final double width;
  final double height;

  String _getAssetName(TrocadorKYCType type) {
    switch (type) {
      case TrocadorKYCType.a:
        return Assets.svg.trocadorRatingA;
      case TrocadorKYCType.b:
        return Assets.svg.trocadorRatingB;
      case TrocadorKYCType.c:
        return Assets.svg.trocadorRatingC;
      case TrocadorKYCType.d:
        return Assets.svg.trocadorRatingD;
    }
  }

  Color _getColor(TrocadorKYCType type, BuildContext context) {
    switch (type) {
      case TrocadorKYCType.a:
        return Theme.of(context).extension<StackColors>()!.accentColorGreen;
      case TrocadorKYCType.b:
        return const Color(0xFF7AA500);
      case TrocadorKYCType.c:
        return Theme.of(context).extension<StackColors>()!.accentColorYellow;
      case TrocadorKYCType.d:
        return const Color(0xFFF37B58);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _getAssetName(kycType),
      width: width,
      height: height,
      color: _getColor(kycType, context),
    );
  }
}
