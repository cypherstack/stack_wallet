import 'package:flutter/material.dart';
import 'package:stackwallet/pages/paynym/subwidgets/paynym_bot.dart';
import 'package:stackwallet/utilities/featured_paynyms.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class FeaturedPaynymsWidget extends StatelessWidget {
  const FeaturedPaynymsWidget({Key? key}) : super(key: key);

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
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      PayNymBot(
                        size: 32,
                        paymentCodeString: entries[i].value,
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entries[i].key,
                              style: STextStyles.w500_12(context),
                            ),
                            const SizedBox(
                              height: 2,
                            ),
                            Text(
                              Format.shorten(entries[i].value, 12, 5),
                              style: STextStyles.w500_12(context).copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textSubtitle1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PrimaryButton(
                        width: 84,
                        buttonHeight: ButtonHeight.l,
                        label: "Follow",
                        onPressed: () {
                          // todo : follow
                        },
                      )
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
