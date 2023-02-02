import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/paynym/paynym_account_lite.dart';
import 'package:stackwallet/pages/paynym/dialogs/paynym_details_popup.dart';
import 'package:stackwallet/pages/paynym/subwidgets/paynym_bot.dart';
import 'package:stackwallet/providers/ui/selected_paynym_details_item_Provider.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/rounded_container.dart';

class PaynymCardButton extends ConsumerStatefulWidget {
  const PaynymCardButton({
    Key? key,
    required this.walletId,
    required this.accountLite,
  }) : super(key: key);

  final String walletId;
  final PaynymAccountLite accountLite;

  @override
  ConsumerState<PaynymCardButton> createState() => _PaynymCardButtonState();
}

class _PaynymCardButtonState extends ConsumerState<PaynymCardButton> {
  final isDesktop = Util.isDesktop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: RoundedContainer(
        padding: const EdgeInsets.all(0),
        color: isDesktop &&
                ref
                        .watch(selectedPaynymDetailsItemProvider.state)
                        .state
                        ?.nymId ==
                    widget.accountLite.nymId
            ? Theme.of(context)
                .extension<StackColors>()!
                .accentColorDark
                .withOpacity(0.08)
            : Colors.transparent,
        child: RawMaterialButton(
          padding: const EdgeInsets.all(0),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              Constants.size.circularBorderRadius,
            ),
          ),
          onPressed: () {
            if (isDesktop) {
              ref.read(selectedPaynymDetailsItemProvider.state).state =
                  widget.accountLite;
            } else {
              showDialog<void>(
                context: context,
                builder: (context) => PaynymDetailsPopup(
                  accountLite: widget.accountLite,
                  walletId: widget.walletId,
                ),
              );
            }
          },
          child: Padding(
            padding: isDesktop
                ? const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  )
                : const EdgeInsets.all(8.0),
            child: Row(
              children: [
                PayNymBot(
                  size: 36,
                  paymentCodeString: widget.accountLite.code,
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.accountLite.nymName,
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
                        Format.shorten(widget.accountLite.code, 12, 5),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
