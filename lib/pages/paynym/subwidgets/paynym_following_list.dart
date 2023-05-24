import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/paynym/subwidgets/paynym_card_button.dart';
import 'package:stackwallet/providers/global/paynym_api_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/providers/wallet/my_paynym_account_state_provider.dart';
import 'package:stackwallet/services/mixins/paynym_wallet_interface.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class PaynymFollowingList extends ConsumerStatefulWidget {
  const PaynymFollowingList({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  final String walletId;

  @override
  ConsumerState<PaynymFollowingList> createState() =>
      _PaynymFollowingListState();
}

class _PaynymFollowingListState extends ConsumerState<PaynymFollowingList> {
  final isDesktop = Util.isDesktop;

  BorderRadius get _borderRadiusFirst {
    return BorderRadius.only(
      topLeft: Radius.circular(
        Constants.size.circularBorderRadius,
      ),
      topRight: Radius.circular(
        Constants.size.circularBorderRadius,
      ),
    );
  }

  BorderRadius get _borderRadiusLast {
    return BorderRadius.only(
      bottomLeft: Radius.circular(
        Constants.size.circularBorderRadius,
      ),
      bottomRight: Radius.circular(
        Constants.size.circularBorderRadius,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final following =
        ref.watch(myPaynymAccountStateProvider.state).state?.following;
    final count = following?.length ?? 0;

    return ConditionalParent(
      condition: !isDesktop,
      builder: (child) => RefreshIndicator(
        child: child,
        onRefresh: () async {
          try {
            final manager = ref
                .read(walletsChangeNotifierProvider)
                .getManager(widget.walletId);

            // get wallet to access paynym calls
            final wallet = manager.wallet as PaynymWalletInterface;

            // get payment code
            final pCode = await wallet.getPaymentCode(
              isSegwit: false,
            );

            // get account from api
            final account =
                await ref.read(paynymAPIProvider).nym(pCode.toString());

            // update my account
            if (account.value != null) {
              ref.read(myPaynymAccountStateProvider.state).state =
                  account.value!;
            }
          } catch (e) {
            Logging.instance.log(
              "Failed pull down refresh of paynym home page: $e",
              level: LogLevel.Warning,
            );
          }
        },
      ),
      child: ListView.separated(
        itemCount: max(count, 1),
        separatorBuilder: (BuildContext context, int index) => Container(
          height: 1.5,
          color: Colors.transparent,
        ),
        itemBuilder: (BuildContext context, int index) {
          if (count == 0) {
            return RoundedWhiteContainer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Your PayNym contacts will appear here",
                    style: isDesktop
                        ? STextStyles.desktopTextExtraExtraSmall(context)
                            .copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textSubtitle1,
                          )
                        : STextStyles.label(context),
                  ),
                ],
              ),
            );
          } else if (count == 1) {
            return RoundedWhiteContainer(
              padding: const EdgeInsets.all(0),
              child: PaynymCardButton(
                walletId: widget.walletId,
                accountLite: following![0],
              ),
            );
          } else {
            BorderRadius? borderRadius;
            if (index == 0) {
              borderRadius = _borderRadiusFirst;
            } else if (index == count - 1) {
              borderRadius = _borderRadiusLast;
            }

            return Container(
              key: Key("paynymCardKey_${following![index].nymId}"),
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                color: Theme.of(context).extension<StackColors>()!.popupBG,
              ),
              child: PaynymCardButton(
                walletId: widget.walletId,
                accountLite: following[index],
              ),
            );
          }
        },
      ),
    );
  }
}
