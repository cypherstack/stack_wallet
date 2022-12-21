import 'package:flutter/material.dart';
import 'package:stackwallet/pages/paynym/subwidgets/paynym_bot.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';

class PaynymCard extends StatefulWidget {
  const PaynymCard({
    Key? key,
    required this.label,
    required this.paymentCodeString,
  }) : super(key: key);

  final String label;
  final String paymentCodeString;

  @override
  State<PaynymCard> createState() => _PaynymCardState();
}

class _PaynymCardState extends State<PaynymCard> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          PayNymBot(
            size: 32,
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
                  style: STextStyles.w500_12(context),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  Format.shorten(widget.paymentCodeString, 12, 5),
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
    );
  }
}
