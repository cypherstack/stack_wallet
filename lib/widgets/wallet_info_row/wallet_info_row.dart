import 'package:epicmobile/providers/providers.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/utilities/util.dart';
import 'package:epicmobile/widgets/wallet_info_row/sub_widgets/wallet_info_row_balance_future.dart';
import 'package:epicmobile/widgets/wallet_info_row/sub_widgets/wallet_info_row_coin_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

class WalletInfoRow extends ConsumerWidget {
  const WalletInfoRow({
    Key? key,
    required this.walletId,
    this.onPressed,
  }) : super(key: key);

  final String walletId;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manager = ref.watch(walletProvider)!;

    if (Util.isDesktop) {
      return GestureDetector(
        onTap: onPressed,
        child: Container(
          color: Colors.transparent,
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    WalletInfoCoinIcon(coin: manager.coin),
                    const SizedBox(
                      width: 12,
                    ),
                    Text(
                      manager.walletName,
                      style:
                          STextStyles.desktopTextExtraSmall(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textLight,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: WalletInfoRowBalanceFuture(
                  walletId: walletId,
                ),
              ),
              Expanded(
                flex: 6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SvgPicture.asset(
                      Assets.svg.chevronRight,
                      width: 20,
                      height: 20,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .textSubtitle1,
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      );
    } else {
      return Row(
        children: [
          WalletInfoCoinIcon(coin: manager.coin),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  manager.walletName,
                  style: STextStyles.bodyBold(context),
                ),
                const SizedBox(
                  height: 2,
                ),
                WalletInfoRowBalanceFuture(walletId: walletId),
              ],
            ),
          ),
        ],
      );
    }
  }
}
