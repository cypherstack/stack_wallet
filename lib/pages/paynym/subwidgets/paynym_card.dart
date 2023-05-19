import 'package:flutter/material.dart';
import 'package:stackwallet/pages/paynym/subwidgets/paynym_bot.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/custom_buttons/paynym_follow_toggle_button.dart';

class PaynymCard extends StatefulWidget {
  const PaynymCard({
    Key? key,
    required this.walletId,
    required this.label,
    required this.paymentCodeString,
  }) : super(key: key);

  final String walletId;
  final String label;
  final String paymentCodeString;

  @override
  State<PaynymCard> createState() => _PaynymCardState();
}

class _PaynymCardState extends State<PaynymCard> {
  final isDesktop = Util.isDesktop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: isDesktop
          ? const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 20,
            )
          : const EdgeInsets.all(12),
      child: Row(
        children: [
          PayNymBot(
            size: 36,
            paymentCodeString: widget.paymentCodeString,
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: isDesktop
                      ? STextStyles.desktopTextExtraExtraSmall(context)
                          .copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textFieldActiveText,
                        )
                      : STextStyles.w500_14(context),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  Format.shorten(widget.paymentCodeString, 12, 5),
                  style: isDesktop
                      ? STextStyles.desktopTextExtraExtraSmall(context)
                      : STextStyles.w500_14(context).copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textSubtitle1,
                        ),
                ),
              ],
            ),
          ),
          PaynymFollowToggleButton(
            walletId: widget.walletId,
            paymentCodeStringToFollow: widget.paymentCodeString,
          ),
        ],
      ),
    );
  }
}
