import 'package:flutter/material.dart';
import 'package:stackwallet/widgets/exchange/trocador/trocador_kyc_icon.dart';
import 'package:stackwallet/widgets/exchange/trocador/trocador_rating_type_enum.dart';
import 'package:stackwallet/widgets/trocador_kyc_rating_info.dart';

class TrocadorKYCInfoButton extends StatelessWidget {
  const TrocadorKYCInfoButton({
    Key? key,
    required this.kycType,
  }) : super(key: key);

  final TrocadorKYCType kycType;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        showDialog<void>(
          context: context,
          builder: (context) => const TrocadorKYCRatingInfo(),
        );
      },
      icon: TrocadorKYCIcon(
        kycType: kycType,
      ),
    );
  }
}
