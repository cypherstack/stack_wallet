import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/wallet_info_row/sub_widgets/wallet_info_row_balance_future.dart';
import 'package:stackwallet/widgets/wallet_info_row/sub_widgets/wallet_info_row_coin_icon.dart';

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
    final manager = ref.watch(ref
        .watch(walletsChangeNotifierProvider.notifier)
        .getManagerProvider(walletId));

    return Row(
      children: Util.isDesktop
          ? [
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
                      style: STextStyles.desktopTextExtraSmall.copyWith(
                        color: CFColors.topNavPrimary,
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
                      color: CFColors.textSubtitle1,
                    )
                  ],
                ),
              )
            ]
          : [
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
                      style: STextStyles.titleBold12,
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
