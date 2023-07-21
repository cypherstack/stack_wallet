import 'package:flutter/material.dart';

import 'package:stackwallet/models/ordinal.dart';
import 'package:stackwallet/pages/ordinals/ordinal_details_view.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class OrdinalCard extends StatelessWidget {
  const OrdinalCard({
    Key? key,
    required this.walletId,
    required this.ordinal,
  }) : super(key: key);

  final String walletId;
  final Ordinal ordinal;

  @override
  Widget build(BuildContext context) {
    return RoundedWhiteContainer(
      radiusMultiplier: 2,
      onPressed: () {
        Navigator.of(context).pushNamed(
          OrdinalDetailsView.routeName,
          arguments: (walletId: walletId, ordinal: ordinal),
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
                ordinal.content, // Use the preview URL as the image source
                fit: BoxFit.cover,
                filterQuality: FilterQuality.none, // Set the filter mode to nearest
              ),
            ),
          ),
          const Spacer(),
          Text(
            'TODO', // infer from address associated with utxoTXID
            style: STextStyles.w500_12(context),
          ),
          const Spacer(),
          Text(
            "INSC. ${ordinal.inscriptionNumber}   ID ${ordinal.inscriptionId}",
            style: STextStyles.w500_8(context),
          ),
        ],
      ),
    );
  }
}
