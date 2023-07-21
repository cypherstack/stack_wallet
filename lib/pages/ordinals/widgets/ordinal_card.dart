import 'package:flutter/material.dart';
import 'package:stackwallet/dto/ordinals/inscription_data.dart';
import 'package:stackwallet/models/ordinal.dart'; // TODO generalize InscriptionData models -> Ordinal
import 'package:stackwallet/pages/ordinals/ordinal_details_view.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class OrdinalCard extends StatelessWidget {
  const OrdinalCard({
    Key? key,
    required this.walletId,
    required this.inscriptionData,
  }) : super(key: key);

  final String walletId;
  final InscriptionData inscriptionData;

  @override
  Widget build(BuildContext context) {
    return RoundedWhiteContainer(
      radiusMultiplier: 2,
      onPressed: () {
        Navigator.of(context).pushNamed(
          OrdinalDetailsView.routeName,
          arguments: (walletId: walletId, inscriptionData: inscriptionData),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              color: Colors.red,
              child: Image.network(
                inscriptionData.preview, // Use the preview URL as the image source
                fit: BoxFit.cover,
              ),
            ),
          ),
          const Spacer(),
          Text(
            inscriptionData.address,
            style: STextStyles.w500_12(context),
          ),
          const Spacer(),
          Text(
            "INSC. ${inscriptionData.inscriptionNumber}   ID ${inscriptionData.inscriptionId}",
            style: STextStyles.w500_8(context),
          ),
        ],
      ),
    );
  }
}
