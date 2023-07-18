import 'package:flutter/material.dart';
import 'package:stackwallet/models/ordinal.dart';
import 'package:stackwallet/pages/ordinals/ordinal_details_view.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class OrdinalCard extends StatelessWidget {
  const OrdinalCard({
    super.key,
    required this.walletId,
    required this.ordinal,
  });

  final String walletId;
  final Ordinal ordinal;

  @override
  Widget build(BuildContext context) {
    return RoundedWhiteContainer(
      radiusMultiplier: 2,
      onPressed: () {
        Navigator.of(context).pushNamed(
          OrdinalDetailsView.routeName,
          arguments: widget.walletId,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              color: Colors.red,
              child: const Center(
                child: Text(
                  "replace red container with image",
                ),
              ),
            ),
          ),
          const Spacer(),
          Text(
            ordinal.name,
            style: STextStyles.w500_12(context),
          ),
          const Spacer(),
          Text(
            "INSC. ${ordinal.inscription}   RANK ${ordinal.rank}",
            style: STextStyles.w500_8(context),
          ),
        ],
      ),
    );
  }
}
