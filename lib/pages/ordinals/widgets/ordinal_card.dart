import 'package:flutter/material.dart';
import 'package:stackwallet/models/isar/ordinal.dart';
import 'package:stackwallet/pages/ordinals/ordinal_details_view.dart';
import 'package:stackwallet/pages_desktop_specific/ordinals/desktop_ordinal_details_view.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
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
          Util.isDesktop
              ? DesktopOrdinalDetailsView.routeName
              : OrdinalDetailsView.routeName,
          arguments: (walletId: walletId, ordinal: ordinal),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                Constants.size.circularBorderRadius,
              ),
              child: Image.network(
                ordinal.content, // Use the preview URL as the image source
                fit: BoxFit.cover,
                filterQuality:
                    FilterQuality.none, // Set the filter mode to nearest
              ),
            ),
          ),
          const Spacer(),
          Text(
            'INSC. ${ordinal.inscriptionNumber}', // infer from address associated with utxoTXID
            style: STextStyles.w500_12(context),
          ),
          // const Spacer(),
          // Text(
          //   "ID ${ordinal.inscriptionId}",
          //   style: STextStyles.w500_8(context),
          // ),
        ],
      ),
    );
  }
}
