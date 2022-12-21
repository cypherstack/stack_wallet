import 'package:flutter/material.dart';
import 'package:stackwallet/pages/paynym/subwidgets/paynym_card.dart';
import 'package:stackwallet/utilities/featured_paynyms.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class FeaturedPaynymsWidget extends StatelessWidget {
  const FeaturedPaynymsWidget({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  final String walletId;

  @override
  Widget build(BuildContext context) {
    final entries = FeaturedPaynyms.featured.entries.toList(growable: false);

    return RoundedWhiteContainer(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          for (int i = 0; i < entries.length; i++)
            Column(
              children: [
                if (i > 0)
                  Container(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .backgroundAppBar,
                    height: 1,
                  ),
                PaynymCard(
                  walletId: walletId,
                  label: entries[i].key,
                  paymentCodeString: entries[i].value,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
