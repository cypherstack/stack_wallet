import 'package:flutter/material.dart';
import 'package:stackwallet/pages/paynym/subwidgets/paynym_card.dart';
import 'package:stackwallet/utilities/featured_paynyms.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
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
    final isDesktop = Util.isDesktop;

    return ConditionalParent(
      condition: !isDesktop,
      builder: (child) => RoundedWhiteContainer(
        padding: const EdgeInsets.all(0),
        child: child,
      ),
      child: Column(
        children: [
          for (int i = 0; i < entries.length; i++)
            Column(
              children: [
                if (i > 0)
                  isDesktop
                      ? const SizedBox(
                          height: 10,
                        )
                      : Container(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .backgroundAppBar,
                          height: 1,
                        ),
                ConditionalParent(
                  condition: isDesktop,
                  builder: (child) => RoundedWhiteContainer(
                    padding: const EdgeInsets.all(0),
                    borderColor: Theme.of(context)
                        .extension<StackColors>()!
                        .backgroundAppBar,
                    child: child,
                  ),
                  child: PaynymCard(
                    walletId: walletId,
                    label: entries[i].key,
                    paymentCodeString: entries[i].value,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
